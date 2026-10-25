import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'books_data.dart';

class AudioLessonsPage extends StatefulWidget {
  const AudioLessonsPage({super.key});

  @override
  State<AudioLessonsPage> createState() => _AudioLessonsPageState();
}

class _AudioLessonsPageState extends State<AudioLessonsPage> {
  String studentGrade = '';
  String? selectedSubject;
  BookItem? selectedBook;
  Uint8List? _pdfBytes;
  bool _loadingPdf = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isBusy = false;
  String? _recordingPath;
  int selectedPage = 1;
  int repeatCount = 1; // 0 means repeat continuously
  double playbackSpeed = 1.0;
  int _remainingPlays = 0;
  bool _playbackSessionActive = false;

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final PdfViewerController _pdfController = PdfViewerController();
  final TextEditingController _pageController = TextEditingController(text: '1');
  List<String> availableSubjects = [];
  List<BookItem> availableBooks = [];

  @override
  void initState() {
    super.initState();
    _loadStudent();
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        _handlePlaybackCompleted();
      } else {
        setState(() => _isPlaying = state.playing);
      }
    });
  }

  Future<void> _loadStudent() async {
    final prefs = await SharedPreferences.getInstance();
    final grade = prefs.getString('student_grade') ?? '';
    if (!mounted) return;
    final gradeBooks = booksByGrade[grade] ?? <String, List<BookItem>>{};
    setState(() {
      studentGrade = grade;
      // Show subjects that actually have books mapped for this grade.
      availableSubjects = gradeBooks.entries
          .where((entry) => entry.value.isNotEmpty)
          .map((entry) => entry.key)
          .toList();
    });
  }

  String get _recordingKey {
    final subject = selectedSubject ?? 'none';
    final bookPart = (selectedBook?.assetPath ?? 'no_book')
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return 'audio_lesson_${studentGrade}_${subject}_${bookPart}_page_$selectedPage';
  }

  Future<void> _selectSubject(String subject) async {
    final books = booksByGrade[studentGrade]?[subject] ?? <BookItem>[];
    BookItem? primaryBook;
    for (final book in books) {
      if (book.title.startsWith('كتاب')) {
        primaryBook = book;
        break;
      }
    }
    primaryBook ??= books.isNotEmpty ? books.first : null;

    setState(() {
      selectedSubject = subject;
      selectedBook = primaryBook;
      availableBooks = books;
      _pdfBytes = null;
      _recordingPath = null;
      _loadingPdf = primaryBook != null;
    });
    await _stopAudioAndRecording();
    if (primaryBook == null) {
      _message('ما لكيت كتاب لهذه المادة');
      return;
    }
    try {
      final data = await rootBundle.load(primaryBook.assetPath);
      if (!mounted || selectedBook?.assetPath != primaryBook.assetPath) return;
      setState(() {
        _pdfBytes = data.buffer.asUint8List();
        _loadingPdf = false;
      });
      await _loadSavedRecording();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pdfController.jumpToPage(selectedPage);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPdf = false);
      _message('تعذر فتح كتاب هذه المادة');
    }
  }

  Future<void> _selectBook(BookItem book) async {
    await _stopAudioAndRecording();
    setState(() {
      selectedBook = book;
      _pdfBytes = null;
      _recordingPath = null;
      _loadingPdf = true;
    });
    try {
      final data = await rootBundle.load(book.assetPath);
      if (!mounted || selectedBook?.assetPath != book.assetPath) return;
      setState(() {
        _pdfBytes = data.buffer.asUint8List();
        _loadingPdf = false;
      });
      await _loadSavedRecording();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pdfController.jumpToPage(selectedPage);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPdf = false);
      _message('تعذر فتح هذا الكتاب؛ تأكدي أن مساره مضاف في pubspec.yaml');
    }
  }

  Future<void> _changePage(String value) async {
    final page = int.tryParse(value.trim());
    if (page == null || page < 1) {
      _message('اكتبي رقم صفحة صحيح');
      return;
    }
    await _stopAudioAndRecording();
    setState(() {
      selectedPage = page;
      _pageController.text = '$page';
      _recordingPath = null;
    });
    if (_pdfBytes != null) {
      _pdfController.jumpToPage(page);
    }
    await _loadSavedRecording();
  }

  Future<void> _loadSavedRecording() async {
    if (selectedSubject == null || selectedBook == null) return;
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_recordingKey);
    if (path != null && await File(path).exists()) {
      if (mounted) setState(() => _recordingPath = path);
      await _player.setFilePath(path);
      await _player.setSpeed(playbackSpeed);
    } else {
      await prefs.remove(_recordingKey);
      if (mounted) setState(() => _recordingPath = null);
    }
  }

  Future<void> _startRecording() async {
    if (selectedSubject == null || selectedBook == null) {
      _message('اختاري المادة أولاً');
      return;
    }
    if (_isPlaying) await _player.stop();
    if (!await _recorder.hasPermission()) {
      _message('لازم تسمحين للتطبيق باستخدام المايكروفون');
      return;
    }
    try {
      final directory = await getApplicationSupportDirectory();
      final safeGrade = studentGrade.replaceAll(RegExp(r'[^\w\u0600-\u06FF-]'), '_');
      final safeSubject = selectedSubject!.replaceAll(RegExp(r'[^\w\u0600-\u06FF-]'), '_');
      final safeBook = (selectedBook?.title ?? 'book').replaceAll(RegExp(r'[^\w\u0600-\u06FF-]'), '_');
      final path = '${directory.path}/lesson_${safeGrade}_${safeSubject}_${safeBook}_page_$selectedPage.m4a';
      final oldPath = _recordingPath;
      if (oldPath != null && await File(oldPath).exists()) {
        await File(oldPath).delete();
      }
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 96000, sampleRate: 44100),
        path: path,
      );
      if (mounted) {
        setState(() {
          _isRecording = true;
          _recordingPath = null;
        });
      }
    } catch (_) {
      _message('تعذر بدء التسجيل. تأكدي من صلاحية المايكروفون.');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      if (path == null || !await File(path).exists()) {
        if (mounted) setState(() => _isRecording = false);
        _message('ما تم حفظ تسجيل');
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_recordingKey, path);
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _recordingPath = path;
      });
      await _player.setFilePath(path);
      await _player.setSpeed(playbackSpeed);
      _message('انحفظ التسجيل داخل التطبيق');
    } catch (_) {
      if (mounted) setState(() => _isRecording = false);
      _message('تعذر إنهاء التسجيل');
    }
  }

  Future<void> _togglePlayback() async {
    if (_recordingPath == null) return;
    if (_isRecording) {
      _message('أوقفي التسجيل أولاً');
      return;
    }
    try {
      if (_player.playing) {
        await _player.pause();
        return;
      }
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
        _playbackSessionActive = false;
      }
      if (!_playbackSessionActive) {
        _remainingPlays = repeatCount == 0 ? -1 : repeatCount;
        if (_remainingPlays > 0) _remainingPlays--;
        _playbackSessionActive = true;
      }
      await _player.setSpeed(playbackSpeed);
      await _player.play();
    } catch (_) {
      _message('تعذر تشغيل التسجيل');
    }
  }

  Future<void> _handlePlaybackCompleted() async {
    if (!mounted || _recordingPath == null) return;
    if (_remainingPlays == -1 || _remainingPlays > 0) {
      if (_remainingPlays > 0) _remainingPlays--;
      await _player.seek(Duration.zero);
      await _player.play();
    } else {
      _playbackSessionActive = false;
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _removeRecording() async {
    if (_recordingPath == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إزالة التسجيل؟'),
        content: const Text('راح ينحذف هذا التسجيل من التطبيق نهائياً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('إزالة')),
        ],
      ),
    );
    if (confirm != true) return;
    await _player.stop();
    final path = _recordingPath!;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recordingKey);
    if (await File(path).exists()) await File(path).delete();
    if (mounted) {
      setState(() {
        _recordingPath = null;
        _isPlaying = false;
        _playbackSessionActive = false;
      });
      _message('انحذف التسجيل');
    }
  }

  Future<void> _stopAudioAndRecording() async {
    try {
      if (_isRecording) await _recorder.stop();
      await _player.stop();
    } catch (_) {}
    if (mounted) setState(() { _isRecording = false; _isPlaying = false; });
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pdfController.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF0F766E);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('قراءة الدروس بصوت الأم', style: TextStyle(fontWeight: FontWeight.bold)),
          foregroundColor: Colors.white,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
          ),
        ),
        body: studentGrade.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : availableSubjects.isEmpty
            ? const Center(child: Text('ما لكينا مواد دراسية للصف المسجل.'))
            : ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF14B8A6)]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(children: [
                Icon(Icons.headphones_rounded, size: 38, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('يلا نختار درسنا ونبدأ رحلة التعلّم! 🌟',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
              ]),
            ),
            const SizedBox(height: 16),
            const Text('1. اختاري المادة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedSubject,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'المادة'),
              items: availableSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (_isRecording || _isBusy) ? null : (value) { if (value != null) _selectSubject(value); },
            ),
            if (selectedSubject != null && availableBooks.length > 1) ...[
              const SizedBox(height: 10),
              ...availableBooks.map((book) {
                final isSelected = selectedBook?.assetPath == book.assetPath;
                final isActivity = book.title.contains('تمارين') ||
                    book.title.contains('نشاط') ||
                    book.title.contains('نشاطات');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isSelected ? const Color(0xFFE0F2F1) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: (_isRecording || _isBusy || isSelected)
                          ? null
                          : () => _selectBook(book),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE0E0E0),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isActivity ? Icons.edit_note_rounded : Icons.menu_book_rounded,
                              size: 28,
                              color: const Color(0xFF0F766E),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                book.title,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF0F766E)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
            if (selectedSubject != null) ...[
              const SizedBox(height: 14),
              const Text('2. اختاري رقم الصفحة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(
                  controller: _pageController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'رقم الصفحة', border: OutlineInputBorder()),
                  onSubmitted: _changePage,
                )),
                const SizedBox(width: 8),
                FilledButton.icon(onPressed: _isRecording ? null : () => _changePage(_pageController.text),
                    icon: const Icon(Icons.visibility), label: const Text('عرض الصفحة')),
              ]),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  Container(
                    width: double.infinity,
                    color: teal,
                    padding: const EdgeInsets.all(12),
                    child: Text('صفحة $selectedPage من ${selectedBook?.title ?? selectedSubject!}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(
                    height: 440,
                    child: _loadingPdf
                        ? const Center(child: CircularProgressIndicator())
                        : _pdfBytes == null
                        ? const Center(child: Text('اختاري المادة لعرض الصفحة'))
                        : SfPdfViewer.memory(
                      _pdfBytes!,
                      controller: _pdfController,
                      initialPageNumber: selectedPage,
                      pageLayoutMode: PdfPageLayoutMode.single,
                      enableDoubleTapZooming: true,
                      canShowScrollHead: false,
                      canShowScrollStatus: false,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              const Text('3. تسجيل صوت الأم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: _isRecording ? Colors.red.shade700 : teal),
                  onPressed: _isBusy ? null : (_isRecording ? _stopRecording : _startRecording),
                  icon: Icon(_isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded),
                  label: Text(_isRecording ? 'إيقاف التسجيل وحفظه' : (_recordingPath == null ? 'ابدئي التسجيل' : 'إعادة التسجيل')),
                ),
              ),
              if (_isRecording) ...[
                const SizedBox(height: 8),
                const Text('● جارٍ تسجيل صوت الأم…', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Text('4. الاستماع والتكرار', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 12),
                    if (_recordingPath == null)
                      const Text('بعد ما توقفين التسجيل، يظهر هنا زر تشغيل الصوت.', textAlign: TextAlign.center)
                    else ...[
                      Row(children: [
                        IconButton.filled(
                          onPressed: _togglePlayback,
                          icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                          iconSize: 30,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('تسجيل الأم محفوظ داخل التطبيق')),
                        IconButton(
                          tooltip: 'إزالة التسجيل',
                          onPressed: _isRecording ? null : _removeRecording,
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      StreamBuilder<Duration?>(
                        stream: _player.durationStream,
                        builder: (context, snapshot) {
                          final duration = snapshot.data ?? Duration.zero;
                          return StreamBuilder<Duration>(
                            stream: _player.positionStream,
                            builder: (context, positionSnapshot) {
                              final position = positionSnapshot.data ?? Duration.zero;
                              final maxMs = duration.inMilliseconds.toDouble();
                              final currentMs = position.inMilliseconds.toDouble().clamp(0.0, maxMs > 0 ? maxMs : 1.0);
                              return Column(children: [
                                Slider(
                                  value: currentMs,
                                  max: maxMs > 0 ? maxMs : 1,
                                  onChanged: duration == Duration.zero ? null : (value) => _player.seek(Duration(milliseconds: value.round())),
                                ),
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Text(_formatDuration(position), style: const TextStyle(fontSize: 12)),
                                  Text(_formatDuration(duration), style: const TextStyle(fontSize: 12)),
                                ]),
                              ]);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.speed_rounded),
                        const SizedBox(width: 8),
                        const Text('سرعة الصوت'),
                        const Spacer(),
                        DropdownButton<double>(
                          value: playbackSpeed,
                          items: const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                              .map((v) => DropdownMenuItem(value: v, child: Text('${v}×'))).toList(),
                          onChanged: (value) async {
                            if (value == null) return;
                            setState(() => playbackSpeed = value);
                            await _player.setSpeed(value);
                          },
                        ),
                      ]),
                      Row(children: [
                        const Icon(Icons.repeat_rounded),
                        const SizedBox(width: 8),
                        const Text('تكرار التسجيل'),
                        const Spacer(),
                        DropdownButton<int>(
                          value: repeatCount,
                          items: const [1, 2, 3, 5, 0].map((v) => DropdownMenuItem(
                            value: v, child: Text(v == 0 ? 'مستمر' : '$v ${v == 1 ? 'مرة' : 'مرات'}'),
                          )).toList(),
                          onChanged: (value) => setState(() => repeatCount = value ?? 1),
                        ),
                      ]),
                    ],
                  ]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
