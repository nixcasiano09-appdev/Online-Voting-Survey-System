const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { setGlobalOptions } = require('firebase-functions/v2');
const admin = require('firebase-admin');

admin.initializeApp();
setGlobalOptions({ region: 'us-central1', maxInstances: 10 });

const db = admin.firestore();

function requireStudent(request) {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in to continue.');
  }
  return request.auth.uid;
}

function requireAdmin(request) {
  const uid = requireStudent(request);
  if (request.auth.token.admin !== true) {
    throw new HttpsError('permission-denied', 'Administrator access is required.');
  }
  return uid;
}

function validateId(value, label) {
  if (typeof value !== 'string' || !/^[a-zA-Z0-9_-]{1,100}$/.test(value)) {
    throw new HttpsError('invalid-argument', `${label} is invalid.`);
  }
  return value;
}

function validateWindow(data, now) {
  if (data.status !== 'active') {
    throw new HttpsError('failed-precondition', 'This activity is not open.');
  }
  const start = data.startDate && data.startDate.toMillis
    ? data.startDate.toMillis()
    : Number(data.startDate);
  const end = data.endDate && data.endDate.toMillis
    ? data.endDate.toMillis()
    : Number(data.endDate);
  if (!Number.isFinite(start) || !Number.isFinite(end) || now < start || now > end) {
    throw new HttpsError('failed-precondition', 'The submission period has ended or has not started.');
  }
}

function normalizePositions(value) {
  if (!Array.isArray(value)) return [];
  return value
    .filter((position) => position && typeof position.title === 'string')
    .map((position) => ({
      title: position.title.trim(),
      candidates: Array.isArray(position.candidates)
        ? position.candidates.map((candidate) =>
            typeof candidate === 'string'
              ? candidate.trim()
              : String(candidate?.fullName || '').trim())
          .filter(Boolean)
        : [],
    }));
}

