class LessonContent {
  final String explanation;
  final String summary;
  final List<String> questions;

  const LessonContent({
    required this.explanation,
    required this.summary,
    required this.questions,
  });
}

const Map<String, LessonContent> lessonContents = {
  'الأعداد': LessonContent(
    explanation:
    'هنا يوضع شرح الدرس المعتمد من المنهج العراقي، بطريقة مبسطة ومناسبة للطالب.',
    summary:
    'هنا يوضع ملخص مختصر لأهم الأفكار الموجودة في الدرس.',
    questions: [
      'ما الفكرة الأساسية في هذا الدرس؟',
      'اذكر مثالاً على ما تعلمته في الدرس.',
      'حل السؤال التدريبي الخاص بالدرس.',
    ],
  ),
};