import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'subjects_data.dart';
import 'books_data.dart';

class StudyAlarmPage extends StatefulWidget {
  const StudyAlarmPage({super.key});

  @override
  State<StudyAlarmPage> createState() => _StudyAlarmPageState();
}

class _StudyAlarmPageState extends State<StudyAlarmPage> {
  final _note = TextEditingController();

  String _subject = 'الرياضيات';
  TimeOfDay _time = TimeOfDay.now();
  bool _hasAlarm = false;
  int _alarmId = 751001;
  String? _selectedAudioPath;
  String? _selectedAudioName;

  // المواد والكتب تُحمّل حسب الصف المسجل للطالب.
  List<String> subjects = [];
  String studentGrade = '';
  List<BookItem> availableBooks = [];
  String? selectedBookTitle;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGrade = prefs.getString('student_grade') ?? '';
    final savedSubject = prefs.getString('study_alarm_subject');
    final savedHour = prefs.getInt('study_alarm_hour');
    final savedMinute = prefs.getInt('study_alarm_minute');
    final savedAudioPath = prefs.getString('study_alarm_audio_path');
    final savedAudioName = prefs.getString('study_alarm_audio_name');
    final gradeSubjects = subjectsByGrade[savedGrade] ?? const <String>[];
    final gradeBooks = booksByGrade[savedGrade] ?? const <String, List<BookItem>>{};

