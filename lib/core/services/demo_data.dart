import '../../models/app_models.dart';

const demoStudent = Student(
  uid: 'demo-student-uid',
  studentId: '2024-1887',
  fullName: 'Sarah Santos',
  course: 'BS Information Technology',
  yearLevel: '3rd Year',
  section: 'IT-3A',
  email: 'sarah.santos@example.edu',
  role: 'student',
);

final demoElections = <Election>[
  const Election(
    id: 'student-council',
    title: 'Student Council Elections',
    description: 'Choose your representatives for the student council.',
    positions: [
      BallotPosition('President', [
        'Daniel Santos',
        'Maya Lopez',
        'Cleo Reyes',
        'Noah Lim',
      ]),
      BallotPosition('Vice President', [
        'Ariana Cruz',
        'Nathan Perez',
        'Brianna Lee',
        'Gabriel Yu',
      ]),
      BallotPosition('Secretary', [
        'Grace Rivera',
        'Karl Santos',
        'Rina Gomez',
        'Milo Cruz',
      ]),
      BallotPosition('Treasurer', [
        'Aaron Tan',
        'Jade Santos',
        'Oscar Delos',
        'Leah Marquez',
      ]),
      BallotPosition('Auditor', [
        'Ysa Ramos',
        'Clemente Park',
        'Dylan Chavez',
        'Ren Flores',
      ]),
    ],
  ),
  const Election(
    id: 'forum-council',
    title: 'The Forum Council Elections',
    description: 'Select the next leaders of The Forum student organization.',
    positions: [
      BallotPosition('President', [
        'Mika Valdez',
        'Edgar Ramos',
        'Lia Santos',
        'Sam Owen',
      ]),
      BallotPosition('Vice President', [
        'Loren Perez',
        'Victor Sol',
        'Ann Cruz',
        'Jin Park',
      ]),
      BallotPosition('Secretary', [
        'Mae Flores',
        'Luis Dela Torre',
        'Alyssa Gomez',
        'Theo Smith',
      ]),
      BallotPosition('Treasurer', [
        'Rene Castillo',
        'Ivy Ramos',
        'Andre Lim',
        'Tess Navarro',
      ]),
      BallotPosition('Auditor', [
        'Nico Reyes',
        'Sofia Tan',
        'James Yu',
        'Mina Cruz',
      ]),
    ],
  ),
  const Election(
    id: 'techsociety-council',
    title: 'TechSociety Council Elections',
    description: 'Choose the TechSociety student representatives.',
    positions: [
      BallotPosition('President', [
        'Jansen Dela Cruz',
        'Nina Baldonado',
        'Andre Santos',
        'Rae Villanueva',
      ]),
      BallotPosition('Vice President', [
        'Paolo Ramos',
        'Kimberly Joy',
        'Theo Brown',
        'Janelle Cuevas',
      ]),
      BallotPosition('Secretary', [
        'Chloe Ramos',
        'Ethan Lim',
        'Aisha Nguyen',
        'Reed Santos',
      ]),
      BallotPosition('Treasurer', [
        'Ivan De Leon',
        'April Kwan',
        'Martha Tan',
        'Harley Cruz',
      ]),
      BallotPosition('Auditor', [
        'Vince Ramos',
        'Ella Park',
        'Leo Santos',
        'Mia Flores',
      ]),
    ],
  ),
];

final demoSurveys = <Survey>[
  const Survey(
    id: 'academic-experience',
    title: 'Academic Experience Survey',
    description: 'Tell us about your learning experience this term.',
    questions: [
      SurveyQuestion(
        id: 'learning',
        prompt: 'How satisfied are you with your student learning experience?',
        options: ['Very satisfied', 'Satisfied', 'Neutral', 'Dissatisfied'],
      ),
      SurveyQuestion(
        id: 'teaching',
        prompt: 'How would you rate the quality of teaching?',
        options: ['Excellent', 'Good', 'Fair', 'Needs improvement'],
      ),
      SurveyQuestion(
        id: 'environment',
        prompt: 'How comfortable is your classroom environment?',
        options: [
          'Very comfortable',
          'Comfortable',
          'Neutral',
          'Uncomfortable',
        ],
      ),
      SurveyQuestion(
        id: 'resources',
        prompt: 'Which academic resources do you use? (Select all that apply)',
        options: ['Library', 'Online modules', 'Tutoring', 'Study groups'],
        multiple: true,
      ),
      SurveyQuestion(
        id: 'suggestion',
        prompt: 'What could improve your academic experience?',
        options: [],
        textAnswer: true,
      ),
    ],
  ),
  const Survey(
    id: 'student-engagement',
    title: 'University Survey on Student Engagement',
    description: 'Help us understand student involvement and engagement.',
    questions: [
      SurveyQuestion(
        id: 'participation',
        prompt: 'How often do you participate in classroom discussions?',
        options: ['Always', 'Often', 'Sometimes', 'Rarely'],
      ),
      SurveyQuestion(
        id: 'communication',
        prompt: 'How comfortable are you communicating with instructors?',
        options: [
          'Very comfortable',
          'Comfortable',
          'Neutral',
          'Uncomfortable',
        ],
      ),
      SurveyQuestion(
        id: 'activities',
        prompt: 'Which academic activities have you joined?',
        options: ['Clubs', 'Workshops', 'Research', 'Peer mentoring'],
        multiple: true,
      ),
      SurveyQuestion(
        id: 'involvement',
        prompt: 'What would help you become more involved?',
        options: [],
        textAnswer: true,
      ),
    ],
  ),
  const Survey(
    id: 'facilities',
    title: 'University Survey on Facilities and Learning Environment',
    description: 'Share feedback about campus facilities and learning spaces.',
    questions: [
      SurveyQuestion(
        id: 'classrooms',
        prompt: 'How would you rate classroom facilities?',
        options: ['Excellent', 'Good', 'Fair', 'Poor'],
      ),
      SurveyQuestion(
        id: 'equipment',
        prompt: 'How well-maintained is school equipment?',
        options: ['Very well', 'Well', 'Fair', 'Poorly'],
      ),
      SurveyQuestion(
        id: 'spaces',
        prompt: 'Which learning spaces do you use? (Select all that apply)',
        options: ['Library', 'Study hall', 'Computer lab', 'Outdoor areas'],
        multiple: true,
      ),
      SurveyQuestion(
        id: 'cleanliness',
        prompt: 'How clean and accessible are campus spaces?',
        options: ['Very good', 'Good', 'Fair', 'Needs improvement'],
      ),
      SurveyQuestion(
        id: 'comments',
        prompt: 'How could we improve the learning environment?',
        options: [],
        textAnswer: true,
      ),
    ],
  ),
];

const demoNotifications = <AppNotification>[
  AppNotification(
    title: 'Student Council Elections are open',
    message: 'Cast your vote before the election deadline.',
    time: 'Today · 9:15 AM',
  ),
  AppNotification(
    title: 'New survey available',
    message: 'Share your thoughts in the Academic Experience Survey.',
    time: 'Yesterday · 2:30 PM',
  ),
  AppNotification(
    title: 'Welcome to the voting portal',
    message: 'Explore the voting guide before you begin.',
    time: 'Nov 01 · 8:00 AM',
  ),
];