async function replaceEligibility(parentRef, subcollection, studentUids) {
  if (!Array.isArray(studentUids) || studentUids.length === 0 || studentUids.length > 400) {
    throw new HttpsError('invalid-argument', 'Provide 1 to 400 eligible student UIDs.');
  }
  const uids = [...new Set(studentUids.map((uid) => String(uid).trim()))];
  if (uids.some((uid) => !/^[a-zA-Z0-9_-]{1,128}$/.test(uid))) {
    throw new HttpsError('invalid-argument', 'An eligible student UID is invalid.');
  }
  const collection = parentRef.collection(subcollection);
  const studentSnapshots = [];
  for (let offset = 0; offset < uids.length; offset += 400) {
    const refs = uids
      .slice(offset, offset + 400)
      .map((uid) => db.collection('students').doc(uid));
    studentSnapshots.push(...await db.getAll(...refs));
  }
  if (studentSnapshots.some((student) => !student.exists)) {
    throw new HttpsError(
      'invalid-argument',
      'Every eligible UID must refer to a provisioned student account.',
    );
  }
  const existing = await collection.get();
  for (let offset = 0; offset < existing.docs.length; offset += 400) {
    const batch = db.batch();
    existing.docs.slice(offset, offset + 400).forEach((document) => {
      batch.delete(document.ref);
    });
    await batch.commit();
  }
  for (let offset = 0; offset < uids.length; offset += 400) {
    const batch = db.batch();
    uids.slice(offset, offset + 400).forEach((uid) => {
      batch.set(collection.doc(uid), {
        eligible: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    await batch.commit();
  }
}

exports.submitBallot = onCall(async (request) => {
  const uid = requireStudent(request);
  const electionId = validateId(request.data?.electionId, 'Election ID');
  const selections = request.data?.selectedCandidates;
  if (!selections || typeof selections !== 'object' || Array.isArray(selections)) {
    throw new HttpsError('invalid-argument', 'Candidate selections are required.');
  }

  const electionRef = db.collection('elections').doc(electionId);
  const eligibilityRef = electionRef.collection('eligibility').doc(uid);
  const ballotRef = db.collection('votes').doc(`${electionId}_${uid}`);
  const now = Date.now();

  await db.runTransaction(async (transaction) => {
    const [electionSnapshot, eligibilitySnapshot, ballotSnapshot] =
      await Promise.all([
        transaction.get(electionRef),
        transaction.get(eligibilityRef),
        transaction.get(ballotRef),
      ]);
    if (!electionSnapshot.exists) {
      throw new HttpsError('not-found', 'Election not found.');
    }
    if (!eligibilitySnapshot.exists || eligibilitySnapshot.data().eligible !== true) {
      throw new HttpsError('permission-denied', 'You are not eligible for this election.');
    }
    if (ballotSnapshot.exists) {
      throw new HttpsError('already-exists', 'A ballot has already been submitted.');
    }

    const election = electionSnapshot.data();
    validateWindow(election, now);
    const positions = normalizePositions(election.positions);
    const required = new Map(positions.map((position) => [position.title, position]));
    if (positions.length === 0 || required.size !== positions.length
      || positions.some((position) => position.candidates.length === 0)) {
      throw new HttpsError('failed-precondition', 'This ballot is not configured correctly.');
    }
    const keys = Object.keys(selections);
    if (keys.length !== required.size || keys.some((key) => !required.has(key))) {
      throw new HttpsError('invalid-argument', 'Select one candidate for every position.');
    }
    for (const [position, candidate] of Object.entries(selections)) {
      if (typeof candidate !== 'string'
        || !required.get(position).candidates.includes(candidate)) {
        throw new HttpsError('invalid-argument', 'A selected candidate is not on this ballot.');
      }
    }

    transaction.create(ballotRef, {
      electionId,
      electionTitle: election.title || electionId,
      studentUid: uid,
      selectedCandidates: selections,
      submittedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'submitted',
    });
  });
  return { submitted: true };
});

exports.submitSurvey = onCall(async (request) => {
  const uid = requireStudent(request);
  const surveyId = validateId(request.data?.surveyId, 'Survey ID');
  const answers = request.data?.answers;
  if (!answers || typeof answers !== 'object' || Array.isArray(answers)) {
    throw new HttpsError('invalid-argument', 'Survey answers are required.');
  }

  const surveyRef = db.collection('surveys').doc(surveyId);
  const eligibilityRef = surveyRef.collection('eligibleStudents').doc(uid);
  const responseRef =
    db.collection('survey_responses').doc(`${surveyId}_${uid}`);
  const now = Date.now();

  await db.runTransaction(async (transaction) => {
    const [surveySnapshot, eligibilitySnapshot, responseSnapshot] =
      await Promise.all([
        transaction.get(surveyRef),
        transaction.get(eligibilityRef),
        transaction.get(responseRef),
      ]);
    if (!surveySnapshot.exists) {
      throw new HttpsError('not-found', 'Survey not found.');
    }
    if (!eligibilitySnapshot.exists || eligibilitySnapshot.data().eligible !== true) {
      throw new HttpsError('permission-denied', 'You are not eligible for this survey.');
    }
    if (responseSnapshot.exists) {
      throw new HttpsError('already-exists', 'A response has already been submitted.');
    }

    const survey = surveySnapshot.data();
    validateWindow(survey, now);
    const questions = Array.isArray(survey.questions) ? survey.questions : [];
    if (questions.length === 0 || questions.length > 50) {
      throw new HttpsError('failed-precondition', 'This survey is not configured correctly.');
    }
    const questionIds = new Set(questions.map((question) => question.id));
    if (questionIds.size !== questions.length
      || questions.some((question) => !question.id
        || !['single', 'multiple', 'text', undefined].includes(question.type))) {
      throw new HttpsError('failed-precondition', 'This survey is not configured correctly.');
    }
    if (Object.keys(answers).some((questionId) => !questionIds.has(questionId))) {
      throw new HttpsError('invalid-argument', 'The response includes an unknown question.');
    }
    for (const question of questions) {
      if (question.required === false) continue;
      const answer = answers[question.id];
      if (question.type === 'text' && typeof answer === 'string'
        && answer.trim().length > 0 && answer.length <= 4000) continue;
      if (question.type === 'multiple' && Array.isArray(answer)
        && answer.length > 0
        && answer.every((value) => question.options?.includes(value))) continue;
      if ((!question.type || question.type === 'single')
        && typeof answer === 'string'
        && question.options?.includes(answer)) continue;
      throw new HttpsError('invalid-argument', 'Answer all required questions.');
    }

    transaction.create(responseRef, {
      surveyId,
      surveyTitle: survey.title || surveyId,
      studentUid: uid,
      answers,
      submittedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  return { submitted: true };
});

exports.upsertElection = onCall(async (request) => {
  requireAdmin(request);
  const election = request.data;
  const electionId = validateId(election?.electionId, 'Election ID');
  if (typeof election.title !== 'string' || !Array.isArray(election.positions)
    || !election.startDate || !election.endDate) {
    throw new HttpsError('invalid-argument', 'Election title, schedule, and positions are required.');
  }
  const positions = normalizePositions(election.positions);
  if (positions.length === 0 || positions.length > 20
    || new Set(positions.map((position) => position.title)).size !== positions.length
    || positions.some((position) => position.candidates.length < 2
      || position.candidates.length > 25
      || new Set(position.candidates).size !== position.candidates.length)) {
    throw new HttpsError('invalid-argument', 'Every election position needs candidates.');
  }
  const startMillis = Number(election.startDate);
  const endMillis = Number(election.endDate);
  if (!Number.isFinite(startMillis) || !Number.isFinite(endMillis)
    || endMillis <= startMillis) {
    throw new HttpsError('invalid-argument', 'The election schedule is invalid.');
  }
  if (election.title.trim().length > 120 || positions.some((position) =>
    position.title.length > 80 || position.candidates.some((candidate) =>
      candidate.length > 120))) {
    throw new HttpsError('invalid-argument', 'Election content exceeds allowed lengths.');
  }
  const electionRef = db.collection('elections').doc(electionId);
  const ballotsQuery = db.collection('votes')
    .where('electionId', '==', electionId)
    .limit(1);
  await db.runTransaction(async (transaction) => {
    const existingElection = await transaction.get(electionRef);
    const existingBallots = await transaction.get(ballotsQuery);
    if (existingElection.exists
      && existingElection.data().resultsPublished === true) {
      throw new HttpsError('failed-precondition', 'Published election data is locked.');
    }
    if (!existingBallots.empty) {
      throw new HttpsError(
        'failed-precondition',
        'An election cannot be changed after a ballot has been submitted.',
      );
    }
    transaction.set(electionRef, {
      title: election.title.trim(),
      description: String(election.description || ''),
      startDate: admin.firestore.Timestamp.fromMillis(startMillis),
      endDate: admin.firestore.Timestamp.fromMillis(endMillis),
      status: 'draft',
      resultsPublished: false,
      positions,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  });
  await replaceEligibility(electionRef, 'eligibility', election.eligibleStudentUids);

  const oldCandidates = await db.collection('candidates')
    .where('electionId', '==', electionId)
    .get();
  for (let offset = 0; offset < oldCandidates.docs.length; offset += 400) {
    const batch = db.batch();
    oldCandidates.docs.slice(offset, offset + 400).forEach((document) => {
      batch.delete(document.ref);
    });
    await batch.commit();
  }
  const candidateBatch = db.batch();
  positions.forEach((position) => {
    position.candidates.forEach((fullName, index) => {
      const candidateId = `${electionId}_${position.title}_${index}`
        .toLowerCase()
        .replace(/[^a-z0-9_-]/g, '_');
      candidateBatch.set(db.collection('candidates').doc(candidateId), {
        electionId,
        position: position.title,
        fullName,
        photoUrl: null,
      });
    });
  });
  await candidateBatch.commit();
  await electionRef.update({
    status: election.status === 'active' ? 'active' : 'draft',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { saved: true };
});

exports.upsertSurvey = onCall(async (request) => {
  requireAdmin(request);
  const survey = request.data;
  const surveyId = validateId(survey?.surveyId, 'Survey ID');
  if (typeof survey.title !== 'string' || !Array.isArray(survey.questions)
    || !survey.startDate || !survey.endDate) {
    throw new HttpsError('invalid-argument', 'Survey title, schedule, and questions are required.');
  }
  const startMillis = Number(survey.startDate);
  const endMillis = Number(survey.endDate);
  if (!Number.isFinite(startMillis) || !Number.isFinite(endMillis)
    || endMillis <= startMillis || survey.questions.length === 0
    || survey.questions.length > 50) {
    throw new HttpsError('invalid-argument', 'The survey schedule or questions are invalid.');
  }
  const questionIds = new Set();
  for (const question of survey.questions) {
    if (!question || typeof question.id !== 'string' || !question.id
      || questionIds.has(question.id) || typeof question.prompt !== 'string'
      || !question.prompt.trim()
      || !['single', 'multiple', 'text'].includes(question.type)) {
      throw new HttpsError('invalid-argument', 'A survey question is invalid.');
    }
    questionIds.add(question.id);
    if (question.type !== 'text'
      && (!Array.isArray(question.options) || question.options.length < 2
        || question.options.some((option) => typeof option !== 'string' || !option.trim()))) {
      throw new HttpsError('invalid-argument', 'A survey question needs valid options.');
    }
  }
  if (survey.title.trim().length > 120) {
    throw new HttpsError('invalid-argument', 'Survey title is too long.');
  }
  const surveyRef = db.collection('surveys').doc(surveyId);
  const responsesQuery = db.collection('survey_responses')
    .where('surveyId', '==', surveyId)
    .limit(1);
  await db.runTransaction(async (transaction) => {
    const existingSurvey = await transaction.get(surveyRef);
    const responses = await transaction.get(responsesQuery);
    if (existingSurvey.exists && existingSurvey.data().status === 'completed') {
      throw new HttpsError('failed-precondition', 'Completed survey data is locked.');
    }
    if (!responses.empty) {
      throw new HttpsError(
        'failed-precondition',
        'A survey cannot be changed after a response has been submitted.',
      );
    }
    transaction.set(surveyRef, {
      title: survey.title.trim(),
      description: String(survey.description || ''),
      startDate: admin.firestore.Timestamp.fromMillis(startMillis),
      endDate: admin.firestore.Timestamp.fromMillis(endMillis),
      status: 'draft',
      questions: survey.questions,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  });
  await replaceEligibility(surveyRef, 'eligibleStudents', survey.eligibleStudentUids);
  await surveyRef.update({
    status: survey.status === 'active' ? 'active' : 'draft',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { saved: true };
});

exports.publishAnnouncement = onCall(async (request) => {
  requireAdmin(request);
  const title = String(request.data?.title || '').trim();
  const message = String(request.data?.message || '').trim();
  const targetAudience = String(request.data?.targetAudience || 'all');
  if (!title || !message || title.length > 120 || message.length > 1000) {
    throw new HttpsError('invalid-argument', 'A title and message are required.');
  }
  if (targetAudience !== 'all') {
    validateId(targetAudience, 'Student UID');
  }
  await db.collection('notifications').add({
    title,
    message,
    targetAudience,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { published: true };
});

exports.listSurveyResponses = onCall(async (request) => {
  requireAdmin(request);
  const surveyId = validateId(request.data?.surveyId, 'Survey ID');
  const responses = await db.collection('survey_responses')
    .where('surveyId', '==', surveyId)
    .limit(100)
    .get();
  return responses.docs.map((document) => {
    const data = document.data();
    return {
      studentUid: data.studentUid,
      answers: data.answers || {},
      submittedAt: data.submittedAt?.toMillis?.() || null,
    };
  });
});

exports.publishResults = onCall(async (request) => {
  requireAdmin(request);
  const electionId = validateId(request.data?.electionId, 'Election ID');
  const electionRef = db.collection('elections').doc(electionId);

  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(electionRef);
    if (!snapshot.exists) throw new HttpsError('not-found', 'Election not found.');
    const election = snapshot.data();
    if (election.resultsPublished === true) {
      throw new HttpsError('failed-precondition', 'Results have already been published.');
    }
    if (!['active', 'completed'].includes(election.status)) {
      throw new HttpsError('failed-precondition', 'This election cannot publish results.');
    }
    const end = election.endDate && election.endDate.toMillis
      ? election.endDate.toMillis()
      : Number(election.endDate);
    if (!Number.isFinite(end) || Date.now() <= end) {
      throw new HttpsError(
        'failed-precondition',
        'Results cannot be published before voting has ended.',
      );
    }
    transaction.update(electionRef, {
      status: 'completed',
      resultsPublished: false,
    });
  });

  const ballots = await db.collection('votes')
    .where('electionId', '==', electionId)
    .get();
  const totals = {};
  for (const ballot of ballots.docs) {
    const selections = ballot.data().selectedCandidates || {};
    for (const [position, candidate] of Object.entries(selections)) {
      totals[position] ||= {};
      totals[position][candidate] = (totals[position][candidate] || 0) + 1;
    }
  }
  await electionRef.update({
    publishedResults: totals,
    totalBallots: ballots.size,
    resultsPublished: true,
    resultsPublishedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { published: true };
});
