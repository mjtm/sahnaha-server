
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'audio_lessons_page.dart';
import 'package:alarm/alarm.dart';
import 'question_bank/questions.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/services.dart';
import 'notifications_page.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'study_alarm_page.dart';
import 'calculator_page.dart';
import 'learning_letters_numbers_page.dart';

import 'subjects_data.dart';
import 'books_data.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
bool pendingAlarmQuestion = false;
bool alarmQuestionOpened = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Alarm.init();

  const alarmChannel = MethodChannel('com.example.flutter_molh/alarm');

  alarmChannel.setMethodCallHandler((call) async {
    if (call.method == 'alarm_ring') {
      pendingAlarmQuestion = true;
      _tryOpenAlarmQuestion();
    }
  });

  runApp(const IraqiStudentApp());

  // إذا التطبيق انفتح من ضغط إشعار المنبّه وهو مغلق.
  try {
    final openedFromAlarm =
        await alarmChannel.invokeMethod<bool>('consumeAlarmRing') ?? false;
    if (openedFromAlarm) {
      pendingAlarmQuestion = true;
      _tryOpenAlarmQuestion();
    }
  } catch (_) {}
}

Future<void> _tryOpenAlarmQuestion() async {
  if (!pendingAlarmQuestion || alarmQuestionOpened) return;

  final prefs = await SharedPreferences.getInstance();
  final a = prefs.getInt('study_alarm_a') ?? 5;
  final b = prefs.getInt('study_alarm_b') ?? 5;
  final answer = prefs.getInt('study_alarm_answer') ?? (a + b);
  final operator = prefs.getString('study_alarm_operator') ?? '+';
  final subject = prefs.getString('study_alarm_subject') ?? 'الرياضيات';
  final studentName = prefs.getString('study_alarm_name') ?? '';
  final note = prefs.getString('study_alarm_note') ?? '';

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      Future.delayed(const Duration(milliseconds: 300), _tryOpenAlarmQuestion);
      return;
    }

    // ننتظر إلى أن تظهر الصفحة الرئيسية فعليًا، ثم نفتح السؤال فوقها.
    alarmQuestionOpened = true;
    pendingAlarmQuestion = false;

    navigator.push(
      MaterialPageRoute(
        builder: (_) => AlarmQuestionPage(
          alarmId: 751001,
          subject: subject,
          studentName: studentName.isEmpty ? 'الطالب' : studentName,
          note: note,
          initialA: a,
          initialB: b,
          initialOperator: operator,
          initialAnswer: answer,
        ),
      ),
    ).then((_) {
      alarmQuestionOpened = false;
    });
  });
}

class IraqiStudentApp extends StatelessWidget {
  const IraqiStudentApp({super.key});

  @override
  Widget build(BuildContext context) {

    return ValueListenableBuilder<double>(
      valueListenable: uiScaleNotifier,
      builder: (context, scale, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'مساعد الطالب العراقي',
          navigatorKey: appNavigatorKey,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF26364A),
            ),
            fontFamily: 'Arial',
          ),
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(scale),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const AppStart(),
        );
      },
    );
  }
}

// ============================================================
// بداية التطبيق
// ============================================================

class AppStart extends StatefulWidget {
  const AppStart({super.key});

  @override
  State<AppStart> createState() => _AppStartState();
}

class _AppStartState extends State<AppStart> {
  bool loading = true;
  bool loggedIn = false;

  static const String currentAppVersion = '1.0.0+3';

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final savedScale = prefs.getDouble('ui_scale') ?? 1.0;

    uiScaleNotifier.value = savedScale;

    if (!mounted) return;

    setState(() {
      loggedIn = token != null && token.isNotEmpty;
      loading = false;
    });

    // إذا فتح التطبيق من إشعار المنبّه، افتح سؤال المنبّه بعد ظهور الصفحة الرئيسية.
    if (loggedIn && pendingAlarmQuestion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryOpenAlarmQuestion();
      });
    }

    // فحص وجود تحديث بعد تشغيل التطبيق
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      final response = await http
          .get(
        Uri.parse(
          'https://sahnaha-server.vercel.app/api/update',
        ),
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return;

      final data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      final latestVersion =
          data['latestVersion']?.toString() ?? '';

      final downloadUrl =
          data['downloadUrl']?.toString() ?? '';

      if (!mounted ||
          latestVersion.isEmpty ||
          downloadUrl.isEmpty ||
          latestVersion == currentAppVersion) {
        return;
      }

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Text(
              data['title']?.toString() ??
                  'تحديث جديد متوفر',
            ),
            content: Text(
              data['message']?.toString() ??
                  'أكو تحديث جديد للتطبيق.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('لاحقًا'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final uri = Uri.parse(downloadUrl);

                  await launchUrl(
                    uri,
                    mode: LaunchMode.platformDefault,
                  );
                },
                child: const Text('تحديث الآن'),
              ),
            ],
          );
        },
      );
    } catch (_) {
      // إذا ماكو إنترنت، التطبيق يشتغل طبيعي.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return loggedIn
        ? const HomePage()
        : const LoginPage();
  }
}
// عنوان السيرفر للحسابات.
// نفس دومين Vercel المستخدم للمساعد الذكي.
const String authBaseUrl = 'https://sahnaha-server.vercel.app/api';

