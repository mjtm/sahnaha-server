class BookItem {
  final String title;
  final String assetPath;

  const BookItem({
    required this.title,
    required this.assetPath,
  });
}

// الكتب مرتبة حسب الصف والمادة.
// كل كتاب يبقى PDF كامل بدون تقسيم الفصول.
const Map<String, Map<String, List<BookItem>>> booksByGrade = {
  'الأول الابتدائي': {
    'التربية الإسلامية': [
      BookItem(title: 'كتاب التربية الإسلامية', assetPath: 'assets/books/grade1/islamic.pdf'),
    ],
    'القراءة': [
      BookItem(title: 'كتاب القراءة', assetPath: 'assets/books/grade1/reading.pdf'),
    ],
    'الرياضيات': [
      BookItem(title: 'كتاب الرياضيات', assetPath: 'assets/books/grade1/math.pdf'),
      BookItem(title: 'تمارين الرياضيات', assetPath: 'assets/books/grade1/math_exercises.pdf'),
    ],
    'العلوم': [
      BookItem(title: 'كتاب العلوم', assetPath: 'assets/books/grade1/science.pdf'),
      BookItem(title: 'نشاط العلوم', assetPath: 'assets/books/grade1/science_activity.pdf'),
    ],
    'اللغة الإنكليزية': [
      BookItem(title: 'كتاب اللغة الإنكليزية', assetPath: 'assets/books/grade1/english.pdf'),
      BookItem(title: 'نشاط اللغة الإنكليزية', assetPath: 'assets/books/grade1/english_activity.pdf'),
    ],
    'التربية الأخلاقية': [
      BookItem(title: 'كتاب التربية الأخلاقية', assetPath: 'assets/books/grade1/moral.pdf'),
    ],
  },

  'الثاني الابتدائي': {
    'التربية الإسلامية': [
      BookItem(title: 'كتاب التربية الإسلامية', assetPath: 'assets/books/grade2/islamic.pdf'),
    ],
    'القراءة': [
      BookItem(title: 'كتاب القراءة', assetPath: 'assets/books/grade2/reading.pdf'),
    ],
    'الرياضيات': [
      BookItem(title: 'كتاب الرياضيات', assetPath: 'assets/books/grade2/math.pdf'),
      BookItem(title: 'تمارين الرياضيات', assetPath: 'assets/books/grade2/math_exercises.pdf'),
    ],
    'العلوم': [
      BookItem(title: 'كتاب العلوم', assetPath: 'assets/books/grade2/science.pdf'),
      BookItem(title: 'نشاط العلوم', assetPath: 'assets/books/grade2/science_activity.pdf'),
    ],
    'اللغة الإنكليزية': [
      BookItem(title: 'كتاب اللغة الإنكليزية', assetPath: 'assets/books/grade2/english.pdf'),
      BookItem(title: 'نشاط اللغة الإنكليزية', assetPath: 'assets/books/grade2/english_activity.pdf'),
    ],
    'التربية الأخلاقية': [
      BookItem(title: 'كتاب التربية الأخلاقية', assetPath: 'assets/books/grade2/moral.pdf'),
    ],
  },

  'الثالث الابتدائي': {
    'التربية الإسلامية': [
      BookItem(title: 'كتاب التربية الإسلامية', assetPath: 'assets/books/grade3/islamic.pdf'),
    ],
    'القراءة': [
      BookItem(title: 'كتاب القراءة', assetPath: 'assets/books/grade3/reading.pdf'),
    ],
    'الرياضيات': [
      BookItem(title: 'كتاب الرياضيات', assetPath: 'assets/books/grade3/math.pdf'),
      BookItem(title: 'تمارين الرياضيات', assetPath: 'assets/books/grade3/math_exercises.pdf'),
    ],
    'العلوم': [
      BookItem(title: 'كتاب العلوم', assetPath: 'assets/books/grade3/science.pdf'),
      BookItem(title: 'نشاط العلوم', assetPath: 'assets/books/grade3/science_activity.pdf'),
    ],
    'اللغة الإنكليزية': [
      BookItem(title: 'كتاب اللغة الإنكليزية', assetPath: 'assets/books/grade3/english.pdf'),
      BookItem(title: 'نشاط اللغة الإنكليزية', assetPath: 'assets/books/grade3/english_activity.pdf'),
    ],
  },

  'الرابع الابتدائي': {
    'التربية الإسلامية': [
      BookItem(title: 'كتاب التربية الإسلامية', assetPath: 'assets/books/grade4/islamic.pdf'),
    ],
    'القراءة': [
      BookItem(title: 'كتاب القراءة', assetPath: 'assets/books/grade4/reading.pdf'),
    ],
    'القواعد': [
      BookItem(title: 'قواعد اللغة العربية', assetPath: 'assets/books/grade4/arabic_rules.pdf'),
    ],
    'الرياضيات': [
      BookItem(title: 'كتاب الرياضيات', assetPath: 'assets/books/grade4/math.pdf'),
      BookItem(title: 'تمارين الرياضيات', assetPath: 'assets/books/grade4/math_exercises.pdf'),
    ],
    'العلوم': [
      BookItem(title: 'كتاب العلوم', assetPath: 'assets/books/grade4/science.pdf'),
      BookItem(title: 'نشاط العلوم', assetPath: 'assets/books/grade4/science_activity.pdf'),
    ],
    'اللغة الإنكليزية': [
      BookItem(title: 'كتاب اللغة الإنكليزية', assetPath: 'assets/books/grade4/english.pdf'),
      BookItem(title: 'نشاط اللغة الإنكليزية', assetPath: 'assets/books/grade4/english_activity.pdf'),
    ],
    'الاجتماعيات': [
      BookItem(title: 'كتاب الاجتماعيات', assetPath: 'assets/books/grade4/social.pdf'),
    ],
  },

  'الخامس الابتدائي': {
    'التربية الإسلامية': [
      BookItem(title: 'كتاب التربية الإسلامية', assetPath: 'assets/books/grade5/islamic.pdf'),
    ],
    'القراءة': [
      BookItem(title: 'كتاب القراءة', assetPath: 'assets/books/grade5/reading.pdf'),
    ],
    'القواعد': [
      BookItem(title: 'قواعد اللغة العربية', assetPath: 'assets/books/grade5/arabic_rules.pdf'),
    ],
    'الرياضيات': [
      BookItem(title: 'كتاب الرياضيات', assetPath: 'assets/books/grade5/math.pdf'),
      BookItem(title: 'تمارين الرياضيات', assetPath: 'assets/books/grade5/math_exercises.pdf'),
    ],
    'العلوم': [
      BookItem(title: 'كتاب العلوم', assetPath: 'assets/books/grade5/science.pdf'),
      BookItem(title: 'نشاط العلوم', assetPath: 'assets/books/grade5/science_activity.pdf'),
    ],
    'اللغة الإنكليزية': [
      BookItem(title: 'كتاب اللغة الإنكليزية', assetPath: 'assets/books/grade5/english.pdf'),
      BookItem(title: 'نشاط اللغة الإنكليزية', assetPath: 'assets/books/grade5/english_activity.pdf'),
    ],
    'الاجتماعيات': [
      BookItem(title: 'كتاب الاجتماعيات', assetPath: 'assets/books/grade5/social.pdf'),
    ],
  },

  'السادس الابتدائي': {
    'التربية الإسلامية': [
      BookItem(title: 'كتاب التربية الإسلامية', assetPath: 'assets/books/grade6/islamic.pdf'),
    ],
    'القراءة': [
      BookItem(title: 'كتاب القراءة', assetPath: 'assets/books/grade6/reading.pdf'),
    ],
    'القواعد': [
      BookItem(title: 'قواعد اللغة العربية', assetPath: 'assets/books/grade6/arabic_rules.pdf'),
    ],
    'الرياضيات': [
      BookItem(title: 'كتاب الرياضيات', assetPath: 'assets/books/grade6/math.pdf'),
      BookItem(title: 'تمارين الرياضيات', assetPath: 'assets/books/grade6/math_exercises.pdf'),
    ],
    'العلوم': [
      BookItem(title: 'كتاب العلوم', assetPath: 'assets/books/grade6/science.pdf'),
      BookItem(title: 'نشاط العلوم', assetPath: 'assets/books/grade6/science_activity.pdf'),
    ],
    'اللغة الإنكليزية': [
      BookItem(title: 'كتاب اللغة الإنكليزية', assetPath: 'assets/books/grade6/english.pdf'),
      BookItem(title: 'نشاط اللغة الإنكليزية', assetPath: 'assets/books/grade6/english_activity.pdf'),
    ],
    'الاجتماعيات': [
      BookItem(title: 'كتاب الاجتماعيات', assetPath: 'assets/books/grade6/social.pdf'),
    ],
  },

  'الأول المتوسط': {
    'التربية الإسلامية': [
      BookItem(title: 'كتاب التربية الإسلامية', assetPath: 'assets/books/middle1/islamic.pdf'),
    ],
    'اللغة العربية': [
      BookItem(title: 'قواعد اللغة العربية - الجزء الأول', assetPath: 'assets/books/middle1/arabic_rules_1.pdf'),
      BookItem(title: 'قواعد اللغة العربية - الجزء الثاني', assetPath: 'assets/books/middle1/arabic_rules_2.pdf'),
    ],
    'اللغة الإنكليزية': [
      BookItem(title: 'كتاب اللغة الإنكليزية', assetPath: 'assets/books/middle1/english.pdf'),
      BookItem(title: 'نشاط اللغة الإنكليزية', assetPath: 'assets/books/middle1/english_activity.pdf'),
    ],
    'اللغة الفرنسية': [
      BookItem(title: 'كتاب اللغة الفرنسية', assetPath: 'assets/books/middle1/french.pdf'),
      BookItem(title: 'نشاط اللغة الفرنسية', assetPath: 'assets/books/middle1/french_activity.pdf'),
    ],
    'الرياضيات': [
      BookItem(title: 'كتاب الرياضيات', assetPath: 'assets/books/middle1/math.pdf'),
    ],
    'الاجتماعيات': [
      BookItem(title: 'كتاب الاجتماعيات', assetPath: 'assets/books/middle1/social.pdf'),
    ],
    'الأحياء': [
      BookItem(title: 'كتاب الأحياء', assetPath: 'assets/books/middle1/biology.pdf'),
    ],
    'الكيمياء': [
      BookItem(title: 'كتاب الكيمياء', assetPath: 'assets/books/middle1/chemistry.pdf'),
    ],
    'الفيزياء': [
      BookItem(title: 'كتاب الفيزياء', assetPath: 'assets/books/middle1/physics.pdf'),
    ],
    'الحاسوب': [
      BookItem(title: 'كتاب الحاسوب', assetPath: 'assets/books/middle1/computer.pdf'),
    ],
    'التربية الأخلاقية': [
      BookItem(title: 'كتاب التربية الأخلاقية', assetPath: 'assets/books/middle1/moral.pdf'),
    ],
  },

  'الثاني المتوسط': {
    'التربية الإسلامية': [
      BookItem(title: 'كتاب التربية الإسلامية', assetPath: 'assets/books/middle2/islamic.pdf'),
    ],
    'اللغة العربية': [
      BookItem(
        title: 'قواعد اللغة العربية - الجزء الأول',
        assetPath: 'assets/books/middle2/arabic_rules_1.pdf',
      ),
      BookItem(
        title: 'قواعد اللغة العربية - الجزء الثاني',
        assetPath: 'assets/books/middle2/arabic_rules_2.pdf',
      ),
    ],
    'الرياضيات': [
      BookItem(title: 'كتاب الرياضيات', assetPath: 'assets/books/middle2/math.pdf'),
    ],
    'الاجتماعيات': [
      BookItem(title: 'كتاب الاجتماعيات', assetPath: 'assets/books/middle2/social.pdf'),
    ],
    'الأحياء': [
      BookItem(title: 'كتاب الأحياء', assetPath: 'assets/books/middle2/biology.pdf'),
    ],
    'الكيمياء': [
      BookItem(title: 'كتاب الكيمياء', assetPath: 'assets/books/middle2/chemistry.pdf'),
    ],
    'الفيزياء': [
      BookItem(title: 'كتاب الفيزياء', assetPath: 'assets/books/middle2/physics.pdf'),
    ],
    'اللغة الإنكليزية': [
      BookItem(title: 'كتاب اللغة الإنكليزية', assetPath: 'assets/books/middle2/english.pdf'),
      BookItem(title: 'نشاط اللغة الإنكليزية', assetPath: 'assets/books/middle2/english_activity.pdf'),
    ],
    'اللغة الفرنسية': [
      BookItem(title: 'كتاب اللغة الفرنسية', assetPath: 'assets/books/middle2/french.pdf'),
    ],
    'الحاسوب': [
      BookItem(title: 'كتاب الحاسوب', assetPath: 'assets/books/middle2/computer.pdf'),
    ],
    'التربية الأخلاقية': [
      BookItem(title: 'كتاب التربية الأخلاقية', assetPath: 'assets/books/middle2/moral.pdf'),
    ],
  },

  'الثالث المتوسط': {
    'التربية الإسلامية': [
      BookItem(
        title: 'كتاب التربية الإسلامية',
        assetPath: 'assets/books/middle3/islamic.pdf',
      ),
    ],
    'اللغة العربية': [
      BookItem(
        title: 'اللغة العربية - الجزء الأول',
        assetPath: 'assets/books/middle3/arabic_1.pdf',
      ),
      BookItem(
        title: 'اللغة العربية - الجزء الثاني',
        assetPath: 'assets/books/middle3/arabic_2.pdf',
      ),
    ],
    'اللغة الإنكليزية': [
      BookItem(
        title: 'كتاب اللغة الإنكليزية',
        assetPath: 'assets/books/middle3/english.pdf',
      ),
      BookItem(
        title: 'نشاط اللغة الإنكليزية',
        assetPath: 'assets/books/middle3/english_activity.pdf',
      ),
    ],
    'اللغة الفرنسية': [
      BookItem(
        title: 'كتاب اللغة الفرنسية',
        assetPath: 'assets/books/middle3/french.pdf',
      ),
    ],
    'الرياضيات': [
      BookItem(
        title: 'كتاب الرياضيات',
        assetPath: 'assets/books/middle3/math.pdf',
      ),
    ],
    'الاجتماعيات': [
      BookItem(
        title: 'كتاب الاجتماعيات',
        assetPath: 'assets/books/middle3/social.pdf',
      ),
    ],
    'الأحياء': [
      BookItem(
        title: 'كتاب الأحياء',
        assetPath: 'assets/books/middle3/biology.pdf',
      ),
    ],
    'الكيمياء': [
      BookItem(
        title: 'كتاب الكيمياء',
        assetPath: 'assets/books/middle3/chemistry.pdf',
      ),
    ],
    'الفيزياء': [
      BookItem(
        title: 'كتاب الفيزياء',
        assetPath: 'assets/books/middle3/physics.pdf',
      ),
    ],
  },
};
