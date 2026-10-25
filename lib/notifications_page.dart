import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const String currentAppVersion = '1.0.0+3';

  bool loading = true;

  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final list = <Map<String, dynamic>>[];

    // ============================================================
    // 1) فحص تحديث التطبيق
    // ============================================================

    try {
      final response = await http
          .get(
        Uri.parse(
          'https://sahnaha-server.vercel.app/api/update',
        ),
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final latestVersion =
            data['latestVersion']?.toString() ?? '';

        final downloadUrl =
            data['downloadUrl']?.toString() ?? '';

        if (latestVersion.isNotEmpty &&
            downloadUrl.isNotEmpty &&
            latestVersion != currentAppVersion) {
          list.add({
            'icon': Icons.system_update_rounded,
            'title': 'تحديث جديد للتطبيق',
            'message':
            'أكو إصدار جديد $latestVersion متوفر للمصحح الذكي.',
            'color': Colors.blue,
            'action': downloadUrl,
          });
        }
      }
    } catch (_) {
      // إذا ماكو إنترنت، باقي الإشعارات تشتغل طبيعي.
    }

    // ============================================================
    // 2) تذكير الدراسة
    // ============================================================

    final prefs = await SharedPreferences.getInstance();

    final subject =
    prefs.getString('study_alarm_subject');

    final hour =
    prefs.getInt('study_alarm_hour');

    final minute =
    prefs.getInt('study_alarm_minute');

    if (subject != null &&
        subject.isNotEmpty &&
        hour != null &&
        minute != null) {
      final time =
          '${hour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')}';

      list.add({
        'icon': Icons.menu_book_rounded,
        'title': 'تذكير بالدراسة',
        'message':
        'منبّه الدراسة مضبوط على مادة $subject الساعة $time.',
        'color': Colors.green,
      });
    }

    // ============================================================
    // 3) الاختبارات
    // ============================================================
    //
    // إذا أضفنا لاحقًا نظام اختبارات محفوظ بالتطبيق،
    // راح تظهر هنا تلقائيًا.
    //
    // حاليًا ما راح نعرض اختبار وهمي للطالب.
    //

    final examTitle =
    prefs.getString('next_exam_title');

    final examSubject =
    prefs.getString('next_exam_subject');

    final examDate =
    prefs.getString('next_exam_date');

    if (examTitle != null &&
        examTitle.isNotEmpty) {
      String message = examTitle;

      if (examSubject != null &&
          examSubject.isNotEmpty) {
        message += ' - المادة: $examSubject';
      }

      if (examDate != null &&
          examDate.isNotEmpty) {
        message += '\nالموعد: $examDate';
      }

      list.add({
        'icon': Icons.assignment_rounded,
        'title': 'تنبيه اختبار',
        'message': message,
        'color': Colors.orange,
      });
    }

    // ============================================================
    // 4) إعلان التطبيق
    // ============================================================

    list.add({
      'icon': Icons.school_rounded,
      'title': 'إعلان من التطبيق',
      'message':
      'نتمنى لك دراسة موفقة ونجاح دائم 🌷',
      'color': Colors.purple,
    });

    if (!mounted) return;

    setState(() {
      notifications = list;
      loading = false;
    });
  }

  Future<void> _openUpdate(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) return;

    try {
      await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر فتح رابط التحديث',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'الإشعارات',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: loading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : notifications.isEmpty
            ? const Center(
          child: Text(
            'ماكو إشعارات حالياً 🔔',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
            : RefreshIndicator(
          onRefresh: _loadNotifications,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            itemBuilder: (
                context,
                index,
                ) {
              final notification =
              notifications[index];

              final color =
              notification['color'] as Color;

              final action =
              notification['action']
                  ?.toString();

              return Card(
                margin:
                const EdgeInsets.only(
                  bottom: 12,
                ),
                elevation: 2,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius:
                  BorderRadius.circular(16),
                  onTap: action != null
                      ? () => _openUpdate(action)
                      : null,
                  child: Padding(
                    padding:
                    const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration:
                          BoxDecoration(
                            color: color.withValues(
                              alpha: 0.12,
                            ),
                            shape:
                            BoxShape.circle,
                          ),
                          child: Icon(
                            notification['icon']
                            as IconData,
                            color: color,
                            size: 28,
                          ),
                        ),
                        const SizedBox(
                          width: 14,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              Text(
                                notification[
                                'title'] as String,
                                style:
                                const TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              Text(
                                notification[
                                'message'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors
                                      .grey
                                      .shade700,
                                  height: 1.5,
                                ),
                              ),
                              if (action != null)
                                const Padding(
                                  padding:
                                  EdgeInsets.only(
                                    top: 8,
                                  ),
                                  child: Text(
                                    'اضغط هنا للتحديث',
                                    style:
                                    TextStyle(
                                      color:
                                      Colors.blue,
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (action != null)
                          const Icon(
                            Icons
                                .arrow_forward_ios_rounded,
                            size: 18,
                            color: Colors.grey,
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