// حجم واجهة التطبيق (محفوظ محلياً ويُطبّق على كل صفحات التطبيق).
final ValueNotifier<double> uiScaleNotifier = ValueNotifier<double>(1.0);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool obscure = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _show('اكتب الإيميل والرمز أولاً');
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse('$authBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('auth_token', data['token'].toString());
        await prefs.setString('student_name', data['user']['fullName'].toString());
        await prefs.setString('student_email', data['user']['email'].toString());
        await prefs.setString('student_stage', data['user']['stage'].toString());
        await prefs.setString('student_grade', data['user']['grade'].toString());

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        _show(data['error']?.toString() ?? 'بيانات الدخول غير صحيحة');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      _show('خطأ الدخول: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _show(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 48,
                      backgroundColor: Color(0xFFEFF6FF),
                      child: Icon(
                        Icons.school_rounded,
                        size: 52,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'طالبنا',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'سجل دخولك وابدأ رحلتك الدراسية 📚',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'الإيميل',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: passwordController,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: 'الرمز / كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => obscure = !obscure),
                          icon: Icon(
                            obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: loading
                            ? null
                            : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordPage(),
                            ),
                          );
                        },
                        child: const Text('نسيت الرمز؟'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: loading ? null : _login,
                        child: loading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: loading
                            ? null
                            : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          );
                        },
                        child: const Text('إنشاء حساب جديد'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  String? stage;
  String? grade;
  bool loading = false;
  bool obscure = true;

  final primaryGrades = const [
    'الأول الابتدائي',
    'الثاني الابتدائي',
    'الثالث الابتدائي',
    'الرابع الابتدائي',
    'الخامس الابتدائي',
    'السادس الابتدائي',
  ];

  final middleGrades = const [
    'الأول المتوسط',
    'الثاني المتوسط',
    'الثالث المتوسط',
  ];

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  List<String> get grades {
    if (stage == 'primary') return primaryGrades;
    if (stage == 'middle') return middleGrades;
    return const [];
  }

  void _show(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _register() async {
    final fullName = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (fullName.split(RegExp(r'\s+')).length < 3) {
      _show('اكتب الاسم الثلاثي');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _show('اكتب إيميل صحيح');
      return;
    }
    if (password.length < 6) {
      _show('الرمز لازم يكون 6 أحرف أو أرقام على الأقل');
      return;
    }
    if (password != confirmController.text) {
      _show('الرمزان غير متطابقين');
      return;
    }
    if (stage == null || grade == null) {
      _show('اختار المرحلة والصف');
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse('$authBaseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'stage': stage,
          'grade': grade,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 201 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('auth_token', data['token'].toString());
        await prefs.setString('student_name', data['user']['fullName'].toString());
        await prefs.setString('student_email', data['user']['email'].toString());
        await prefs.setString('student_stage', data['user']['stage'].toString());
        await prefs.setString('student_grade', data['user']['grade'].toString());

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
              (_) => false,
        );
      } else {
        _show(data['error']?.toString() ?? 'تعذر إنشاء الحساب');
      }
    } catch (e) {
      debugPrint('Register error: $e');
      _show('خطأ التسجيل: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إنشاء حساب')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                children: [
                  const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 65,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'حساب الطالب',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'الاسم الثلاثي',
                      hintText: 'مثلاً: علي نجم محمد',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'الإيميل',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'الرمز / كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: confirmController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'تأكيد الرمز',
                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: stage,
                    decoration: InputDecoration(
                      labelText: 'المرحلة الدراسية',
                      prefixIcon: const Icon(Icons.school_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'primary',
                        child: Text('المرحلة الابتدائية'),
                      ),
                      DropdownMenuItem(
                        value: 'middle',
                        child: Text('المرحلة المتوسطة'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        stage = value;
                        grade = null;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: grade,
                    decoration: InputDecoration(
                      labelText: 'الصف',
                      prefixIcon: const Icon(Icons.menu_book_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    items: grades
                        .map(
                          (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      ),
                    )
                        .toList(),
                    onChanged: grades.isEmpty
                        ? null
                        : (value) => setState(() => grade = value),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: loading ? null : _register,
                      child: loading
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        'إنشاء الحساب',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final newPasswordController = TextEditingController();

  bool sent = false;
  bool loading = false;
  bool obscure = true;

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }

  void _show(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _sendCode() async {
    final email = emailController.text.trim();

    if (!email.contains('@')) {
      _show('اكتب الإيميل المسجل بالحساب');
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse('$authBaseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() => sent = true);
        _show('تم إرسال رمز إعادة التعيين إلى الإيميل');
      } else {
        _show(data['error']?.toString() ?? 'تعذر إرسال الرمز');
      }
    } catch (_) {
      _show('تعذر الاتصال بالسيرفر');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();
    final code = codeController.text.trim();
    final password = newPasswordController.text;

    if (code.isEmpty || password.length < 6) {
      _show('أدخل رمز التحقق وكلمة مرور جديدة لا تقل عن 6 أحرف');
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse('$authBaseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'newPassword': password,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        _show('تم تغيير الرمز بنجاح');
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        _show(data['error']?.toString() ?? 'رمز التحقق غير صحيح أو منتهي');
      }
    } catch (_) {
      _show('تعذر الاتصال بالسيرفر');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('استعادة الرمز')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  const Icon(
                    Icons.mark_email_read_outlined,
                    size: 70,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'نسيت الرمز؟',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'أدخل إيميل حسابك حتى نرسل لك رمز إعادة التعيين.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 25),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !sent,
                    decoration: InputDecoration(
                      labelText: 'الإيميل',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  if (sent) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: codeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'رمز التحقق',
                        prefixIcon: const Icon(Icons.pin_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: 'الرمز الجديد',
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => obscure = !obscure),
                          icon: Icon(
                            obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: loading
                          ? null
                          : (sent ? _resetPassword : _sendCode),
                      child: loading
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(
                        sent
                            ? 'تغيير الرمز'
                            : 'إرسال رمز إلى الإيميل',
                      ),
                    ),
                  ),
                  if (sent)
                    TextButton(
                      onPressed: loading
                          ? null
                          : () {
                        setState(() {
                          sent = false;
                          codeController.clear();
                          newPasswordController.clear();
                        });
                      },
                      child: const Text('إرسال رمز جديد'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// إنشاء ملف الطالب
// ============================================================

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() =>
      _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final nameController = TextEditingController();

  String? stage;
  String? grade;

  bool saving = false;

  final primaryGrades = [
    'الأول الابتدائي',
    'الثاني الابتدائي',
    'الثالث الابتدائي',
    'الرابع الابتدائي',
    'الخامس الابتدائي',
    'السادس الابتدائي',
  ];

  final middleGrades = [
    'الأول المتوسط',
    'الثاني المتوسط',
    'الثالث المتوسط',
  ];

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> saveStudent() async {
    final name = nameController.text.trim();

    if (name.isEmpty || stage == null || grade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إكمال معلومات الطالب'),
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('student_name', name);
    await prefs.setString('student_stage', stage!);
    await prefs.setString('student_grade', grade!);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grades = stage == 'primary'
        ? primaryGrades
        : stage == 'middle'
        ? middleGrades
        : <String>[];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final large = constraints.maxWidth >= 700;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: large ? 80 : 22,
                    vertical: 30,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 650,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Color(0xFF2563EB),
                            size: 50,
                          ),
                        ),

                        const SizedBox(height: 22),

                        const Text(
                          'مساعد الطالب العراقي',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'خلينا نجهز ملفك الدراسي 📚',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 30),

                        TextField(
                          controller: nameController,
                          textDirection: TextDirection.rtl,
                          decoration: InputDecoration(
                            labelText: 'اسم الطالب',
                            hintText: 'مثلاً: علي محمد',
                            prefixIcon: const Icon(
                              Icons.person_outline,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        DropdownButtonFormField<String>(
                          value: stage,
                          decoration: InputDecoration(
                            labelText: 'المرحلة الدراسية',
                            prefixIcon: const Icon(
                              Icons.school_outlined,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(16),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'primary',
                              child: Text('المرحلة الابتدائية'),
                            ),
                            DropdownMenuItem(
                              value: 'middle',
                              child: Text('المرحلة المتوسطة'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              stage = value;
                              grade = null;
                            });
                          },
                        ),

                        const SizedBox(height: 18),

                        DropdownButtonFormField<String>(
                          value: grade,
                          decoration: InputDecoration(
                            labelText: 'الصف',
                            prefixIcon: const Icon(
                              Icons.menu_book_outlined,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(16),
                            ),
                          ),
                          items: grades
                              .map(
                                (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                              .toList(),
                          onChanged: grades.isEmpty
                              ? null
                              : (value) {
                            setState(() {
                              grade = value;
                            });
                          },
                        ),

                        const SizedBox(height: 28),

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            onPressed:
                            saving ? null : saveStudent,
                            child: saving
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                              CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              'ابدأ الآن',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================
// الصفحة الرئيسية
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final pages = const [
    HomeContent(),
    SubjectsPage(),
    HomeworkPage(),
    MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: pages[selectedIndex],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'المواد',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'الواجبات',
            ),
            NavigationDestination(
              icon: Icon(Icons.apps_outlined),
              selectedIcon: Icon(Icons.apps),
              label: 'المزيد',
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// الرئيسية
// ============================================================

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String studentName = '';
  String studentGrade = '';

  @override
  void initState() {
    super.initState();
    loadStudent();
  }

  Future<void> loadStudent() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      studentName =
          prefs.getString('student_name') ?? '';
      studentGrade =
          prefs.getString('student_grade') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final large = constraints.maxWidth >= 700;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: large ? 40 : 18,
            vertical: 18,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1200,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 25,
                        backgroundColor:
                        Color(0xFFEFF6FF),
                        child: Icon(
                          Icons.person,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'أهلاً $studentName 👋',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              studentGrade,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsPage(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.notifications_none,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF2563EB),
                          Color(0xFF1D4ED8),
                        ],
                      ),
                      borderRadius:
                      BorderRadius.circular(25),
                    ),
                    child: const Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'جاهز للدراسة؟ 📚',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'نظم دراستك، تابع واجباتك\nوطور مستواك خطوة بخطوة.',
                          style: TextStyle(
                            color: Colors.white70,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'أدوات الطالب',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  GridView.count(
                    crossAxisCount: large ? 3 : 2,
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio:
                    large ? 2.1 : 1.15,
                    children: [
                      _HomeTool(
                        icon: Icons.menu_book,
                        title: 'المواد الدراسية',
                        color: const Color(0xFF2563EB),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const SubjectsPage(),
                            ),
                          );
                        },
                      ),

                      _HomeTool(
                        icon: Icons.record_voice_over_rounded,
                        title: 'قراءة الدروس بالصوت',
                        color: const Color(0xFF0F766E),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AudioLessonsPage(),
                            ),
                          );
                        },
                      ),

                      _HomeTool(
                        icon: Icons.assignment,
                        title: 'واجباتي',
                        color: const Color(0xFF0891B2),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const HomeworkPage(),
                            ),
                          );
                        },
                      ),
                      _HomeTool(
                        icon: Icons.psychology,
                        title: 'اختبر نفسك',
                        color: const Color(0xFF7C3AED),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const QuizPage(),
                            ),
                          );
                        },
                      ),
                      _HomeTool(
                        icon: Icons.smart_toy,
                        title: 'المساعد الذكي',
                        color: const Color(0xFFEA580C),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const AssistantPage(),
                            ),
                          );
                        },
                      ),
                      _HomeTool(
                        icon: Icons.calendar_month,
                        title: 'جدولي الدراسي',
                        color: const Color(0xFF059669),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SchedulePage(),
                            ),
                          );
                        },
                      ),
                      _HomeTool(
                        icon: Icons.alarm_rounded,
                        title: 'المنبّه الدراسي',
                        color: const Color(0xFF26364A),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StudyAlarmPage(),
                            ),
                          );
                        },
                      ),
                      _HomeTool(
                        icon: Icons.abc_rounded,
                        title: 'تعلّم الأحرف والأرقام',
                        color: const Color(0xFF9333EA),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LearningLettersNumbersPage(),
                            ),
                          );
                        },
                      ),
                      _HomeTool(
                        icon: Icons.calculate_rounded,
                        title: 'الحاسبة',
                        color: const Color(0xFFB08D57),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CalculatorPage(),
                            ),
                          );
                        },
                      ),
                      _HomeTool(
                        icon: Icons.bar_chart,
                        title: 'درجاتي',
                        color: const Color(0xFFDB2777),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GradesPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


// ============================================================
// الجدول الدراسي
// ============================================================

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  static const String _storageKey = 'student_schedule';

  final List<String> days = const [
    'السبت',
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
  ];

  final List<String> periods = const [
    'الأولى',
    'الثانية',
    'الثالثة',
    'الرابعة',
    'الخامسة',
    'السادسة',
  ];

  List<String> subjects = [];
  Map<String, String> schedule = {};
  bool loading = true;
  int selectedDay = 0;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final prefs = await SharedPreferences.getInstance();

    final grade = prefs.getString('student_grade') ?? '';
    final saved = prefs.getString(_storageKey);

    final loaded = <String, String>{};

    if (saved != null && saved.isNotEmpty) {
      try {
        final decoded = jsonDecode(saved);

        if (decoded is Map) {
          decoded.forEach((key, value) {
            if (key is String && value is String) {
              loaded[key] = value;
            }
          });
        }
      } catch (_) {}
    }

    if (!mounted) return;

    setState(() {
      subjects = List<String>.from(
        subjectsByGrade[grade] ?? const <String>[],
      );
      schedule = loaded;
      loading = false;
    });
  }

  Future<void> _saveSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(schedule));
  }

  String _key(int day, int period) => '$day-$period';

  Future<void> _editPeriod(int period) async {
    final current = schedule[_key(selectedDay, period)] ?? '';

    final result = await showDialog<String>(
      context: context,
      builder: (_) => _ScheduleDialog(
        periodName: periods[period],
        subjects: subjects,
        currentSubject: current,
      ),
    );

    if (result == null) return;

    setState(() {
      if (result.isEmpty) {
        schedule.remove(_key(selectedDay, period));
      } else {
        schedule[_key(selectedDay, period)] = result;
      }
    });

    await _saveSchedule();
  }

  void _clearDay() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('مسح جدول اليوم'),
        content: Text(
          'هل تريد مسح جميع حصص يوم ${days[selectedDay]}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              for (int i = 0; i < periods.length; i++) {
                schedule.remove(_key(selectedDay, i));
              }

              await _saveSchedule();

              if (!mounted) return;
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('مسح'),
          ),
        ],
      ),
    );
  }

  Widget _daySelector() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = selectedDay == index;

          return ChoiceChip(
            label: Text(days[index]),
            selected: selected,
            onSelected: (_) {
              setState(() {
                selectedDay = index;
              });
            },
          );
        },
      ),
    );
  }

  Widget _periodCard(int index) {
    final subject = schedule[_key(selectedDay, index)] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _editPeriod(index),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الحصة ${periods[index]}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subject.isEmpty ? 'اضغط لإضافة المادة' : subject,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: subject.isEmpty
                            ? Colors.grey
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                subject.isEmpty
                    ? Icons.add_circle_outline
                    : Icons.edit_outlined,
                color: const Color(0xFF059669),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'جدولي الدراسي',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              tooltip: 'مسح جدول اليوم',
              onPressed: _clearDay,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 10),
            _daySelector(),
            const SizedBox(height: 14),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFF059669),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'جدول يوم ${days[selectedDay]}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${schedule.entries.where((e) => e.key.startsWith('$selectedDay-')).length}/${periods.length}',
                    style: const TextStyle(
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 25),
                itemCount: periods.length,
                itemBuilder: (_, index) => _periodCard(index),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _editPeriod(0),
          icon: const Icon(Icons.add),
          label: const Text('إضافة حصة'),
        ),
      ),
    );
  }
}

