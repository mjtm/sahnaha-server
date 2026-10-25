class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
}

const Map<String, List<QuizQuestion>> quizQuestions = {
  'الأعداد': [
    QuizQuestion(
      question: 'كم عدد الأصابع في اليد الواحدة؟',
      options: [
        '3',
        '4',
        '5',
        '6',
      ],
      correctAnswer: 2,
    ),

    QuizQuestion(
      question: 'أي عدد يأتي بعد 2؟',
      options: [
        '1',
        '3',
        '4',
        '5',
      ],
      correctAnswer: 1,
    ),

    QuizQuestion(
      question: 'أي عدد هو الأكبر؟',
      options: [
        '1',
        '2',
        '5',
        '3',
      ],
      correctAnswer: 2,
    ),
  ],
};