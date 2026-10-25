import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart' as mlkit;

/// صفحة تعليم الأحرف والأرقام للأطفال.
/// أضف flutter_tts إلى pubspec.yaml قبل تشغيل الصفحة.
class LearningLettersNumbersPage extends StatefulWidget {
  final String initialSection;
  final String initialTarget;
  final bool initialEnglish;

  const LearningLettersNumbersPage({
    super.key,
    this.initialSection = 'home',
    this.initialTarget = 'أ',
    this.initialEnglish = false,
  });

  @override
  State<LearningLettersNumbersPage> createState() =>
      _LearningLettersNumbersPageState();
}

class _LearningLettersNumbersPageState
    extends State<LearningLettersNumbersPage> {
  static const Color navy = Color(0xFF26364A);
  static const Color gold = Color(0xFFB08D57);
  static const Color pageBg = Color(0xFFF7F3EA);

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _applausePlayer = AudioPlayer();
  final Random _random = Random();
  Timer? _celebrationTimer;

  String _section = 'home'; // home, arabic, english, numbers, quiz
  String _numberStyle = 'both';
  String _numberGroup = 'all';
  String _quizKind = 'letters';
  String _question = '';
  List<String> _choices = [];
  String? _chosen;
  String _feedback = 'اختار الإجابة الصحيحة ⭐';
  int _score = 0;
  int _round = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialSection == 'writing') {
      _section = 'writing';
      _writingTarget = widget.initialTarget;
      _writingEnglish = widget.initialEnglish;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prepareInkRecognizer(widget.initialEnglish ? 'en' : 'ar');
      });
    }
  }

  // ==================== الصبورة الناطقة ====================
  mlkit.DigitalInkRecognizer? _inkRecognizer;
  mlkit.DigitalInkRecognizer? _arabicInkRecognizer;
  mlkit.DigitalInkRecognizer? _englishInkRecognizer;
  final mlkit.DigitalInkRecognizerModelManager _inkModelManager =
  mlkit.DigitalInkRecognizerModelManager();
  Future<void>? _arabicModelFuture;
  Future<void>? _englishModelFuture;
  final List<mlkit.Stroke> _drawingStrokes = [];
  mlkit.Stroke? _activeStroke;
  String _writingTarget = '';
  bool _writingEnglish = false;
  String _writingCategory = 'arabicLetters';
  bool _recognizing = false;
  bool _modelReady = false;
  String _writingMessage = 'اكتب الحرف داخل الصبورة ثم اضغط «تحقق من كتابتي» ✍️';
  int _celebrationIndex = 0;
  bool _showWrongAnswer = false;

  static const List<Map<String, String>> _arabicLetters = [
    {'letter': 'أ', 'word': 'أسد', 'emoji': '🦁'},
    {'letter': 'ب', 'word': 'بطة', 'emoji': '🦆'},
    {'letter': 'ت', 'word': 'تفاحة', 'emoji': '🍎'},
    {'letter': 'ث', 'word': 'ثعلب', 'emoji': '🦊'},
    {'letter': 'ج', 'word': 'جمل', 'emoji': '🐪'},
    {'letter': 'ح', 'word': 'حصان', 'emoji': '🐴'},
    {'letter': 'خ', 'word': 'خروف', 'emoji': '🐑'},
    {'letter': 'د', 'word': 'دب', 'emoji': '🐻'},
    {'letter': 'ذ', 'word': 'ذرة', 'emoji': '🌽'},
    {'letter': 'ر', 'word': 'رمان', 'emoji': '🍎'},
    {'letter': 'ز', 'word': 'زهرة', 'emoji': '🌷'},
    {'letter': 'س', 'word': 'سمكة', 'emoji': '🐟'},
    {'letter': 'ش', 'word': 'شمس', 'emoji': '☀️'},
    {'letter': 'ص', 'word': 'صقر', 'emoji': '🦅'},
    {'letter': 'ض', 'word': 'ضفدع', 'emoji': '🐸'},
    {'letter': 'ط', 'word': 'طائرة', 'emoji': '✈️'},
    {'letter': 'ظ', 'word': 'ظرف', 'emoji': '✉️'},
    {'letter': 'ع', 'word': 'عنب', 'emoji': '🍇'},
    {'letter': 'غ', 'word': 'غزال', 'emoji': '🦌'},
    {'letter': 'ف', 'word': 'فراشة', 'emoji': '🦋'},
    {'letter': 'ق', 'word': 'قمر', 'emoji': '🌙'},
    {'letter': 'ك', 'word': 'كتاب', 'emoji': '📘'},
    {'letter': 'ل', 'word': 'ليمون', 'emoji': '🍋'},
    {'letter': 'م', 'word': 'موز', 'emoji': '🍌'},
    {'letter': 'ن', 'word': 'نحلة', 'emoji': '🐝'},
    {'letter': 'هـ', 'word': 'هلال', 'emoji': '🌙'},
    {'letter': 'و', 'word': 'وردة', 'emoji': '🌹'},
    {'letter': 'ي', 'word': 'يد', 'emoji': '✋'},
  ];

  static const List<Map<String, String>> _englishLetters = [
    {'letter': 'A', 'word': 'Apple', 'emoji': '🍎'},
    {'letter': 'B', 'word': 'Ball', 'emoji': '⚽'},
    {'letter': 'C', 'word': 'Cat', 'emoji': '🐱'},
    {'letter': 'D', 'word': 'Dog', 'emoji': '🐶'},
    {'letter': 'E', 'word': 'Elephant', 'emoji': '🐘'},
    {'letter': 'F', 'word': 'Fish', 'emoji': '🐟'},
    {'letter': 'G', 'word': 'Giraffe', 'emoji': '🦒'},
    {'letter': 'H', 'word': 'House', 'emoji': '🏠'},
    {'letter': 'I', 'word': 'Ice cream', 'emoji': '🍦'},
    {'letter': 'J', 'word': 'Juice', 'emoji': '🧃'},
    {'letter': 'K', 'word': 'Kite', 'emoji': '🪁'},
    {'letter': 'L', 'word': 'Lion', 'emoji': '🦁'},
    {'letter': 'M', 'word': 'Moon', 'emoji': '🌙'},
    {'letter': 'N', 'word': 'Nest', 'emoji': '🪺'},
    {'letter': 'O', 'word': 'Owl', 'emoji': '🦉'},
    {'letter': 'P', 'word': 'Panda', 'emoji': '🐼'},
    {'letter': 'Q', 'word': 'Queen', 'emoji': '👑'},
    {'letter': 'R', 'word': 'Rabbit', 'emoji': '🐰'},
    {'letter': 'S', 'word': 'Sun', 'emoji': '☀️'},
    {'letter': 'T', 'word': 'Tree', 'emoji': '🌳'},
    {'letter': 'U', 'word': 'Umbrella', 'emoji': '☂️'},
    {'letter': 'V', 'word': 'Van', 'emoji': '🚐'},
    {'letter': 'W', 'word': 'Whale', 'emoji': '🐳'},
    {'letter': 'X', 'word': 'Xylophone', 'emoji': '🎼'},
    {'letter': 'Y', 'word': 'Yo-yo', 'emoji': '🪀'},
    {'letter': 'Z', 'word': 'Zebra', 'emoji': '🦓'},
  ];

  static const List<String> _arabicDigits = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
  static const List<String> _westernDigits = ['0','1','2','3','4','5','6','7','8','9'];
  static const List<String> _arabicNumberWords = [
    'صفر','واحد','اثنان','ثلاثة','أربعة','خمسة','ستة','سبعة','ثمانية','تسعة',
    'عشرة','أحد عشر','اثنا عشر','ثلاثة عشر','أربعة عشر','خمسة عشر','ستة عشر','سبعة عشر','ثمانية عشر','تسعة عشر',
    'عشرون','واحد وعشرون','اثنان وعشرون','ثلاثة وعشرون','أربعة وعشرون','خمسة وعشرون','ستة وعشرون','سبعة وعشرون','ثمانية وعشرون','تسعة وعشرون',
    'ثلاثون','واحد وثلاثون','اثنان وثلاثون','ثلاثة وثلاثون','أربعة وثلاثون','خمسة وثلاثون','ستة وثلاثون','سبعة وثلاثون','ثمانية وثلاثون','تسعة وثلاثون',
    'أربعون','واحد وأربعون','اثنان وأربعون','ثلاثة وأربعون','أربعة وأربعون','خمسة وأربعون','ستة وأربعون','سبعة وأربعون','ثمانية وأربعون','تسعة وأربعون',
    'خمسون','واحد وخمسون','اثنان وخمسون','ثلاثة وخمسون','أربعة وخمسون','خمسة وخمسون','ستة وخمسون','سبعة وخمسون','ثمانية وخمسون','تسعة وخمسون',
    'ستون','واحد وستون','اثنان وستون','ثلاثة وستون','أربعة وستون','خمسة وستون','ستة وستون','سبعة وستون','ثمانية وستون','تسعة وستون',
    'سبعون','واحد وسبعون','اثنان وسبعون','ثلاثة وسبعون','أربعة وسبعون','خمسة وسبعون','ستة وسبعون','سبعة وسبعون','ثمانية وسبعون','تسعة وسبعون',
    'ثمانون','واحد وثمانون','اثنان وثمانون','ثلاثة وثمانون','أربعة وثمانون','خمسة وثمانون','ستة وثمانون','سبعة وثمانون','ثمانية وثمانون','تسعة وثمانون',
    'تسعون','واحد وتسعون','اثنان وتسعون','ثلاثة وتسعون','أربعة وتسعون','خمسة وتسعون','ستة وتسعون','سبعة وتسعون','ثمانية وتسعون','تسعة وتسعون','مئة'
  ];
  static const List<String> _englishNumberWords = [
    'zero','one','two','three','four','five','six','seven','eight','nine',
    'ten','eleven','twelve','thirteen','fourteen','fifteen','sixteen','seventeen','eighteen','nineteen',
    'twenty','twenty-one','twenty-two','twenty-three','twenty-four','twenty-five','twenty-six','twenty-seven','twenty-eight','twenty-nine',
    'thirty','thirty-one','thirty-two','thirty-three','thirty-four','thirty-five','thirty-six','thirty-seven','thirty-eight','thirty-nine',
    'forty','forty-one','forty-two','forty-three','forty-four','forty-five','forty-six','forty-seven','forty-eight','forty-nine',
    'fifty','fifty-one','fifty-two','fifty-three','fifty-four','fifty-five','fifty-six','fifty-seven','fifty-eight','fifty-nine',
    'sixty','sixty-one','sixty-two','sixty-three','sixty-four','sixty-five','sixty-six','sixty-seven','sixty-eight','sixty-nine',
    'seventy','seventy-one','seventy-two','seventy-three','seventy-four','seventy-five','seventy-six','seventy-seven','seventy-eight','seventy-nine',
    'eighty','eighty-one','eighty-two','eighty-three','eighty-four','eighty-five','eighty-six','eighty-seven','eighty-eight','eighty-nine',
    'ninety','ninety-one','ninety-two','ninety-three','ninety-four','ninety-five','ninety-six','ninety-seven','ninety-eight','ninety-nine','one hundred'
  ];

  Future<void> _speak(String text, {bool english = false}) async {
    try {
      // Set the language immediately before speaking so English number words
      // are not sent to the Arabic voice.
      final locale = english ? 'en-US' : 'ar-SA';
      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(english ? 0.38 : 0.42);
      await _tts.setPitch(1.0);
      await _tts.speak(text);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الصوت غير متاح على هذا الجهاز حالياً')),
      );
    }
  }


  static const List<String> _arabicWritingTargets = [
    'أ','ب','ت','ث','ج','ح','خ','د','ذ','ر','ز','س','ش','ص','ض','ط','ظ','ع','غ','ف','ق','ك','ل','م','ن','هـ','و','ي',
  ];
  static const List<String> _englishWritingTargets = [
    'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
  ];
  static const List<String> _arabicNumberWritingTargets = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
  static const List<String> _englishNumberWritingTargets = ['0','1','2','3','4','5','6','7','8','9'];

  List<String> _writingTargetsForCategory(String category) {
    switch (category) {
      case 'englishLetters':
        return _englishWritingTargets;
      case 'arabicNumbers':
        return _arabicNumberWritingTargets;
      case 'englishNumbers':
        return _englishNumberWritingTargets;
      default:
        return _arabicWritingTargets;
    }
  }

  bool _categoryIsEnglish(String category) =>
      category == 'englishLetters' || category == 'englishNumbers';

  String _categoryTitle(String category) {
    switch (category) {
      case 'englishLetters':
        return 'الأحرف الإنكليزية';
      case 'arabicNumbers':
        return 'الأرقام العربية';
      case 'englishNumbers':
        return 'الأرقام الإنكليزية';
      default:
        return 'الأحرف العربية';
    }
  }

  Future<Duration?> _playApplause() async {
    try {
      await _applausePlayer.setAsset('assets/sounds/applause.wav');
      await _applausePlayer.seek(Duration.zero);
      final duration = _applausePlayer.duration;

      // مهم: لا ننتظر انتهاء التصفيق هنا، لأن play() يرجع Future
      // يستمر حتى نهاية التشغيل. انتظارُه كان يخلي زر التحقق يبقى
      // على «جاري التحقق» إذا صار تعليق بمشغل الصوت.
      unawaited(() async {
        try {
          await _applausePlayer.play();
        } catch (e) {
          debugPrint('Applause playback error: $e');
        }
      }());

      return duration;
    } catch (e) {
      debugPrint('Applause error: $e');
      return null;
    }
  }

  Future<void> _openWritingBoard(
      String target, {
        required bool english,
      }) async {
    setState(() {
      _section = 'writing';
      _writingTarget = target;
      _writingEnglish = english;
      _writingCategory = english ? 'englishLetters' : 'arabicLetters';
      _drawingStrokes.clear();
      _activeStroke = null;
      _recognizing = false;
      final existingRecognizer = english ? _englishInkRecognizer : _arabicInkRecognizer;
      _inkRecognizer = existingRecognizer;
      _modelReady = existingRecognizer != null;
      _writingMessage =
      'اكتب الحرف داخل الصبورة ثم اضغط «تحقق من كتابتي» ✍️';
    });

    await _prepareInkRecognizer(english ? 'en' : 'ar');
  }

  String? _preparedInkLanguage;
  Future<void>? _inkPreparationFuture;
  String? _inkPreparingLanguage;

  Future<void> _prepareInkRecognizer(String languageCode) {
    // لا نغلق محرك لغة حتى نفتح الآخر. نخلي العربي والإنكليزي جاهزين بشكل مستقل.
    if (languageCode == 'ar') {
      if (_arabicInkRecognizer != null && _arabicModelFuture == null) {
        _preparedInkLanguage = 'ar';
        _inkRecognizer = _arabicInkRecognizer;
        _modelReady = true;
        return Future.value();
      }
      if (_arabicModelFuture != null) return _arabicModelFuture!;

      late Future<void> future;
      future = _prepareLanguageModel('ar').whenComplete(() {
        if (identical(_arabicModelFuture, future)) _arabicModelFuture = null;
      });
      _arabicModelFuture = future;
      return future;
    }

    if (languageCode == 'en') {
      if (_englishInkRecognizer != null && _englishModelFuture == null) {
        _preparedInkLanguage = 'en';
        _inkRecognizer = _englishInkRecognizer;
        _modelReady = true;
        return Future.value();
      }
      if (_englishModelFuture != null) return _englishModelFuture!;

      late Future<void> future;
      future = _prepareLanguageModel('en').whenComplete(() {
        if (identical(_englishModelFuture, future)) _englishModelFuture = null;
      });
      _englishModelFuture = future;
      return future;
    }

    return Future.error('Unsupported ink language: $languageCode');
  }

  Future<void> _prepareLanguageModel(String languageCode) async {
    try {
      // إذا النموذج موجود مسبقاً، لا نعيد تنزيله.
      final downloaded = await _inkModelManager
          .isModelDownloaded(languageCode)
          .timeout(const Duration(seconds: 10));

      if (!downloaded) {
        final ok = await _inkModelManager
            .downloadModel(languageCode, isWifiRequired: false)
            .timeout(const Duration(seconds: 40));
        if (!ok) {
          throw Exception('Failed to download $languageCode model');
        }
      }

      final recognizer = mlkit.DigitalInkRecognizer(languageCode: languageCode);
      if (languageCode == 'ar') {
        _arabicInkRecognizer = recognizer;
      } else {
        _englishInkRecognizer = recognizer;
      }

      if (!mounted) return;
      // فقط إذا اللغة المطلوبة حالياً هي هذه اللغة نربطها بالمحرك النشط.
      final currentLanguage = _writingEnglish ? 'en' : 'ar';
      if (currentLanguage == languageCode) {
        setState(() {
          _inkRecognizer = recognizer;
          _preparedInkLanguage = languageCode;
          _modelReady = true;
        });
      }
    } catch (e) {
      debugPrint('Ink model preparation error [$languageCode]: $e');
      if (!mounted) return;
      final currentLanguage = _writingEnglish ? 'en' : 'ar';
      if (currentLanguage == languageCode) {
        setState(() {
          _modelReady = false;
          _writingMessage =
          languageCode == 'en'
              ? 'تعذر تجهيز نموذج الإنكليزي. تأكد من الإنترنت وحاول مرة ثانية.'
              : 'تعذر تجهيز نموذج العربي. تأكد من الإنترنت وحاول مرة ثانية.';
        });
      }
      rethrow;
    }
  }

  mlkit.DigitalInkRecognizer? _recognizerForCurrentLanguage() {
    final language = _writingEnglish ? 'en' : 'ar';
    final recognizer = language == 'en'
        ? _englishInkRecognizer
        : _arabicInkRecognizer;
    if (recognizer != null) {
      _inkRecognizer = recognizer;
      _preparedInkLanguage = language;
      _modelReady = true;
    }
    return recognizer;
  }

  void _startWritingStroke(Offset point) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final stroke = mlkit.Stroke()
      ..points = [
        mlkit.StrokePoint(x: point.dx, y: point.dy, t: now),
      ];

    setState(() {
      _activeStroke = stroke;
      _drawingStrokes.add(stroke);
    });
  }

  void _updateWritingStroke(Offset point) {
    final stroke = _activeStroke;
    if (stroke == null) return;

    stroke.points.add(
      mlkit.StrokePoint(
        x: point.dx,
        y: point.dy,
        t: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    setState(() {});
  }

  void _endWritingStroke() {
    _activeStroke = null;
  }

  void _clearWritingBoard() {
    setState(() {
      _drawingStrokes.clear();
      _activeStroke = null;
      _writingMessage =
      'اكتب الحرف داخل الصبورة ثم اضغط «تحقق من كتابتي» ✍️';
    });
  }

  String _normalizeRecognized(String value) {
    var text = value.trim().replaceAll(RegExp(r'\s+'), '');
    text = text.replaceAll('إ', 'ا').replaceAll('أ', 'ا').replaceAll('آ', 'ا');
    text = text.replaceAll('ٱ', 'ا');

    // توحيد الأرقام العربية والإنكليزية للمقارنة.
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    const englishDigits = '0123456789';
    for (var i = 0; i < arabicDigits.length; i++) {
      text = text.replaceAll(arabicDigits[i], englishDigits[i]);
    }

    return text.toLowerCase();
  }

  bool _recognizedMatchesTarget(String value) {
    final recognized = _normalizeRecognized(value);
    final target = _normalizeRecognized(_writingTarget);

    if (recognized == target) return true;

    // بعض نماذج الكتابة قد ترجع ه بدل هـ.
    if ((target == 'هـ' || target == 'ه') &&
        (recognized == 'ه' || recognized == 'هـ')) {
      return true;
    }

    return false;
  }

  Future<void> _checkWriting() async {
    if (_drawingStrokes.isEmpty) {
      setState(() {
        _writingMessage = 'اكتب الحرف أولاً يا بطل ✍️';
      });
      return;
    }

    if (_recognizing) return;

    setState(() => _recognizing = true);

    try {
      final language = _writingEnglish ? 'en' : 'ar';
      var recognizer = _recognizerForCurrentLanguage();

      // نجهز اللغة المطلوبة فقط، بدون إغلاق محرك اللغة الثانية.
      if (recognizer == null) {
        await _prepareInkRecognizer(language);
        recognizer = _recognizerForCurrentLanguage();
      }

      if (recognizer == null) {
        throw Exception('Recognizer is not ready for $language');
      }

      final digitalInk = mlkit.Ink()
        ..strokes = List<mlkit.Stroke>.from(_drawingStrokes);

      // أحياناً محرك ML Kit قد يتأخر أو يعلق في التعرف على بعض المحاولات.
      // نضع مهلة حتى لا يبقى الزر عالقاً على «جاري التحقق» للأبد.
      final candidates = await recognizer.recognize(
        digitalInk,
        context: mlkit.DigitalInkRecognitionContext(
          writingArea: mlkit.WritingArea(width: 340, height: 330),
        ),
      ).timeout(const Duration(seconds: 8));

      final matched = candidates.any(
            (candidate) => _recognizedMatchesTarget(candidate.text),
      );

      if (!mounted) return;

      if (matched) {
        _celebrationTimer?.cancel();
        setState(() {
          _showWrongAnswer = false;
          _writingMessage = 'أحسنت يا بطل!';
          _celebrationIndex = (_celebrationIndex + 1) % 3;
        });

        // الاحتفال يبقى بنفس مدة ملف التصفيق.
        final applauseDuration = await _playApplause();
        final celebrationDuration =
            applauseDuration ?? const Duration(seconds: 4);

        _celebrationTimer = Timer(celebrationDuration, () {
          if (!mounted) return;
          setState(() {
            _writingMessage =
            'اكتب الحرف أو الرقم ثم اضغط «تحقق من كتابتي» ✍️';
          });
        });
      } else {
        debugPrint(
          'Digital ink candidates: '
              '${candidates.map((e) => '${e.text}:${e.score}').join(', ')}',
        );

        _celebrationTimer?.cancel();
        setState(() {
          _showWrongAnswer = true;
          _writingMessage = 'إجابة خطأ';
        });

        // إخفاء ملصق الخطأ بعد 3 ثوانٍ.
        _celebrationTimer = Timer(const Duration(seconds: 3), () {
          if (!mounted) return;
          setState(() {
            _showWrongAnswer = false;
            _writingMessage =
            'اكتب الحرف أو الرقم ثم اضغط «تحقق من كتابتي» ✍️';
          });
        });
      }
    } on TimeoutException catch (e) {
      debugPrint('Digital ink recognition timeout: $e');

      // إذا علق المحرك، نغلقه وننشئ نسخة جديدة للمحاولة التالية.
      _inkRecognizer = _recognizerForCurrentLanguage();
      _preparedInkLanguage = _inkRecognizer == null ? null : (_writingEnglish ? 'en' : 'ar');
      _modelReady = _inkRecognizer != null;

      if (!mounted) return;
      setState(() {
        _showWrongAnswer = false;
        _writingMessage =
        'التعرف تأخر شوي، امسح وجرب مرة ثانية ✍️';
      });
    } catch (e) {
      debugPrint('Digital ink recognition error: $e');

      // لا نخلي حالة التحقق تبقى معلقة إذا صار خطأ بالمحرك.
      _inkRecognizer = _recognizerForCurrentLanguage();
      _preparedInkLanguage = _inkRecognizer == null ? null : (_writingEnglish ? 'en' : 'ar');
      _modelReady = _inkRecognizer != null;

      if (!mounted) return;
      setState(() {
        _showWrongAnswer = false;
        _writingMessage =
        'صار خطأ بالتعرف على الكتابة. امسح وجرب مرة ثانية.';
      });
    } finally {
      if (mounted) {
        setState(() => _recognizing = false);
      }
    }
  }

  Widget _buildWritingBoard({Key? key}) {
    final success = _writingMessage == 'أحسنت يا بطل!';

    return Stack(
      key: key,
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      'الصبورة الذكية ✍️',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'اختار نوع الكتابة ثم اختار الحرف أو الرقم',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _writingCategory,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'نوع الكتابة',
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'arabicLetters', child: Text('أحرف عربية')),
                              DropdownMenuItem(value: 'englishLetters', child: Text('أحرف إنكليزية')),
                              DropdownMenuItem(value: 'arabicNumbers', child: Text('أرقام عربية')),
                              DropdownMenuItem(value: 'englishNumbers', child: Text('أرقام إنكليزية')),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              final options = _writingTargetsForCategory(value);
                              setState(() {
                                _writingCategory = value;
                                _writingEnglish = _categoryIsEnglish(value);
                                _writingTarget = options.first;
                                _drawingStrokes.clear();
                                _activeStroke = null;
                                _writingMessage = 'اكتب الحرف أو الرقم داخل الصبورة ثم اضغط «تحقق من كتابتي» ✍️';
                                // لا نعطل النموذج إذا بقيت نفس اللغة (عربي/إنكليزي).
                                final selectedLanguage = _writingEnglish ? 'en' : 'ar';
                                final selectedRecognizer = selectedLanguage == 'en'
                                    ? _englishInkRecognizer
                                    : _arabicInkRecognizer;
                                _inkRecognizer = selectedRecognizer;
                                _preparedInkLanguage = selectedRecognizer == null ? null : selectedLanguage;
                                _modelReady = selectedRecognizer != null;
                              });
                              _prepareInkRecognizer(_writingEnglish ? 'en' : 'ar');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _writingTarget,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'اختار',
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: _writingTargetsForCategory(_writingCategory)
                                .map((item) => DropdownMenuItem<String>(
                              value: item,
                              child: Center(
                                child: Text(
                                  item,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ))
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _writingTarget = value;
                                _drawingStrokes.clear();
                                _activeStroke = null;
                                _writingMessage = 'اكتب الحرف أو الرقم داخل الصبورة ثم اضغط «تحقق من كتابتي» ✍️';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Flexible(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFCBD5E1),
                      width: 2,
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (details) =>
                            _startWritingStroke(details.localPosition),
                        onPanUpdate: (details) =>
                            _updateWritingStroke(details.localPosition),
                        onPanEnd: (_) => _endWritingStroke(),
                        child: CustomPaint(
                          painter: _WritingBoardPainter(
                            strokes: _drawingStrokes,
                          ),
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            if (!success)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 3),
                child: Text(
                  _writingMessage,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 1, 14, 24),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _recognizing ? null : _clearWritingBoard,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        icon: const Icon(Icons.cleaning_services_outlined, size: 21),
                        label: const Text(
                          'مسح النص',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _recognizing ? null : _checkWriting,
                        icon: _recognizing
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.check_circle_outline, size: 21),
                        label: Text(
                          _recognizing ? 'جاري التحقق...' : 'تحقق من كتابتي',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (_showWrongAnswer)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.white.withOpacity(0.94),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.75, end: 1.0),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: -0.08, end: 0.08),
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeInOut,
                              builder: (context, angle, child) {
                                return Transform.rotate(
                                  angle: angle,
                                  child: child,
                                );
                              },
                              child: const Text(
                                '😭',
                                style: TextStyle(fontSize: 92),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'إجابة خطأ',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

        if (success)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.white.withOpacity(0.96),
                child: Stack(
                  children: [
                    ..._flowerRain(),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'أحسنت يا بطل!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF15803D),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _celebrationText(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 34),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _celebrationText() {
    const texts = ['🌹🌷🌸🌺🌼', '🌸🌻🌹🌷💐', '🌺🌷🌼🌸🌹'];
    return texts[_celebrationIndex];
  }

  List<Widget> _flowerRain() {
    const flowers = ['🌹', '🌷', '🌸', '🌺', '🌼', '💐'];
    const positions = <double>[
      0.03, 0.12, 0.21, 0.30, 0.39, 0.48, 0.57, 0.66, 0.75, 0.84, 0.93,
    ];
    return List.generate(22, (i) {
      final left = positions[i % positions.length];
      final top = 0.04 + ((i * 0.137) % 0.88);
      return Positioned(
        left: MediaQuery.of(context).size.width * left,
        top: MediaQuery.of(context).size.height * top,
        child: Text(
          flowers[(i + _celebrationIndex) % flowers.length],
          style: TextStyle(fontSize: 25 + (i % 3) * 7),
        ),
      );
    });
  }

  @override
  void dispose() {
    _inkRecognizer?.close();
    _celebrationTimer?.cancel();
    _applausePlayer.dispose();
    _tts.stop();
    super.dispose();
  }

  void _startQuiz(String kind) {
    setState(() {
      _section = 'quiz';
      _quizKind = kind;
      _score = 0;
      _round = 0;
      _chosen = null;
      _feedback = 'اختار الإجابة الصحيحة ⭐';
    });
    _newQuestion();
  }

  void _newQuestion() {
    final List<String> pool;
    if (_quizKind == 'arabic') {
      pool = _arabicLetters.map((e) => e['letter']!).toList();
    } else if (_quizKind == 'english') {
      pool = _englishLetters.map((e) => e['letter']!).toList();
    } else if (_quizKind == 'numbers') {
      pool = List.generate(101, (i) => i.toString());
    } else {
      pool = [..._arabicLetters.map((e) => e['letter']!), ..._englishLetters.map((e) => e['letter']!)];
    }
    final correct = pool[_random.nextInt(pool.length)];
    final choices = <String>{correct};
    while (choices.length < 4 && choices.length < pool.length) {
      choices.add(pool[_random.nextInt(pool.length)]);
    }
    final shuffled = choices.toList()..shuffle(_random);
    setState(() {
      _question = correct;
      _choices = shuffled;
      _chosen = null;
      _feedback = 'اختار الإجابة الصحيحة ⭐';
    });
  }

  void _answerQuestion(String value) {
    if (_chosen != null) return;
    final correct = value == _question;
    setState(() {
      _chosen = value;
      if (correct) {
        _score++;
        _feedback = 'أحسنت! إجابة صحيحة 🎉';
      } else {
        _feedback = 'مو مشكلة، الصحيح هو $_question 💪';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          title: const Text('تعلّم الأحرف والأرقام', style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_section == 'home') {
                Navigator.maybePop(context);
              } else {
                setState(() => _section = 'home');
              }
            },
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _buildSection(),
        ),
      ),
    );
  }

  Widget _buildCelebration() {
    final effects = [
      '🌹🌹🌹  ورد جميل  🌹🌹🌹',
      '🍎🍓🍊  فواكه حلوة  🍇🍉🍌',
      '🦋🎈✨  مفاجأة حلوة  ✨🎈🦋',
    ];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(_celebrationIndex),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Text(
          effects[_celebrationIndex],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }

  Widget _buildSection() {
    switch (_section) {
      case 'arabic':
        return _buildLetters(_arabicLetters, english: false, key: const ValueKey('arabic'));
      case 'english':
        return _buildLetters(_englishLetters, english: true, key: const ValueKey('english'));
      case 'numbers':
        return _buildNumbers(key: const ValueKey('numbers'));
      case 'quiz':
        return _buildQuiz(key: const ValueKey('quiz'));
      case 'writing':
        return _buildWritingBoard(key: const ValueKey('writing'));
      default:
        return _buildHome(key: const ValueKey('home'));
    }
  }

  Widget _buildHome({Key? key}) => ListView(
    key: key,
    padding: const EdgeInsets.all(18),
    children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(26)),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('يلا نتعلّم ونلعب! 🎈', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('اختار درس، اسمع النطق، وبعدها جرّب معلوماتك باللعبة.', style: TextStyle(color: Colors.white, height: 1.5, fontSize: 15)),
        ]),
      ),
      const SizedBox(height: 18),
      _homeTile(title: 'الحروف العربية', subtitle: 'أ، ب، ت ...', emoji: 'أ ب ت', color: const Color(0xFFDFF3FF), onTap: () => setState(() => _section = 'arabic')),
      _homeTile(title: 'English Letters', subtitle: 'A, B, C ...', emoji: 'A B C', color: const Color(0xFFFFE7EF), onTap: () => setState(() => _section = 'english')),
      _homeTile(title: 'الأرقام والعدّ', subtitle: 'نتعلّم الأرقام من ٠ إلى ١٠٠ بالعربي والإنكليزي', emoji: '١ 2 ٣', color: const Color(0xFFFFEACD), onTap: () => setState(() => _section = 'numbers')),
      _homeTile(title: 'الصبورة الناطقة ✍️', subtitle: 'اختار أحرف أو أرقام، واكتبها بإيدك على الصبورة الذكية', emoji: '✍️', color: const Color(0xFFEDE9FE), onTap: () => _openWritingBoard('أ', english: false)),
      _homeTile(title: 'اختبر نفسك', subtitle: 'أسئلة قصيرة ونجوم تشجيعية', emoji: '⭐ ?', color: const Color(0xFFE7E3FF), onTap: () => _startQuiz('letters')),
    ],
  );

  Widget _homeTile({required String title, required String subtitle, required String emoji, required Color color, required VoidCallback onTap}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(width: 76, height: 76, alignment: Alignment.center, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)), child: Text(emoji, textAlign: TextAlign.center, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: navy))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navy)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.black54))])),
                const Icon(Icons.arrow_forward_ios_rounded, color: gold, size: 19),
              ]),
            ),
          ),
        ),
      );

  Widget _buildLetters(List<Map<String, String>> data, {required bool english, Key? key}) => GridView.builder(
    key: key,
    padding: const EdgeInsets.all(14),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.05, crossAxisSpacing: 12, mainAxisSpacing: 12),
    itemCount: data.length,
    itemBuilder: (context, index) {
      final item = data[index];
      final colors = [const Color(0xFFDFF3FF), const Color(0xFFFFE7EF), const Color(0xFFFFEACD), const Color(0xFFE7E3FF)];
      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _speak('${item['letter']}. ${item['word']}', english: english),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(item['emoji']!, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 3),
              Text(item['letter']!, style: TextStyle(fontSize: english ? 37 : 42, color: navy, fontWeight: FontWeight.w900)),
              Text(item['word']!, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: IconButton(
                      tooltip: 'نطق',
                      onPressed: () => _speak(
                        '${item['letter']}. ${item['word']}',
                        english: english,
                      ),
                      icon: const Icon(
                        Icons.volume_up_rounded,
                        color: gold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      tooltip: 'اكتب الحرف',
                      onPressed: () => _openWritingBoard(
                        item['letter']!,
                        english: english,
                      ),
                      icon: const Icon(
                        Icons.edit_rounded,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ),
      );
    },
  );

  String _toArabicDigits(int number) {
    return number.toString().split('').map((digit) {
      final index = int.parse(digit);
      return _arabicDigits[index];
    }).join();
  }

  static const List<String> _unitAr = [
    'صفر', 'واحد', 'اثنان', 'ثلاثة', 'أربعة', 'خمسة', 'ستة', 'سبعة', 'ثمانية', 'تسعة',
  ];
  static const List<String> _unitEn = [
    'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine',
  ];
  static const List<String> _placeAr = [
    'آحاد', 'عشرات', 'مئات', 'آلاف', 'عشرات الآلاف', 'مئات الآلاف',
  ];
  static const List<String> _placeEn = [
    'ones', 'tens', 'hundreds', 'thousands', 'ten thousands', 'hundred thousands',
  ];
  static const List<String> _placeWordsAr = [
    'صفر', 'عشرة', 'مئة', 'ألف', 'عشرة آلاف', 'مئة ألف',
  ];
  static const List<String> _placeWordsEn = [
    'zero', 'ten', 'one hundred', 'one thousand', 'ten thousand', 'one hundred thousand',
  ];

  int _placeValue(int group, int digit) {
    if (group == 0) return digit;
    int multiplier = 1;
    for (int i = 0; i < group; i++) {
      multiplier *= 10;
    }
    return digit * multiplier;
  }

  String _placeNumberAr(int group, int digit) {
    if (group == 0) return _unitAr[digit];
    if (digit == 0) return 'صفر';
    const tensAr = ['', 'عشرة', 'عشرون', 'ثلاثون', 'أربعون', 'خمسون', 'ستون', 'سبعون', 'ثمانون', 'تسعون'];
    if (group == 1) return tensAr[digit];
    if (group == 2) {
      const hundreds = ['', 'مئة', 'مئتان', 'ثلاثمئة', 'أربعمئة', 'خمسمئة', 'ستمئة', 'سبعمئة', 'ثمانمئة', 'تسعمئة'];
      return hundreds[digit];
    }
    if (group == 3) {
      const thousands = ['', 'ألف', 'ألفان', 'ثلاثة آلاف', 'أربعة آلاف', 'خمسة آلاف', 'ستة آلاف', 'سبعة آلاف', 'ثمانية آلاف', 'تسعة آلاف'];
      return thousands[digit];
    }
    if (group == 4) return '${tensAr[digit]} ألف';
    if (digit == 1) return 'مئة ألف';
    if (digit == 2) return 'مئتا ألف';
    return '${_unitAr[digit]} مئة ألف';
  }

  String _placeNumberEn(int group, int digit) {
    if (group == 0) return _unitEn[digit];
    if (digit == 0) return 'zero';
    const tensEn = ['', 'ten', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'];
    if (group == 1) return tensEn[digit];
    if (group == 2) return '${_unitEn[digit]} hundred';
    if (group == 3) return '${_unitEn[digit]} thousand';
    if (group == 4) return '${tensEn[digit]} thousand';
    return '${_unitEn[digit]} hundred thousand';
  }

  List<int> _numbersForSelectedGroup() {
    if (_numberGroup == 'all') return List<int>.generate(101, (i) => i);
    final group = int.tryParse(_numberGroup) ?? 0;
    return List<int>.generate(10, (i) => _placeValue(group, i));
  }

  Widget _buildNumbers({Key? key}) {
    final values = _numbersForSelectedGroup();
    return Column(key: key, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFFEACD), borderRadius: BorderRadius.circular(16)),
          child: const Text(
            'اختار نوع الأرقام من الأزرار، واضغط «عربي» أو «English» حتى تسمع النطق باللغة الصحيحة 🔊',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600, height: 1.4),
          ),
        ),
      ),
      SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          children: [
            _numberGroupButton('all', '٠–١٠٠'),
            for (int i = 0; i < _placeAr.length; i++) _numberGroupButton('$i', _placeAr[i]),
          ],
        ),
      ),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.92,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: values.length,
          itemBuilder: (context, index) {
            final number = values[index];
            final digit = _numberGroup == 'all' ? number : index;
            final group = _numberGroup == 'all' ? -1 : int.parse(_numberGroup);
            final arabicWord = group == -1 ? _arabicNumberWords[number] : _placeNumberAr(group, digit);
            final englishWord = group == -1 ? _englishNumberWords[number] : _placeNumberEn(group, digit);
            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${_toArabicDigits(number)}   $number', textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 27, color: navy, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(arabicWord, textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(englishWord, textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF0F766E), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 5),
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(
                        onPressed: () => _speak(arabicWord),
                        icon: const Icon(Icons.volume_up_rounded, size: 15),
                        label: const Text('عربي', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 3), minimumSize: const Size(0, 32)),
                      )),
                      const SizedBox(width: 4),
                      Expanded(child: FilledButton.icon(
                        onPressed: () => _speak(englishWord, english: true),
                        icon: const Icon(Icons.volume_up_rounded, size: 15),
                        label: const Text('English', style: TextStyle(fontSize: 10)),
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F766E), padding: const EdgeInsets.symmetric(horizontal: 3), minimumSize: const Size(0, 32)),
                      )),
                    ]),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(10),
        child: SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: () => _startQuiz('numbers'),
          icon: const Icon(Icons.quiz_outlined),
          label: const Text('اختبر الأرقام'),
        )),
      ),
    ]);
  }

  Widget _numberGroupButton(String value, String label) {
    final selected = _numberGroup == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _numberGroup = value),
        selectedColor: const Color(0xFF26364A),
        labelStyle: TextStyle(color: selected ? Colors.white : navy, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildQuiz({Key? key}) => ListView(
    key: key,
    padding: const EdgeInsets.all(18),
    children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(22)),
        child: Column(children: [
          const Text('اختبار سريع 🎯', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('النقاط: $_score ⭐', style: const TextStyle(color: Color(0xFFFFD778), fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
      ),
      const SizedBox(height: 22),
      const Text('اختار الرمز المطابق للسؤال:', textAlign: TextAlign.center, style: TextStyle(fontSize: 17)),
      const SizedBox(height: 12),
      Center(child: Text(_question, style: const TextStyle(fontSize: 68, color: navy, fontWeight: FontWeight.w900))),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.7,
        children: _choices.map((choice) {
          final isCorrect = _chosen != null && choice == _question;
          final isWrong = _chosen == choice && choice != _question;
          return FilledButton(
            onPressed: _chosen == null ? () => _answerQuestion(choice) : null,
            style: FilledButton.styleFrom(backgroundColor: isCorrect ? Colors.green : isWrong ? Colors.red : Colors.white, foregroundColor: isCorrect || isWrong ? Colors.white : navy, disabledBackgroundColor: isCorrect ? Colors.green : isWrong ? Colors.red : Colors.white, disabledForegroundColor: isCorrect || isWrong ? Colors.white : navy),
            child: Text(choice, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          );
        }).toList(),
      ),
      const SizedBox(height: 18),
      Text(_feedback, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const SizedBox(height: 14),
      FilledButton.icon(onPressed: _chosen == null ? null : _newQuestion, icon: const Icon(Icons.navigate_next), label: const Text('السؤال التالي')),
      TextButton(onPressed: () => setState(() => _section = 'home'), child: const Text('العودة للقائمة')),
    ],
  );
}


class _WritingBoardPainter extends CustomPainter {
  final List<mlkit.Stroke> strokes;
  const _WritingBoardPainter({
    required this.strokes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // خطوط خفيفة تساعد الطفل على الكتابة داخل الصبورة.
    final guideLinePaint = Paint()
      ..color = const Color(0xFFE8EDF3)
      ..strokeWidth = 1;

    final third = size.height / 3;
    canvas.drawLine(
      Offset(18, third),
      Offset(size.width - 18, third),
      guideLinePaint,
    );
    canvas.drawLine(
      Offset(18, third * 2),
      Offset(size.width - 18, third * 2),
      guideLinePaint,
    );

    // كتابة الطفل.
    final inkPaint = Paint()
      ..color = const Color(0xFF26364A)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      final points = stroke.points;
      if (points.isEmpty) continue;

      if (points.length == 1) {
        final p = points.first;
        canvas.drawCircle(Offset(p.x, p.y), 3, inkPaint);
        continue;
      }

      final path = Path()
        ..moveTo(points.first.x, points.first.y);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].x, points[i].y);
      }

      canvas.drawPath(path, inkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WritingBoardPainter oldDelegate) {
    return oldDelegate.strokes != strokes;
  }
}