class _ScheduleDialog extends StatefulWidget {
  final String periodName;
  final List<String> subjects;
  final String currentSubject;

  const _ScheduleDialog({
    required this.periodName,
    required this.subjects,
    required this.currentSubject,
  });

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  String? selectedSubject;

  @override
  void initState() {
    super.initState();
    selectedSubject = widget.currentSubject.isEmpty
        ? null
        : widget.currentSubject;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(
          'الحصة ${widget.periodName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: widget.subjects.isEmpty
            ? const Text(
          'لم يتم تحديد صف الطالب بعد، لذلك لا توجد مواد للاختيار.',
        )
            : DropdownButtonFormField<String>(
          value: selectedSubject,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'اختيار المادة',
            prefixIcon: const Icon(Icons.menu_book_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          items: widget.subjects
              .map(
                (subject) => DropdownMenuItem<String>(
              value: subject,
              child: Text(subject),
            ),
          )
              .toList(),
          onChanged: (value) {
            setState(() {
              selectedSubject = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          if (widget.currentSubject.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('مسح الحصة'),
            ),
          FilledButton(
            onPressed: widget.subjects.isEmpty
                ? null
                : () => Navigator.pop(
              context,
              selectedSubject ?? '',
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}



// ============================================================
// درجاتي
// ============================================================

class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  static const String _storageKey = 'student_grades';

  List<String> subjects = [];
  Map<String, double> grades = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    final prefs = await SharedPreferences.getInstance();
    final gradeName = prefs.getString('student_grade') ?? '';

    final loaded = <String, double>{};
    final saved = prefs.getString(_storageKey);

    if (saved != null && saved.isNotEmpty) {
      try {
        final decoded = jsonDecode(saved);

        if (decoded is Map) {
          decoded.forEach((key, value) {
            if (key is String && value is num) {
              loaded[key] = value.toDouble();
            }
          });
        }
      } catch (_) {}
    }

    if (!mounted) return;

    setState(() {
      subjects = List<String>.from(
        subjectsByGrade[gradeName] ?? const <String>[],
      );
      grades = loaded;
      loading = false;
    });
  }

  Future<void> _saveGrades() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(grades));
  }

  double get average {
    if (grades.isEmpty) return 0;

    final total = grades.values.fold<double>(
      0,
          (sum, value) => sum + value,
    );

    return total / grades.length;
  }

  String _resultText(double value) {
    if (value >= 90) return 'ممتاز';
    if (value >= 80) return 'جيد جداً';
    if (value >= 70) return 'جيد';
    if (value >= 50) return 'مقبول';
    return 'يحتاج مراجعة';
  }

  Future<void> _editGrade(String subject) async {
    final result = await showDialog<double>(
      context: context,
      builder: (_) => _GradeDialog(
        subject: subject,
        currentGrade: grades[subject],
      ),
    );

    if (result == null) return;

    setState(() {
      grades[subject] = result;
    });

    await _saveGrades();
  }

  Future<void> _deleteGrade(String subject) async {
    setState(() {
      grades.remove(subject);
    });

    await _saveGrades();
  }

  Widget _summaryCard() {
    final averageValue = average;

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFDB2777),
            Color(0xFFBE185D),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            'معدلي الحالي',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            grades.isEmpty
                ? '—'
                : '${averageValue.toStringAsFixed(1)} / 100',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (grades.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              _resultText(averageValue),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryMini(
                  title: 'المواد',
                  value: '${grades.length}/${subjects.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMini(
                  title: 'أعلى درجة',
                  value: grades.isEmpty
                      ? '—'
                      : grades.values
                      .reduce((a, b) => a > b ? a : b)
                      .toStringAsFixed(0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _subjectCard(String subject) {
    final value = grades[subject];
    final hasGrade = value != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _editGrade(subject),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: hasGrade
                      ? const Color(0xFFFCE7F3)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: hasGrade
                      ? const Color(0xFFDB2777)
                      : Colors.grey,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasGrade
                          ? _resultText(value!)
                          : 'اضغط لإضافة الدرجة',
                      style: TextStyle(
                        color: hasGrade
                            ? const Color(0xFFDB2777)
                            : Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasGrade)
                Text(
                  '${value!.toStringAsFixed(0)}/100',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDB2777),
                  ),
                )
              else
                const Icon(
                  Icons.add_circle_outline,
                  color: Color(0xFFDB2777),
                ),
              if (hasGrade)
                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'edit') {
                      _editGrade(subject);
                    } else if (action == 'delete') {
                      _deleteGrade(subject);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('تعديل'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('حذف'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'درجاتي',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: subjects.isEmpty
            ? const Center(
          child: Text(
            'لم يتم اختيار الصف بعد',
            style: TextStyle(
              fontSize: 17,
              color: Colors.grey,
            ),
          ),
        )
            : ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            _summaryCard(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'درجات المواد',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${grades.length} مسجلة',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: subjects
                    .map(_subjectCard)
                    .toList(),
              ),
            ),
          ],
        ),
        floatingActionButton: subjects.isEmpty
            ? null
            : FloatingActionButton.extended(
          onPressed: () async {
            final available = subjects
                .where((subject) => !grades.containsKey(subject))
                .toList();

            if (available.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('كل المواد تمت إضافة درجاتها'),
                  duration: Duration(seconds: 1),
                ),
              );
              return;
            }

            final subject = await showDialog<String>(
              context: context,
              builder: (_) => _ChooseSubjectDialog(
                subjects: available,
              ),
            );

            if (subject != null) {
              await _editGrade(subject);
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('إضافة درجة'),
        ),
      ),
    );
  }
}

class _SummaryMini extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryMini({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeDialog extends StatefulWidget {
  final String subject;
  final double? currentGrade;

  const _GradeDialog({
    required this.subject,
    required this.currentGrade,
  });

  @override
  State<_GradeDialog> createState() => _GradeDialogState();
}

class _GradeDialogState extends State<_GradeDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: widget.currentGrade == null
          ? ''
          : widget.currentGrade!.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(
          'درجة ${widget.subject}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'الدرجة من 100',
            hintText: 'مثلاً 85',
            prefixIcon: const Icon(Icons.star_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(
                controller.text.trim().replaceAll(',', '.'),
              );

              if (value == null || value < 0 || value > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('اكتب درجة صحيحة من 0 إلى 100'),
                    duration: Duration(seconds: 1),
                  ),
                );
                return;
              }

              Navigator.pop(context, value);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class _ChooseSubjectDialog extends StatelessWidget {
  final List<String> subjects;

  const _ChooseSubjectDialog({
    required this.subjects,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text(
          'اختيار المادة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: subjects.length,
            itemBuilder: (_, index) {
              final subject = subjects[index];

              return ListTile(
                leading: const Icon(
                  Icons.menu_book_outlined,
                  color: Color(0xFFDB2777),
                ),
                title: Text(subject),
                onTap: () => Navigator.pop(
                  context,
                  subject,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}


// ============================================================
// المواد
// ============================================================

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  String studentGrade = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadGrade();
  }

  Future<void> loadGrade() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      studentGrade = prefs.getString('student_grade') ?? '';
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final subjects = subjectsByGrade[studentGrade] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'المواد الدراسية',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: subjects.isEmpty
          ? const Center(
        child: Text(
          'لم يتم اختيار الصف بعد',
          style: TextStyle(
            fontSize: 17,
            color: Colors.grey,
          ),
        ),
      )
          : LayoutBuilder(
        builder: (context, constraints) {
          final columns =
          constraints.maxWidth >= 900 ? 4 : 2;

          return GridView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: subjects.length,
            gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              final subject = subjects[index];

              return SubjectCard(
                subject: subject,
                index: index,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubjectPage(
                        subjectName: subject,
                        grade: studentGrade,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
class SubjectCard extends StatelessWidget {
  final String subject;
  final int index;
  final VoidCallback onTap;

  const SubjectCard({
    super.key,
    required this.subject,
    required this.index,
    required this.onTap,
  });

  static const colors = [
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFF059669),
    Color(0xFFEA580C),
    Color(0xFFDB2777),
    Color(0xFF0891B2),
  ];

  static const icons = [
    Icons.menu_book_rounded,
    Icons.calculate_rounded,
    Icons.science_rounded,
    Icons.language_rounded,
    Icons.public_rounded,
    Icons.school_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final color = colors[index % colors.length];
    final icon = icons[index % icons.length];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subject,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 13,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class SubjectPage extends StatelessWidget {
  final String subjectName;
  final String grade;

  const SubjectPage({
    super.key,
    required this.subjectName,
    required this.grade,
  });

  @override
  Widget build(BuildContext context) {
    final books = booksByGrade[grade]?[subjectName] ?? const <BookItem>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          subjectName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(grade, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 6),
          Text(subjectName, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...books.map((book) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookViewerPage(title: book.title, assetPath: book.assetPath),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                        child: const Icon(Icons.menu_book_rounded, color: Color(0xFF2563EB), size: 34),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(book.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            const Text('الكتاب كامل بدون تقسيم', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.grey, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

// ============================================================
// الواجبات
// ============================================================

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key});

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  static const String _storageKey = 'student_homeworks';

  List<_HomeworkData> homeworks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadHomeworks();
  }

  Future<void> _loadHomeworks() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_storageKey) ?? [];
    final loaded = <_HomeworkData>[];

    for (final item in saved) {
      final parts = item.split('|');
      if (parts.length >= 5) {
        loaded.add(_HomeworkData(
          subject: parts[0],
          title: parts[1],
          dueDate: parts[2],
          completed: parts[3] == 'true',
          id: parts[4],
        ));
      }
    }

    if (!mounted) return;
    setState(() {
      homeworks = loaded;
      loading = false;
    });
  }

  Future<void> _saveHomeworks() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = homeworks.map((item) =>
    '${item.subject}|${item.title}|${item.dueDate}|${item.completed}|${item.id}').toList();
    await prefs.setStringList(_storageKey, saved);
  }

  Future<void> _addHomework() async {
    final result = await showDialog<_HomeworkData>(
      context: context,
      builder: (_) => const _AddHomeworkDialog(),
    );
    if (result == null) return;
    setState(() => homeworks.insert(0, result));
    await _saveHomeworks();
  }

  Future<void> _toggleHomework(int index) async {
    setState(() {
      homeworks[index].completed = !homeworks[index].completed;
    });
    await _saveHomeworks();
  }

  Future<void> _deleteHomework(int index) async {
    final removed = homeworks[index];
    setState(() => homeworks.removeAt(index));
    await _saveHomeworks();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حذف واجب ${removed.title}')),
    );
  }

  String _formatDate(String value) {
    if (value.isEmpty) return '';
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 95,
              height: 95,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_outlined,
                  color: Color(0xFF2563EB), size: 48),
            ),
            const SizedBox(height: 20),
            const Text('ما عندك واجبات حالياً',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'أضف واجبك الأول حتى تتابعه وتعرف موعد تسليمه.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _addHomework,
              icon: const Icon(Icons.add),
              label: const Text('إضافة واجب'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final completed = homeworks.where((item) => item.completed).length;
    final remaining = homeworks.length - completed;
    return Row(
      children: [
        Expanded(child: _HomeworkSummaryCard(title: 'كل الواجبات', value: '${homeworks.length}', icon: Icons.assignment)),
        const SizedBox(width: 10),
        Expanded(child: _HomeworkSummaryCard(title: 'المتبقي', value: '$remaining', icon: Icons.pending_actions)),
        const SizedBox(width: 10),
        Expanded(child: _HomeworkSummaryCard(title: 'المكتمل', value: '$completed', icon: Icons.check_circle_outline)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الواجبات', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              onPressed: _addHomework,
              icon: const Icon(Icons.add),
              tooltip: 'إضافة واجب',
            ),
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : homeworks.isEmpty
            ? _buildEmptyState()
            : ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _buildSummary(),
            const SizedBox(height: 18),
            ...List.generate(
              homeworks.length,
                  (index) {
                final item = homeworks[index];
                return _HomeworkItem(
                  subject: item.subject,
                  title: item.title,
                  dueDate: _formatDate(item.dueDate),
                  completed: item.completed,
                  onChanged: (_) => _toggleHomework(index),
                  onDelete: () => _deleteHomework(index),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeworkData {
  final String subject;
  final String title;
  final String dueDate;
  final String id;
  bool completed;

  _HomeworkData({
    required this.subject,
    required this.title,
    required this.dueDate,
    required this.completed,
    required this.id,
  });
}

class _AddHomeworkDialog extends StatefulWidget {
  const _AddHomeworkDialog();

  @override
  State<_AddHomeworkDialog> createState() => _AddHomeworkDialogState();
}

class _AddHomeworkDialogState extends State<_AddHomeworkDialog> {
  final titleController = TextEditingController();

  String? subject;
  DateTime? dueDate;

  final subjects = const [
    'التربية الإسلامية',
    'اللغة العربية',
    'القراءة',
    'القواعد',
    'الرياضيات',
    'العلوم',
    'اللغة الإنكليزية',
    'الاجتماعيات',
    'الأحياء',
    'الكيمياء',
    'الفيزياء',
    'اللغة الفرنسية',
    'الحاسوب',
    'التربية الأخلاقية',
  ];

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'اختر موعد تسليم الواجب',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );

    if (picked != null) {
      setState(() {
        dueDate = picked;
      });
    }
  }

  void _save() {
    final title = titleController.text.trim();

    if (subject == null || title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار المادة وكتابة الواجب'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      _HomeworkData(
        subject: subject!,
        title: title,
        dueDate: dueDate?.toIso8601String() ?? '',
        completed: false,
        id: DateTime.now().microsecondsSinceEpoch.toString(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text(
          'إضافة واجب جديد',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: subject,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'المادة',
                  prefixIcon: const Icon(Icons.menu_book_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                items: subjects
                    .map(
                      (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    subject = value;
                  });
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                maxLines: 3,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: 'الواجب',
                  hintText: 'مثلاً: حل تمارين الصفحة 25',
                  prefixIcon: const Icon(Icons.edit_note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _chooseDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'موعد التسليم',
                    prefixIcon: const Icon(Icons.calendar_month),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    dueDate == null
                        ? 'اختياري - لم يتم تحديد موعد'
                        : '${dueDate!.day.toString().padLeft(2, '0')}/'
                        '${dueDate!.month.toString().padLeft(2, '0')}/'
                        '${dueDate!.year}',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: _save,
            child: const Text('حفظ الواجب'),
          ),
        ],
      ),
    );
  }
}

class _HomeworkSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _HomeworkSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 22,
            color: const Color(0xFF2563EB),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ============================================================
// المساعد
// ============================================================

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantMessage {
  final String text;
  final bool isUser;
  final Uint8List? imageBytes;

  const _AssistantMessage({
    required this.text,
    required this.isUser,
    this.imageBytes,
  });
}

class _AssistantPageState extends State<AssistantPage> {
  final controller = TextEditingController();
  final scrollController = ScrollController();
  final ImagePicker picker = ImagePicker();

  final messages = <_AssistantMessage>[
    const _AssistantMessage(
      text: 'أهلاً بك 👋 أنا مساعدك الدراسي. صوّر واجبك أو اكتب سؤالك وأنا أساعدك خطوة بخطوة.',
      isUser: false,
    ),
  ];

  bool sending = false;

  Uint8List? selectedImageBytes;
  String? selectedImageMimeType;

  static const String serverUrl =
      'https://sahnaha-server.vercel.app/api/chat';

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // اختيار صورة من المعرض
  // ============================================================

  Future<void> pickFromGallery() async {
    if (sending) return;

    try {
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();

      if (!mounted) return;

      setState(() {
        selectedImageBytes = bytes;
        selectedImageMimeType = _getMimeType(file);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر اختيار الصورة'),
        ),
      );
    }
  }

  // ============================================================
  // الكاميرا
  // ============================================================

  Future<void> takePhoto() async {
    if (sending) return;

    try {
      final XFile? file = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();

      if (!mounted) return;

      setState(() {
        selectedImageBytes = bytes;
        selectedImageMimeType = _getMimeType(file);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح الكاميرا'),
        ),
      );
    }
  }

  String _getMimeType(XFile file) {
    final mime = file.mimeType;

    if (mime != null && mime.isNotEmpty) {
      return mime;
    }

    final path = file.path.toLowerCase();

    if (path.endsWith('.png')) {
      return 'image/png';
    }

    if (path.endsWith('.webp')) {
      return 'image/webp';
    }

    return 'image/jpeg';
  }

  void removeSelectedImage() {
    if (sending) return;

    setState(() {
      selectedImageBytes = null;
      selectedImageMimeType = null;
    });
  }

  // ============================================================
  // إرسال السؤال / الصورة
  // ============================================================

  Future<void> send({
    String? customPrompt,
  }) async {
    final typedText = controller.text.trim();
    final text = customPrompt ?? typedText;

    if ((text.isEmpty && selectedImageBytes == null) || sending) {
      return;
    }

    final imageBytes = selectedImageBytes;
    final imageMimeType = selectedImageMimeType ?? 'image/jpeg';

    final imageBase64 =
    imageBytes != null ? base64Encode(imageBytes) : null;

    final userText = text.isEmpty
        ? 'حل هاي الصورة واشرحلي الحل خطوة بخطوة.'
        : text;

    controller.clear();

    setState(() {
      messages.add(
        _AssistantMessage(
          text: userText,
          isUser: true,
          imageBytes: imageBytes,
        ),
      );

      selectedImageBytes = null;
      selectedImageMimeType = null;
      sending = true;
    });

    _scrollToBottom();

    try {
      final prefs = await SharedPreferences.getInstance();

      final studentName =
          prefs.getString('student_name') ?? 'الطالب';

      final studentGrade =
          prefs.getString('student_grade') ?? 'غير محدد';

      final response = await http
          .post(
        Uri.parse(serverUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': text,
          'studentName': studentName,
          'studentGrade': studentGrade,
          'image': imageBase64,
          'imageMimeType': imageMimeType,
        }),
      )
          .timeout(
        const Duration(seconds: 60),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        final answer = data['answer']?.toString();

        if (data['success'] == true &&
            answer != null &&
            answer.isNotEmpty) {
          setState(() {
            messages.add(
              _AssistantMessage(
                text: answer,
                isUser: false,
              ),
            );
          });
        } else {
          setState(() {
            messages.add(
              const _AssistantMessage(
                text: 'عذراً، المساعد ما قدر يطلع جواب حالياً.',
                isUser: false,
              ),
            );
          });
        }
      } else {
        String errorText = 'تعذر الاتصال بالمساعد.\nرمز الخطأ: ${response.statusCode}';

        try {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final serverError = data['error']?.toString();

          if (serverError != null && serverError.isNotEmpty) {
            errorText = 'تعذر الاتصال بالمساعد.\n$serverError';
          }
        } catch (_) {}

        setState(() {
          messages.add(
            _AssistantMessage(
              text: errorText,
              isUser: false,
            ),
          );
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        messages.add(
          const _AssistantMessage(
            text:
            'ما قدرت أتصل بالسيرفر 🤖\n\n'
                'تأكد من اتصال الإنترنت وحاول مرة ثانية.',
            isUser: false,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          sending = false;
        });

        _scrollToBottom();
      }
    }
  }

  // ============================================================
  // أوامر المساعد
  // ============================================================

  Future<void> repeatExplanation(String answer) async {
    await send(
      customPrompt:
      'أعد شرح جوابك السابق بطريقة أوضح وبخطوات أبسط، '
          'ومناسبة لصف الطالب. لا تختصر الحل.',
    );
  }

  Future<void> simplifyExplanation(String answer) async {
    await send(
      customPrompt:
      'اشرح جوابك السابق بطريقة أبسط جداً وكأنك تشرح لطالب صغير، '
          'واستخدم مثالاً بسيطاً إذا كان ذلك يساعد على الفهم.',
    );
  }

  Future<void> makeQuiz(String answer) async {
    await send(
      customPrompt:
      'اعمل لي سؤالاً تدريبياً مشابهاً للموضوع الذي شرحته للتو. '
          'لا تعطِ الجواب مباشرة. اترك للطالب فرصة يحاول، '
          'ثم اطلب منه أن يرسل إجابته.',
    );
  }

  // ============================================================
  // النزول إلى آخر رسالة
  // ============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ============================================================
  // أزرار المساعدة بعد جواب Gemini
  // ============================================================

  Widget _assistantActions(String answer) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 8,
        right: 8,
        bottom: 14,
      ),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          ActionChip(
            avatar: const Icon(
              Icons.refresh_rounded,
              size: 18,
            ),
            label: const Text('أعد الشرح'),
            onPressed: sending
                ? null
                : () => repeatExplanation(answer),
          ),
          ActionChip(
            avatar: const Icon(
              Icons.lightbulb_outline_rounded,
              size: 18,
            ),
            label: const Text('شرح أبسط'),
            onPressed: sending
                ? null
                : () => simplifyExplanation(answer),
          ),
          ActionChip(
            avatar: const Icon(
              Icons.psychology_alt_outlined,
              size: 18,
            ),
            label: const Text('اختبرني'),
            onPressed: sending
                ? null
                : () => makeQuiz(answer),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // فقاعة الرسالة
  // ============================================================

  Widget _messageBubble(
      _AssistantMessage message,
      int index,
      ) {
    final isUser = message.isUser;

    return Column(
      crossAxisAlignment:
      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment:
          isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 340,
            ),
            margin: const EdgeInsets.only(
              bottom: 6,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(
                  isUser ? 18 : 4,
                ),
                bottomRight: Radius.circular(
                  isUser ? 4 : 18,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.imageBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        message.imageBytes!,
                        width: 280,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                if (message.text.isNotEmpty)
                  Text(
                    message.text,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : Colors.black87,
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),
              ],
            ),
          ),
        ),

        if (!isUser && index > 0)
          _assistantActions(message.text),
      ],
    );
  }

  // ============================================================
  // معاينة الصورة
  // ============================================================

  Widget _selectedImagePreview() {
    if (selectedImageBytes == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              selectedImageBytes!,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'الصورة جاهزة للإرسال\nاضغط إرسال حتى يحلها المساعد.',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: sending ? null : removeSelectedImage,
            icon: const Icon(
              Icons.close_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // واجهة المساعد
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'المساعد الذكي',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
              ),
              child: Center(
                child: Icon(
                  Icons.smart_toy_rounded,
                  color: Color(0xFFEA580C),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  10,
                ),
                itemCount: messages.length + (sending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (sending && index == messages.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(
                          bottom: 10,
                        ),
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    );
                  }

                  return _messageBubble(
                    messages[index],
                    index,
                  );
                },
              ),
            ),

            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  10,
                  8,
                  10,
                  12,
                ),
                child: Column(
                  children: [
                    _selectedImagePreview(),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // المعرض
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF8B5CF6),
                                Color(0xFF6366F1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed:
                            sending ? null : pickFromGallery,
                            tooltip: 'اختيار صورة',
                            icon: const Icon(
                              Icons.photo_library_rounded,
                              color: Colors.white,
                              size: 23,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        // الكاميرا
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF0EA5E9),
                                Color(0xFF2563EB),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed:
                            sending ? null : takePhoto,
                            tooltip: 'الكاميرا',
                            icon: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 23,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        Expanded(
                          child: TextField(
                            controller: controller,
                            enabled: !sending,
                            minLines: 1,
                            maxLines: 4,
                            textDirection: TextDirection.rtl,
                            onSubmitted: (_) => send(),
                            decoration: InputDecoration(
                              hintText: 'اكتب سؤالك هنا...',
                              filled: true,
                              fillColor: const Color(0xFFF1F5F9),
                              contentPadding:
                              const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        // إرسال
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFEA580C),
                                Color(0xFFF97316),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.16),
                                blurRadius: 9,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: sending ? null : send,
                            tooltip: 'إرسال',
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 23,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// المزيد
// ============================================================

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  Future<void> _open(BuildContext context, Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'المزيد',
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'إدارة حسابك وإعدادات التطبيق',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 18),
        Card(
          elevation: 0,
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text('ملفي الدراسي'),
            subtitle: const Text('الاسم والصف والمرحلة'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => _open(context, const StudentProfileViewPage()),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('الإعدادات'),
            subtitle: const Text('الاسم، الإيميل، الرمز وحجم الواجهة'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => _open(context, const SettingsPage()),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('عن التطبيق والحقوق'),
            subtitle: const Text('معلومات التطبيق وطرق التواصل'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => _open(context, const AboutAppPage()),
          ),
        ),
      ],
    );
  }
}

class StudentProfileViewPage extends StatelessWidget {
  const StudentProfileViewPage({super.key});

  Future<Map<String, String>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('student_name') ?? 'غير محدد',
      'email': prefs.getString('student_email') ?? 'غير محدد',
      'stage': prefs.getString('student_stage') ?? 'غير محدد',
      'grade': prefs.getString('student_grade') ?? 'غير محدد',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ملفي الدراسي')),
        body: FutureBuilder<Map<String, String>>(
          future: _load(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const CircleAvatar(
                  radius: 48,
                  child: Icon(Icons.person, size: 52),
                ),
                const SizedBox(height: 18),
                _infoTile(Icons.person_outline, 'الاسم', data['name']!),
                _infoTile(Icons.email_outlined, 'الإيميل', data['email']!),
                _infoTile(Icons.school_outlined, 'المرحلة', data['stage'] == 'primary' ? 'المرحلة الابتدائية' : 'المرحلة المتوسطة'),
                _infoTile(Icons.menu_book_outlined, 'الصف', data['grade']!),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double scale = 1.0;

  @override
  void initState() {
    super.initState();
    scale = uiScaleNotifier.value;
  }

  Future<void> _setScale(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ui_scale', value);
    uiScaleNotifier.value = value;
    setState(() => scale = value);
  }

  Future<void> _editAccount() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditAccountPage()),
    );
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من الحساب؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('خروج')),
        ],
      ),
    );
    if (ok != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الإعدادات')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              elevation: 0,
              child: ListTile(
                leading: const Icon(Icons.manage_accounts_outlined),
                title: const Text('بيانات الحساب'),
                subtitle: const Text('تعديل الاسم أو الإيميل أو الرمز'),
                trailing: const Icon(Icons.chevron_left),
                onTap: _editAccount,
              ),
            ),
            const SizedBox(height: 18),
            const Text('حجم الواجهات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              child: Column(
                children: [
                  RadioListTile<double>(value: 0.9, groupValue: scale, onChanged: (v) { if (v != null) _setScale(v); }, title: const Text('صغير')),
                  RadioListTile<double>(value: 1.0, groupValue: scale, onChanged: (v) { if (v != null) _setScale(v); }, title: const Text('طبيعي')),
                  RadioListTile<double>(value: 1.15, groupValue: scale, onChanged: (v) { if (v != null) _setScale(v); }, title: const Text('كبير')),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Card(
              elevation: 0,
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('عن التطبيق والحقوق'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutAppPage())),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );
  }
}

class EditAccountPage extends StatefulWidget {
  const EditAccountPage({super.key});

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool loading = false;
  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    nameController.text = prefs.getString('student_name') ?? '';
    emailController.text = prefs.getString('student_email') ?? '';
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _show(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _save() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final currentPassword = currentPasswordController.text;
    final newPassword = newPasswordController.text;

    if (name.split(RegExp(r'\s+')).length < 3) {
      _show('اكتب الاسم الثلاثي');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _show('اكتب إيميل صحيح');
      return;
    }
    if (currentPassword.isEmpty) {
      _show('اكتب الرمز الحالي للتأكيد');
      return;
    }
    if (newPassword.isNotEmpty && newPassword.length < 6) {
      _show('الرمز الجديد يجب أن يكون 6 أحرف أو أرقام على الأقل');
      return;
    }
    if (newPassword != confirmPasswordController.text) {
      _show('الرمزان الجديدان غير متطابقين');
      return;
    }

    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldEmail = prefs.getString('student_email') ?? '';
      final response = await http.post(
        Uri.parse('$authBaseUrl/auth/update-profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': oldEmail,
          'currentPassword': currentPassword,
          'newFullName': name,
          'newEmail': email,
          'newPassword': newPassword.isEmpty ? null : newPassword,
        }),
      ).timeout(const Duration(seconds: 30));
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && data['success'] == true) {
        final user = data['user'];
        await prefs.setString('student_name', user['fullName'].toString());
        await prefs.setString('student_email', user['email'].toString());
        await prefs.setString('student_stage', user['stage'].toString());
        await prefs.setString('student_grade', user['grade'].toString());
        if (!mounted) return;
        _show('تم حفظ بيانات الحساب بنجاح');
        Navigator.pop(context);
      } else {
        _show(data['error']?.toString() ?? 'تعذر حفظ البيانات');
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      _show('تعذر الاتصال بالسيرفر');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تعديل الحساب')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم الثلاثي', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder())),
              const SizedBox(height: 14),
              TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'الإيميل', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder())),
              const SizedBox(height: 22),
              const Align(alignment: Alignment.centerRight, child: Text('للتأكيد اكتب الرمز الحالي', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 10),
              TextField(controller: currentPasswordController, obscureText: obscureCurrent, decoration: InputDecoration(labelText: 'الرمز الحالي', prefixIcon: const Icon(Icons.lock_outline), border: const OutlineInputBorder(), suffixIcon: IconButton(onPressed: () => setState(() => obscureCurrent = !obscureCurrent), icon: Icon(obscureCurrent ? Icons.visibility : Icons.visibility_off)))),
              const SizedBox(height: 22),
              const Align(alignment: Alignment.centerRight, child: Text('إذا تريد تغيير الرمز فقط', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 10),
              TextField(controller: newPasswordController, obscureText: obscureNew, decoration: InputDecoration(labelText: 'الرمز الجديد (اختياري)', prefixIcon: const Icon(Icons.password_outlined), border: const OutlineInputBorder(), suffixIcon: IconButton(onPressed: () => setState(() => obscureNew = !obscureNew), icon: Icon(obscureNew ? Icons.visibility : Icons.visibility_off)))),
              const SizedBox(height: 14),
              TextField(controller: confirmPasswordController, obscureText: obscureConfirm, decoration: InputDecoration(labelText: 'تأكيد الرمز الجديد', prefixIcon: const Icon(Icons.password_outlined), border: const OutlineInputBorder(), suffixIcon: IconButton(onPressed: () => setState(() => obscureConfirm = !obscureConfirm), icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off)))),
              const SizedBox(height: 26),
              SizedBox(width: double.infinity, height: 54, child: FilledButton(onPressed: loading ? null : _save, child: loading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Text('حفظ التعديلات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)))),
            ],
          ),
        ),
      ),
    );
  }
}

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  void _copy(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('عن التطبيق والحقوق')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const CircleAvatar(radius: 46, child: Icon(Icons.school_rounded, size: 50)),
            const SizedBox(height: 15),
            const Center(child: Text('مساعد الطالب العراقي', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            const Center(child: Text('تطبيق تعليمي لمساعدة الطلبة العراقيين', textAlign: TextAlign.center)),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              child: ListTile(
                leading: const Icon(Icons.phone_android),
                title: const Text('رقم الحقوق والتواصل'),
                subtitle: const SelectableText('9647718245095'),
                trailing: IconButton(icon: const Icon(Icons.copy), onPressed: () => _copy(context, '9647718245095', 'تم نسخ الرقم')),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              child: ListTile(
                leading: const Icon(Icons.telegram),
                title: const Text('حساب التليگرام'),
                subtitle: const SelectableText('@malaa95'),
                trailing: IconButton(icon: const Icon(Icons.copy), onPressed: () => _copy(context, '@malaa95', 'تم نسخ حساب التليگرام')),
              ),
            ),
            const SizedBox(height: 22),
            const Text('الإصدار', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('مساعد الطالب العراقي'),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Widgets
// ============================================================

class _HomeTool extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _HomeTool({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 35,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeworkItem extends StatelessWidget {
  final String subject;
  final String title;
  final String dueDate;
  final bool completed;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onDelete;

  const _HomeworkItem({
    required this.subject,
    required this.title,
    required this.dueDate,
    required this.completed,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 7,
        ),
        leading: CircleAvatar(
          backgroundColor: completed
              ? const Color(0xFFDCFCE7)
              : const Color(0xFFEFF6FF),
          child: Icon(
            completed
                ? Icons.check
                : Icons.assignment_outlined,
            color: completed
                ? const Color(0xFF16A34A)
                : const Color(0xFF2563EB),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration:
            completed ? TextDecoration.lineThrough : null,
            color: completed ? Colors.grey : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            dueDate.isEmpty
                ? subject
                : '$subject  •  التسليم: $dueDate',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: completed,
              onChanged: onChanged,
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('حذف الواجب'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BookViewerPage extends StatefulWidget {
  final String title;
  final String assetPath;

  const BookViewerPage({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  State<BookViewerPage> createState() => _BookViewerPageState();
}

class _BookViewerPageState extends State<BookViewerPage> {
  Uint8List? pdfBytes;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    try {
      final data = await rootBundle.load(widget.assetPath);
      if (!mounted) return;
      setState(() {
        pdfBytes = data.buffer.asUint8List();
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'مسار الكتاب:\n${widget.assetPath}\n\nالخطأ:\n$e';
      });
    }
  }

  Future<void> _printBook() async {
    final bytes = pdfBytes;
    if (bytes == null) return;
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'طباعة الكتاب',
            onPressed: pdfBytes == null ? null : _printBook,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('تعذر فتح الكتاب\n\n$errorMessage', textAlign: TextAlign.center),
        ),
      );
    }
    if (pdfBytes == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return SfPdfViewer.memory(
      pdfBytes!,
      enableDoubleTapZooming: false,
      enableTextSelection: false,
      canShowScrollHead: true,
      canShowScrollStatus: true,
    );
  }
}

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  String studentStage = '';
  String studentGrade = '';
  bool loading = true;
  String? selectedCategory;
  List<QuizQuestion> questions = [];

  int currentQuestion = 0;
  int score = 0;
  int? selectedAnswer;
  bool answered = false;

  @override
  void initState() {
    super.initState();
    _loadStudentInfo();
  }

  Future<void> _loadStudentInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      studentStage = prefs.getString('student_stage') ?? '';
      studentGrade = prefs.getString('student_grade') ?? '';
      loading = false;
    });
  }

  List<String> get availableCategories {
    final prefix = studentStage == 'primary'
        ? 'الابتدائي - '
        : studentStage == 'middle'
        ? 'المتوسط - '
        : '';

    if (prefix.isEmpty) return const [];

    return quizQuestions.keys
        .where((key) => key.startsWith(prefix))
        .toList()
      ..sort();
  }

  void _startQuiz(String category) {
    final bankQuestions = quizQuestions[category] ?? const <QuizQuestion>[];
    if (bankQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ماكو أسئلة متوفرة لهذه المادة حالياً.')),
      );
      return;
    }

    setState(() {
      selectedCategory = category;
      questions = List<QuizQuestion>.from(bankQuestions);
      currentQuestion = 0;
      score = 0;
      selectedAnswer = null;
      answered = false;
    });
  }

  void _backToSubjects() {
    setState(() {
      selectedCategory = null;
      questions = [];
      currentQuestion = 0;
      score = 0;
      selectedAnswer = null;
      answered = false;
    });
  }

  void selectAnswer(int index) {
    if (answered || questions.isEmpty) return;

    setState(() {
      selectedAnswer = index;
      answered = true;

      if (index == questions[currentQuestion].correctAnswer) {
        score++;
      }
    });
  }

  void nextQuestion() {
    if (questions.isEmpty) return;

    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
        selectedAnswer = null;
        answered = false;
      });
    } else {
      _showResult();
    }
  }

  void _restartQuiz() {
    setState(() {
      currentQuestion = 0;
      score = 0;
      selectedAnswer = null;
      answered = false;
    });
  }

  void _showResult() {
    if (questions.isEmpty) return;
    final percent = ((score / questions.length) * 100).round();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            '🎉 انتهى الاختبار',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedCategory ?? 'نتيجتك',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                '$score / ${questions.length}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text('$percent / 100'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _backToSubjects();
              },
              child: const Text('اختيار مادة أخرى'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _restartQuiz();
              },
              child: const Text('إعادة الاختبار'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (selectedCategory == null) {
      final categories = availableCategories;

      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'اختبر نفسك',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: categories.isEmpty
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'ما قدرنا نحدد المرحلة الدراسية المحفوظة بالحساب. '
                    'سجّل الدخول مرة ثانية وتأكد من معلومات الطالب.',
                textAlign: TextAlign.center,
              ),
            ),
          )
              : ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'اختار المادة',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6D28D9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      studentGrade.isEmpty
                          ? 'اختر المادة اللي تريد تختبر نفسك بيها.'
                          : 'الصف: $studentGrade\nاختار المادة حتى يبدأ الاختبار.',
                      style: const TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ...categories.map((category) {
                final count = quizQuestions[category]?.length ?? 0;
                final subject = category
                    .replaceFirst('الابتدائي - ', '')
                    .replaceFirst('المتوسط - ', '');

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF3E8FF),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    title: Text(
                      subject,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    subtitle: Text('$count سؤال متوفر'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 17),
                    onTap: () => _startQuiz(category),
                  ),
                );
              }),
              if (studentStage == 'middle')
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'ملاحظة: مادة اللغة الإنكليزية غير مضافة حالياً لأسئلة المرحلة المتوسطة.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('اختبر نفسك')),
        body: Center(
          child: FilledButton(
            onPressed: _backToSubjects,
            child: const Text('العودة للمواد'),
          ),
        ),
      );
    }

    final question = questions[currentQuestion];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            selectedCategory!
                .replaceFirst('الابتدائي - ', '')
                .replaceFirst('المتوسط - ', ''),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            tooltip: 'العودة للمواد',
            icon: const Icon(Icons.arrow_back),
            onPressed: _backToSubjects,
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Text(
                    'السؤال ${currentQuestion + 1} من ${questions.length}',
                    style: const TextStyle(
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (currentQuestion + 1) / questions.length,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  question.question,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            ...List.generate(question.options.length, (index) {
              final isSelected = selectedAnswer == index;
              final isCorrect = index == question.correctAnswer;

              Color? background;
              IconData? icon;

              if (answered && isCorrect) {
                background = const Color(0xFFD1FAE5);
                icon = Icons.check_circle;
              } else if (answered && isSelected) {
                background = const Color(0xFFFEE2E2);
                icon = Icons.cancel;
              }

              return Card(
                color: background,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: CircleAvatar(
                    child: Text(String.fromCharCode(65 + index)),
                  ),
                  title: Text(
                    question.options[index],
                    style: const TextStyle(fontSize: 17),
                  ),
                  trailing: icon == null ? null : Icon(icon),
                  onTap: answered ? null : () => selectAnswer(index),
                ),
              );
            }),
            const SizedBox(height: 8),
            if (answered)
              FilledButton.icon(
                onPressed: nextQuestion,
                icon: Icon(
                  currentQuestion == questions.length - 1
                      ? Icons.emoji_events
                      : Icons.arrow_back,
                ),
                label: Text(
                  currentQuestion == questions.length - 1
                      ? 'عرض النتيجة'
                      : 'السؤال التالي',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

