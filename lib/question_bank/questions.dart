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
  'الابتدائي - الرياضيات': [
    QuizQuestion(
      question: 'ما ناتج 7 + 8؟',
      options: ['14', '15', '16', '17'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما ناتج 16 - 9؟',
      options: ['5', '6', '7', '8'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما ناتج 6 × 5؟',
      options: ['25', '30', '35', '40'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما ناتج 42 ÷ 7؟',
      options: ['5', '6', '7', '8'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي الأعداد الآتية زوجي؟',
      options: ['13', '17', '20', '25'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما قيمة الرقم 5 في العدد 352؟',
      options: ['5', '50', '500', '35'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'كم ضلعاً للمربع؟',
      options: ['3', '4', '5', '6'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما نصف العدد 18؟',
      options: ['6', '8', '9', '12'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما ناتج 9 × 3؟',
      options: ['18', '21', '27', '30'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'أي كسر يساوي النصف؟',
      options: ['1/3', '2/4', '3/5', '1/4'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'كم سنتيمتراً في المتر الواحد؟',
      options: ['10', '50', '100', '1000'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما العدد الذي يأتي بعد 999؟',
      options: ['998', '100', '1000', '1001'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما ناتج 125 + 25؟',
      options: ['140', '150', '160', '175'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما ناتج 80 - 35؟',
      options: ['35', '40', '45', '55'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'كم دقيقة في ساعتين؟',
      options: ['60', '90', '100', '120'],
      correctAnswer: 3,
    ),
    QuizQuestion(
      question: 'ما محيط مربع طول ضلعه 3 سم؟',
      options: ['6 سم', '9 سم', '12 سم', '15 سم'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'أي عدد أكبر؟',
      options: ['0.7', '0.5', '0.3', '0.2'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'ما ناتج 4 × 8؟',
      options: ['24', '28', '32', '36'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'كم زاوية قائمة للمستطيل؟',
      options: ['1', '2', '3', '4'],
      correctAnswer: 3,
    ),
    QuizQuestion(
      question: 'ما ناتج 1000 - 1؟',
      options: ['999', '990', '1001', '900'],
      correctAnswer: 0,
    ),

    QuizQuestion(
      question: 'ما ناتج 9 + 6؟',
      options: ['14', '15', '16', '17'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما ناتج 24 ÷ 4؟',
      options: ['4', '5', '6', '7'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما ناتج 7 × 3؟',
      options: ['18', '21', '24', '27'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي كسر يمثل النصف؟',
      options: ['1/3', '1/2', '1/4', '2/3'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'كم ضلعاً للمستطيل؟',
      options: ['3', '4', '5', '6'],
      correctAnswer: 1,
    ),
  ],

  'الابتدائي - اللغة العربية': [
    QuizQuestion(
      question: 'ما جمع كلمة «قلم»؟',
      options: ['أقلام', 'قلمان', 'قلمون', 'قلمات'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'ما ضد كلمة «قريب»؟',
      options: ['صغير', 'بعيد', 'سريع', 'قصير'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي كلمة من الآتي اسم؟',
      options: ['يكتب', 'اكتب', 'مدرسة', 'ذهب'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'أي كلمة من الآتي فعل؟',
      options: ['شجرة', 'يلعب', 'كتاب', 'باب'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما مفرد كلمة «أشجار»؟',
      options: ['شجرات', 'شجرة', 'شجرتان', 'غابة'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي كلمة تبدأ بهمزة قطع؟',
      options: ['استخرج', 'ابن', 'أحمد', 'اسم'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما علامة الاستفهام؟',
      options: ['،', '؛', '؟', '.'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'أي كلمة تنتهي بتاء مربوطة؟',
      options: ['بيت', 'مدرسة', 'صوت', 'زيت'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما مرادف كلمة «سعيد»؟',
      options: ['حزين', 'فرح', 'غاضب', 'متعب'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما ضد كلمة «النظافة»؟',
      options: ['الترتيب', 'الوسخ', 'الجمال', 'النظام'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'في جملة «قرأ الطالب الدرس»، من قام بالفعل؟',
      options: ['الدرس', 'قرأ', 'الطالب', 'لا أحد'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'أي الكلمات جمع تكسير؟',
      options: ['معلمون', 'طالبات', 'كتب', 'مهندسان'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما نوع كلمة «جميل»؟',
      options: ['اسم', 'فعل', 'حرف', 'ضمير'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'أي حرف يأتي بعد «س»؟',
      options: ['ر', 'ش', 'ص', 'ض'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما المثنى من كلمة «طالب»؟',
      options: ['طلاب', 'طالبان', 'طالبون', 'طالبة'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي جملة تنتهي بنقطة عادةً؟',
      options: ['أين بيتك؟', 'ما أجمل الربيع!', 'عاد أبي إلى البيت.', 'هل حضرت؟'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما ضد كلمة «قوي»؟',
      options: ['شجاع', 'ضعيف', 'متين', 'كبير'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي كلمة فيها مد بالألف؟',
      options: ['باب', 'بنت', 'كتب', 'علم'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'ما جمع كلمة «معلم»؟',
      options: ['معالم', 'معلمون', 'تعليم', 'علامة'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي كلمة تدل على مكان؟',
      options: ['يجري', 'سريع', 'حديقة', 'أكل'],
      correctAnswer: 2,
    ),

    QuizQuestion(
      question: 'ما ضد كلمة «قريب»؟',
      options: ['بعيد', 'صغير', 'سريع', 'قصير'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'أي كلمة تبدأ بهمزة قطع؟',
      options: ['أحمد', 'ابن', 'اسم', 'استخرج'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'ما جمع كلمة «قلم»؟',
      options: ['أقلام', 'قلمان', 'قالم', 'قلمات'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'ما نوع كلمة «يلعب»؟',
      options: ['اسم', 'فعل', 'حرف', 'صفة'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي علامة توضع في نهاية السؤال؟',
      options: ['،', '؛', '؟', '.'],
      correctAnswer: 2,
    ),
  ],

  'الابتدائي - العلوم': [
    QuizQuestion(
      question: 'أي مما يأتي كائن حي؟',
      options: ['صخرة', 'نبات', 'قلم', 'كرسي'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما العضو الذي نستخدمه للرؤية؟',
      options: ['الأذن', 'العين', 'الأنف', 'اليد'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما مصدر الضوء والحرارة الرئيس للأرض؟',
      options: ['القمر', 'الشمس', 'المريخ', 'السحاب'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'في أي حالة يكون الثلج؟',
      options: ['صلبة', 'سائلة', 'غازية', 'بلا شكل'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'أي حيوان يتنفس بالخياشيم؟',
      options: ['القطة', 'السمكة', 'الدجاجة', 'الحصان'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما الذي تحتاجه النباتات لصنع غذائها؟',
      options: ['ضوء الشمس', 'الرمل فقط', 'الظلام', 'البلاستيك'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'أي حاسة نستخدمها لمعرفة الروائح؟',
      options: ['السمع', 'الشم', 'البصر', 'التذوق'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي مادة تنجذب عادةً إلى المغناطيس؟',
      options: ['الخشب', 'الحديد', 'الورق', 'الزجاج'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما الكوكب الذي نعيش عليه؟',
      options: ['المريخ', 'الأرض', 'زحل', 'عطارد'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي جزء من النبات يمتص الماء غالباً؟',
      options: ['الزهرة', 'الجذر', 'الثمرة', 'الورقة فقط'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي مما يأتي مصدر طاقة متجدد؟',
      options: ['الفحم', 'النفط', 'الشمس', 'الغاز الطبيعي'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما العضو الذي يضخ الدم؟',
      options: ['القلب', 'المعدة', 'الرئة', 'الكلية'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'ما الحالة الغازية للماء؟',
      options: ['الثلج', 'البخار', 'المطر', 'الندى'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي حيوان يبيض؟',
      options: ['الدجاجة', 'القطة', 'البقرة', 'الحصان'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'ما الذي يحمي الرأس؟',
      options: ['الجمجمة', 'المعدة', 'الرئة', 'الأمعاء'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'ما القوة التي تسحب الأجسام نحو الأرض؟',
      options: ['الاحتكاك', 'الجاذبية', 'المغناطيسية فقط', 'الضوء'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي مما يأتي من الحواس الخمس؟',
      options: ['التوازن', 'الشم', 'النوم', 'التفكير'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي جزء من الجسم يساعدنا على السمع؟',
      options: ['العين', 'الأذن', 'اللسان', 'الأنف'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما اسم صغير الضفدع في بداية نموه؟',
      options: ['شرغوف', 'فرخ', 'جرو', 'حمل'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'أي مما يأتي مادة شفافة؟',
      options: ['الزجاج النظيف', 'الخشب', 'الحجر', 'الحديد'],
      correctAnswer: 0,
    ),

    QuizQuestion(
      question: 'أي جزء من النبات يمتص الماء من التربة؟',
      options: ['الزهرة', 'الجذر', 'الثمرة', 'الورقة'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما الحالة التي يكون عليها الثلج؟',
      options: ['سائلة', 'غازية', 'صلبة', 'بلازما'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'أي حاسة نستخدمها لمعرفة الروائح؟',
      options: ['السمع', 'الشم', 'البصر', 'اللمس'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما مصدر الضوء الطبيعي نهاراً؟',
      options: ['القمر', 'الشمس', 'المصباح', 'المرآة'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي حيوان يبيض؟',
      options: ['القطة', 'البقرة', 'الدجاجة', 'الحصان'],
      correctAnswer: 2,
    ),
  ],

  'الابتدائي - اللغة الإنكليزية': [
    QuizQuestion(
      question: 'What is the meaning of "book"?',
      options: ['كتاب', 'قلم', 'باب', 'بيت'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'Choose the correct word: I ___ a student.',
      options: ['am', 'is', 'are', 'be'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'What is the opposite of "big"?',
      options: ['small', 'long', 'fast', 'hot'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'What comes after B?',
      options: ['A', 'C', 'D', 'E'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'What is the plural of "cat"?',
      options: ['cates', 'cats', 'cat', 'caties'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'Choose the correct article: ___ apple.',
      options: ['A', 'An', 'Thee', 'Am'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'What is the meaning of "school"?',
      options: ['مدرسة', 'سيارة', 'حديقة', 'ماء'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'Choose the correct word: She ___ happy.',
      options: ['am', 'are', 'is', 'be'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'What is the opposite of "hot"?',
      options: ['warm', 'cold', 'tall', 'new'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'Which one is a colour?',
      options: ['blue', 'chair', 'run', 'book'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'What is the meaning of "dog"?',
      options: ['قطة', 'كلب', 'حصان', 'طائر'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'Choose the correct word: They ___ friends.',
      options: ['is', 'am', 'are', 'be'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'Which word is a number?',
      options: ['seven', 'green', 'door', 'happy'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'What is the past of "go"?',
      options: ['goed', 'went', 'goes', 'going'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'Choose the correct pronoun: Ali is a boy. ___ is tall.',
      options: ['She', 'It', 'He', 'They'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'What is the meaning of "water"?',
      options: ['نار', 'ماء', 'هواء', 'تراب'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'Which word is a verb?',
      options: ['table', 'write', 'blue', 'school'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'Choose the correct spelling.',
      options: ['frend', 'friend', 'freind', 'frind'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'What is the opposite of "old"?',
      options: ['young', 'slow', 'small', 'dark'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'Complete: We ___ English.',
      options: ['studies', 'study', 'studying', 'is study'],
      correctAnswer: 1,
    ),

    QuizQuestion(
      question: 'What is the meaning of "water"?',
      options: ['ماء', 'نار', 'هواء', 'تراب'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'Choose the correct word: She ___ happy.',
      options: ['am', 'is', 'are', 'be'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'What is the plural of "cat"?',
      options: ['cates', 'cat', 'cats', 'caties'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'Which one is a color?',
      options: ['Chair', 'Blue', 'Book', 'Run'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'What comes before the letter D?',
      options: ['B', 'C', 'E', 'F'],
      correctAnswer: 1,
    ),
  ],

  'المتوسط - الرياضيات': [
    QuizQuestion(
      question: 'ما ناتج 3²؟',
      options: ['6', '9', '12', '27'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'حل المعادلة: س + 7 = 12',
      options: ['3', '4', '5', '6'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما قيمة 2 × (3 + 4)؟',
      options: ['10', '12', '14', '16'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما ناتج 5² - 9؟',
      options: ['14', '16', '18', '20'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'إذا كان محيط مربع 20 سم، فما طول ضلعه؟',
      options: ['4 سم', '5 سم', '10 سم', '20 سم'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما العدد الأولي من الآتي؟',
      options: ['9', '15', '17', '21'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما ناتج 3/4 + 1/4؟',
      options: ['1/2', '1', '4/8', '3/8'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما ناتج 0.5 × 10؟',
      options: ['0.5', '5', '50', '0.05'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'إذا كانت الزاويتان متتامتين وإحداهما 35°، فالأخرى؟',
      options: ['45°', '55°', '65°', '145°'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما الجذر التربيعي الموجب للعدد 81؟',
      options: ['7', '8', '9', '10'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'حل المعادلة: 2س = 18',
      options: ['6', '8', '9', '16'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما ناتج 15% من 200؟',
      options: ['15', '20', '30', '45'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما إحداثيا نقطة الأصل في المستوى الإحداثي؟',
      options: ['(1,1)', '(0,0)', '(0,1)', '(1,0)'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما مجموع زوايا المثلث؟',
      options: ['90°', '180°', '270°', '360°'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما ناتج (-3) + 8؟',
      options: ['-11', '-5', '5', '11'],
      correctAnswer: 2,
    ),

    QuizQuestion(
      question: 'إذا كان 3x = 18، فما قيمة x؟',
      options: ['3', '6', '9', '12'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما ناتج (-4) + 9؟',
      options: ['-13', '-5', '5', '13'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما مساحة مستطيل طوله 8 وعرضه 3؟',
      options: ['11', '22', '24', '28'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما الجذر التربيعي للعدد 81؟',
      options: ['7', '8', '9', '10'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'إذا كانت الزاوية 90 درجة، فهي زاوية:',
      options: ['حادة', 'قائمة', 'منفرجة', 'مستقيمة'],
      correctAnswer: 1,
    ),

    QuizQuestion(
      question: 'حل المعادلة x + 7 = 12.',
      options: ['3', '4', '5', '6'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما ناتج 5²؟',
      options: ['10', '15', '20', '25'],
      correctAnswer: 3,
    ),
    QuizQuestion(
      question: 'ما محيط مربع طول ضلعه 4 سم؟',
      options: ['8 سم', '12 سم', '16 سم', '20 سم'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما العدد الأولي من بين الآتي؟',
      options: ['9', '15', '17', '21'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما قيمة 2(3 + 4)؟',
      options: ['10', '12', '14', '16'],
      correctAnswer: 2,
    ),
  ],

  'المتوسط - اللغة العربية': [
    QuizQuestion(
      question: 'ما نوع الأسلوب في «لا تهمل واجبك»؟',
      options: ['استفهام', 'نهي', 'تعجب', 'نداء'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما علامة رفع المبتدأ المفرد؟',
      options: ['الفتحة', 'الكسرة', 'الضمة', 'السكون'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'في جملة «كتب الطالب الدرس»، ما الفاعل؟',
      options: ['كتب', 'الطالب', 'الدرس', 'لا يوجد'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي الكلمات همزتها همزة قطع؟',
      options: ['استعمال', 'ابن', 'أكرم', 'اسم'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما جمع كلمة «مدينة»؟',
      options: ['مدائن', 'مدينتان', 'مديني', 'مدينات فقط'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'ما نوع الفعل «اكتبْ»؟',
      options: ['ماضٍ', 'مضارع', 'أمر', 'اسم'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما ضد كلمة «التواضع»؟',
      options: ['الكرم', 'التكبر', 'الصبر', 'الصدق'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي جملة اسمية؟',
      options: ['يقرأ الطالب', 'الجو جميل', 'اكتب الدرس', 'ذهب علي'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما علامة نصب المفعول به المفرد غالباً؟',
      options: ['الضمة', 'الفتحة', 'الكسرة', 'السكون'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما مرادف «شجاع»؟',
      options: ['جبان', 'جريء', 'حزين', 'ضعيف'],
      correctAnswer: 1,
    ),

    QuizQuestion(
      question: 'ما إعراب كلمة «الطالبُ» في جملة «حضر الطالبُ»؟',
      options: ['مفعول به', 'فاعل مرفوع', 'مضاف إليه', 'حال'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي الكلمات الآتية جمع تكسير؟',
      options: ['معلمون', 'طالبات', 'كتب', 'مهندسان'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما نوع الأسلوب في «لا تهمل واجبك»؟',
      options: ['استفهام', 'نهي', 'تعجب', 'نداء'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما ضد كلمة «الشجاعة»؟',
      options: ['الكرم', 'الجبن', 'الصبر', 'الصدق'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي كلمة من الآتي فعل ماضٍ؟',
      options: ['يكتب', 'اكتب', 'كتب', 'كاتب'],
      correctAnswer: 2,
    ),

    QuizQuestion(
      question: 'ما علامة رفع المثنى؟',
      options: ['الضمة', 'الألف', 'الواو', 'الكسرة'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما نوع كلمة «في»؟',
      options: ['اسم', 'فعل', 'حرف جر', 'صفة'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما جمع كلمة «مدينة»؟',
      options: ['مدائن', 'مدينتان', 'مديني', 'مدينات'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'أي جملة تحتوي على أسلوب استفهام؟',
      options: ['ما أجمل السماء!', 'أين كتابك؟', 'لا تتأخر.', 'يا طالب اجتهد.'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما مرادف كلمة «سعيد»؟',
      options: ['حزين', 'فرح', 'غاضب', 'متعب'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي كلمة تحتوي على تاء مربوطة؟',
      options: ['بيت', 'مدرسة', 'صوت', 'وقت'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما نوع الجملة «الجوُّ جميلٌ»؟',
      options: ['فعلية', 'اسمية', 'شرطية', 'تعجبية'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما ضد كلمة «النجاح»؟',
      options: ['التفوق', 'الفوز', 'الفشل', 'التقدم'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'أي مما يأتي حرف عطف؟',
      options: ['من', 'إلى', 'ثم', 'على'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما الفعل المضارع من «نجح»؟',
      options: ['ناجح', 'ينجح', 'نجاح', 'ناجحون'],
      correctAnswer: 1,
    ),
  ],

  'المتوسط - العلوم': [
    QuizQuestion(
      question: 'ما وحدة قياس القوة في النظام الدولي؟',
      options: ['الجول', 'النيوتن', 'الواط', 'الأمبير'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما الغاز الذي تمتصه النباتات في عملية البناء الضوئي؟',
      options: ['الأكسجين', 'ثاني أكسيد الكربون', 'الهيدروجين', 'الهيليوم'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما مركز الذرة؟',
      options: ['الإلكترون', 'النواة', 'الغلاف الخارجي', 'الجزيء'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي كوكب يشتهر بحلقاته؟',
      options: ['عطارد', 'زحل', 'الأرض', 'المريخ'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما العملية التي يتحول فيها السائل إلى غاز؟',
      options: ['التجمد', 'التكاثف', 'التبخر', 'الانصهار'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما العضية المسؤولة عن إنتاج الطاقة في الخلية؟',
      options: ['النواة', 'الميتوكوندريا', 'الغشاء', 'الفجوة'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي من الآتي موصل جيد للكهرباء؟',
      options: ['النحاس', 'الخشب الجاف', 'المطاط', 'البلاستيك'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'ما الرمز الكيميائي للماء؟',
      options: ['CO2', 'O2', 'H2O', 'NaCl'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما القوة التي تعيق حركة سطحين متلامسين؟',
      options: ['الجاذبية', 'الاحتكاك', 'الطفو', 'الدفع فقط'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما اسم انتقال الحرارة عبر حركة السوائل والغازات؟',
      options: ['التوصيل', 'الحمل', 'الإشعاع', 'الانعكاس'],
      correctAnswer: 1,
    ),

    QuizQuestion(
      question: 'ما وحدة قياس القوة؟',
      options: ['الجول', 'النيوتن', 'الواط', 'الأمبير'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما الغاز الذي تحتاجه عملية الاحتراق غالباً؟',
      options: ['الأوكسجين', 'النيتروجين', 'الهيليوم', 'الهيدروجين'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'ما العضية المسؤولة عن إنتاج الطاقة في الخلية؟',
      options: ['النواة', 'الميتوكوندريا', 'الغشاء', 'الفجوة'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما الكوكب الأقرب إلى الشمس؟',
      options: ['الزهرة', 'الأرض', 'عطارد', 'المريخ'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما العملية التي يتحول فيها السائل إلى غاز؟',
      options: ['التجمد', 'التكاثف', 'التبخر', 'الانصهار'],
      correctAnswer: 2,
    ),

    QuizQuestion(
      question: 'ما وحدة قياس شدة التيار الكهربائي؟',
      options: ['الفولت', 'الأمبير', 'الأوم', 'النيوتن'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما الرمز الكيميائي للماء؟',
      options: ['CO2', 'O2', 'H2O', 'NaCl'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'أي جزء من الخلية يحتوي غالباً على المادة الوراثية؟',
      options: ['النواة', 'الغشاء', 'الجدار', 'السيتوبلازم فقط'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'ما القوة التي تجذب الأجسام نحو الأرض؟',
      options: ['الاحتكاك', 'المغناطيسية', 'الجاذبية', 'الطفو'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'أي مادة تعد موصلاً جيداً للكهرباء؟',
      options: ['الخشب', 'البلاستيك', 'النحاس', 'الزجاج'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما اسم تحول الغاز إلى سائل؟',
      options: ['التبخر', 'التكاثف', 'الانصهار', 'التسامي'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي عضو مسؤول عن تنقية الدم وإنتاج البول؟',
      options: ['القلب', 'الرئتان', 'الكليتان', 'المعدة'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما مصدر الطاقة الأساسي لمعظم الأنظمة البيئية؟',
      options: ['الشمس', 'القمر', 'التربة', 'الرياح فقط'],
      correctAnswer: 0,
    ),
    QuizQuestion(
      question: 'أي كوكب يعرف بالكوكب الأحمر؟',
      options: ['المشتري', 'المريخ', 'زحل', 'عطارد'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما سرعة الضوء تقريباً في الفراغ؟',
      options: ['300 كم/ث', '3,000 كم/ث', '30,000 كم/ث', '300,000 كم/ث'],
      correctAnswer: 3,
    ),
  ],

  'معلومات عامة': [
    QuizQuestion(
      question: 'ما عاصمة العراق؟',
      options: ['البصرة', 'بغداد', 'الموصل', 'أربيل'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما أكبر محيط في العالم؟',
      options: ['الأطلسي', 'الهندي', 'الهادئ', 'المتجمد الشمالي'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'كم عدد قارات العالم وفق التقسيم الشائع؟',
      options: ['5', '6', '7', '8'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما العملة الرسمية للعراق؟',
      options: ['الريال', 'الدينار العراقي', 'الليرة', 'الدرهم'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما عاصمة اليابان؟',
      options: ['بكين', 'طوكيو', 'سيول', 'بانكوك'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'أي معدن رمزه الكيميائي Au؟',
      options: ['الفضة', 'الذهب', 'الحديد', 'النحاس'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'كم ثانية في الدقيقة؟',
      options: ['30', '45', '60', '100'],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: 'ما أكبر حيوان معروف يعيش حالياً؟',
      options: ['الفيل الأفريقي', 'الحوت الأزرق', 'الزرافة', 'القرش الأبيض'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما اسم الجهاز الذي يقيس درجة الحرارة؟',
      options: ['البارومتر', 'الترمومتر', 'البوصلة', 'المسطرة'],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: 'ما اللغة الرسمية الأكثر استخداماً في البرازيل؟',
      options: ['الإسبانية', 'البرتغالية', 'الفرنسية', 'الإنكليزية'],
      correctAnswer: 1,
    ),
  ],

};