    if (!mounted) return;
    setState(() {
      studentGrade = savedGrade;
      _selectedAudioPath = savedAudioPath;
      _selectedAudioName = savedAudioName;
      subjects = List<String>.from(gradeSubjects);
      if (savedSubject != null && subjects.contains(savedSubject)) {
        _subject = savedSubject;
      } else if (subjects.isNotEmpty) {
        _subject = subjects.first;
      } else {
        _subject = 'الرياضيات';
      }
      availableBooks = List<BookItem>.from(gradeBooks[_subject] ?? const <BookItem>[]);
      selectedBookTitle = availableBooks.isNotEmpty ? availableBooks.first.title : null;
      if (savedHour != null && savedMinute != null) {
        _time = TimeOfDay(hour: savedHour, minute: savedMinute);
      }
    });
    _refreshAlarm();
  }

  Future<void> _refreshAlarm() async {
    final alarms = await Alarm.getAlarms();
    if (!mounted) return;
    setState(() => _hasAlarm = alarms.any((a) => a.id == _alarmId));
  }



  Future<void> _pickAlarmSound() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
      );
      if (file == null) return;
      final path = file.path;
      if (path == null || path.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ما كدرنا نوصل لملف النغمة، اختاري ملف صوتي محفوظ بالجهاز.')),
        );
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('study_alarm_audio_path', path);
      await prefs.setString('study_alarm_audio_name', file.name);
      if (!mounted) return;
      setState(() {
        _selectedAudioPath = path;
        _selectedAudioName = file.name;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم اختيار النغمة: ${file.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر اختيار النغمة: $e')),
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _saveAlarm() async {
    final now = DateTime.now();
    var date = DateTime(now.year, now.month, now.day, _time.hour, _time.minute);
    if (!date.isAfter(now)) date = date.add(const Duration(days: 1));

    await Alarm.stop(_alarmId);
    final settings = AlarmSettings(
      id: _alarmId,
      dateTime: date,
      assetAudioPath: _selectedAudioPath,
      loopAudio: true,
      vibrate: true,
      androidFullScreenIntent: true,
      androidStopAlarmOnTermination: false,
      volumeSettings: const VolumeSettings.fixed(volume: 1.0, volumeEnforced: true),
      notificationSettings: NotificationSettings(
        title: 'مساعد الطالب العراقي 🔔',
        body: 'حان وقت دراسة $_subject${selectedBookTitle == null ? '' : ' — $selectedBookTitle'}',
        stopButton: 'إيقاف المنبّه',
        androidStopAlarmOnDismiss: false,
      ),
      payload: 'study_alarm',
    );

    final ok = await Alarm.set(alarmSettings: settings);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('study_alarm_subject', _subject);
    if (selectedBookTitle != null) {
      await prefs.setString('study_alarm_book', selectedBookTitle!);
    } else {
      await prefs.remove('study_alarm_book');
    }
    if (_selectedAudioPath != null) {
      await prefs.setString('study_alarm_audio_path', _selectedAudioPath!);
      await prefs.setString('study_alarm_audio_name', _selectedAudioName ?? 'نغمة مخصصة');
    }
    await prefs.setString('study_alarm_note', _note.text.trim());
    await prefs.setInt('study_alarm_hour', _time.hour);
    await prefs.setInt('study_alarm_minute', _time.minute);

    if (!mounted) return;
    setState(() => _hasAlarm = ok);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'تم ضبط المنبّه على ${_time.format(context)}' : 'تعذر ضبط المنبّه')),
    );
  }

  Future<void> _cancelAlarm() async {
    await Alarm.stop(_alarmId);
    if (!mounted) return;
    setState(() => _hasAlarm = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء المنبّه')));
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF26364A);
    const gold = Color(0xFFB08D57);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F3EA),
        appBar: AppBar(
          title: const Text('المنبّه الدراسي', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: navy,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(24)),
              child: const Row(children: [
                Icon(Icons.alarm_rounded, color: Color(0xFFD6B56A), size: 42),
                SizedBox(width: 14),
                Expanded(child: Text('حدد وقت الدراسة، ومن يرن المنبّه تكدر توقفه من زر الإيقاف بالإشعار.', style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5))),
              ]),
            ),
            const SizedBox(height: 18),
            if (subjects.isNotEmpty)
              DropdownButtonFormField<String>(
                value: subjects.contains(_subject) ? _subject : subjects.first,
                decoration: _decoration('المادة', Icons.menu_book_outlined),
                items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  final gradeBooks = booksByGrade[studentGrade] ?? const <String, List<BookItem>>{};
                  setState(() {
                    _subject = v;
                    availableBooks = List<BookItem>.from(gradeBooks[v] ?? const <BookItem>[]);
                    selectedBookTitle = availableBooks.isNotEmpty ? availableBooks.first.title : null;
                  });
                },
              ),
            if (availableBooks.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...availableBooks.map((book) {
                final isSelected = selectedBookTitle == book.title;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isSelected ? const Color(0xFFEDE6D7) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => selectedBookTitle = book.title),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFB08D57) : const Color(0xFFE3DED4),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              book.title.contains('تمارين') || book.title.contains('نشاط')
                                  ? Icons.edit_note_rounded
                                  : Icons.menu_book_rounded,
                              color: const Color(0xFFB08D57),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                book.title,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: Color(0xFF26364A)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
            if (subjects.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('ما لكينا مواد لهذا الصف. تأكد من الصف المسجل للطالب.'),
                ),
              ),
            const SizedBox(height: 12),
            TextField(controller: _note, maxLines: 2, decoration: _decoration('ملاحظة (اختياري)', Icons.notes_outlined)),
            const SizedBox(height: 12),
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: ListTile(
                leading: const Icon(Icons.schedule, color: gold, size: 30),
                title: const Text('وقت المنبّه', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_time.format(context), style: const TextStyle(fontSize: 20, color: navy, fontWeight: FontWeight.bold)),
                trailing: FilledButton(onPressed: _pickTime, child: const Text('اختيار')),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: const Color(0xFFEDE6D7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: ListTile(
                leading: const Icon(Icons.music_note, color: gold, size: 30),
                title: const Text('نغمة المنبّه', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  _selectedAudioName ?? 'صوت المنبّه الافتراضي للجهاز',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: FilledButton.icon(
                  onPressed: _pickAlarmSound,
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text('اختيار'),
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: navy, minimumSize: const Size.fromHeight(54)),
              onPressed: _saveAlarm,
              icon: const Icon(Icons.alarm_add),
              label: const Text('حفظ وتشغيل المنبّه', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
            if (_hasAlarm) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(onPressed: _cancelAlarm, icon: const Icon(Icons.alarm_off), label: const Text('إلغاء المنبّه')),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: const Color(0xFFB08D57)),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
  );

  Widget _field(TextEditingController c, String label, IconData icon) => TextField(controller: c, decoration: _decoration(label, icon));
}


// Kept for compatibility with main.dart: no math question, just a stop screen.
class AlarmQuestionPage extends StatelessWidget {
  final int alarmId;
  final String subject;
  final String studentName;
  final String note;
  final int initialA;
  final int initialB;
  final String initialOperator;
  final int initialAnswer;

  const AlarmQuestionPage({
    super.key,
    required this.alarmId,
    required this.subject,
    required this.studentName,
    required this.note,
    required this.initialA,
    required this.initialB,
    required this.initialOperator,
    required this.initialAnswer,
  });

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF26364A);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: false,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('المنبّه الدراسي'),
            backgroundColor: navy,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_active, size: 72, color: Color(0xFFB08D57)),
                  const SizedBox(height: 16),
                  Text('حان وقت دراسة $subject', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(note, textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: navy),
                      onPressed: () async {
                        await Alarm.stop(alarmId);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.alarm_off),
                      label: const Text('إيقاف المنبّه'),
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
