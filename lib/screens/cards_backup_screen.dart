import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:upgrade/controllers/api_controller.dart';
import 'package:upgrade/resources.dart';

/// Admin only: save a backup of all decks + cards to a file, or restore one.
/// Restore never deletes anything and keeps ids, so users' progress stays valid.
class CardsBackupScreen extends StatefulWidget {
  const CardsBackupScreen({super.key});

  @override
  State<CardsBackupScreen> createState() => _CardsBackupScreenState();
}

class _CardsBackupScreenState extends State<CardsBackupScreen> {
  bool _busy = false;
  bool _includePersonal = false;
  bool _overwrite = false;
  String _result = '';

  Future<void> _export() async {
    setState(() {
      _busy = true;
      _result = '';
    });
    final raw = await ApiController.exportCardsBackup(includePersonal: _includePersonal);
    if (raw == null) {
      setState(() {
        _busy = false;
        _result = '❌ تعذّر إنشاء النسخة (تأكد أنك مدير وأن الخادم محدَّث).';
      });
      return;
    }
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final counts = j['counts'] as Map<String, dynamic>?;
      final dir = await getTemporaryDirectory();
      final day = DateTime.now().toIso8601String().substring(0, 10);
      final file = File('${dir.path}/mozaik-cards-$day.json');
      await file.writeAsString(raw);
      setState(() => _result =
          '✅ تم إنشاء النسخة: ${counts?['decks'] ?? '?'} مجموعة، ${counts?['cards'] ?? '?'} بطاقة.\nاختر مكان الحفظ من نافذة المشاركة (Drive، تيليجرام، الملفات...).');
      await Share.shareXFiles([XFile(file.path)], subject: 'Mozaik cards backup');
    } catch (e) {
      setState(() => _result = '❌ فشل حفظ الملف: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );
    final path = picked?.files.firstOrNull?.path;
    if (path == null) return;

    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('استعادة النسخة الاحتياطية'),
          content: Text(_overwrite
              ? 'سيُعاد ضبط أي مجموعة/بطاقة موجودة (بنفس الرقم) إلى قيمتها في النسخة، وتُضاف المفقودة. لن يُحذف شيء.'
              : 'ستُضاف المجموعات والبطاقات المفقودة فقط، ولن يتغير أي شيء موجود. لن يُحذف شيء.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('استعادة')),
          ],
        ),
      ),
    );
    if (ok != true) return;

    setState(() {
      _busy = true;
      _result = '';
    });
    try {
      final r = await ApiController.restoreCardsBackup(
        await File(path).readAsString(),
        overwrite: _overwrite,
      );
      if (r == null) {
        setState(() => _result = '❌ فشلت الاستعادة (ملف غير صالح أو الخادم لا يستجيب).');
      } else {
        final s = r['summary'] as Map<String, dynamic>;
        String line(String k) {
          final m = s[k] as Map<String, dynamic>;
          return '$k: +${m['created'] ?? 0}'
              '${m.containsKey('updated') ? '  ↻${m['updated']}' : ''}'
              '  =${m['existing'] ?? 0}';
        }
        final failed = (r['failed_count'] ?? 0) as int;
        setState(() => _result =
            '✅ اكتملت الاستعادة\n(+ أُضيف   ↻ حُدِّث   = موجود مسبقًا)\n${line('decks')}\n${line('cards')}\n${line('media')}'
            '${failed > 0 ? '\n⚠️ تعذّر استعادة $failed عنصر: ${(r['failed'] as List).take(3).map((f) => '${f['kind']} ${f['id']} (${f['reason']})').join('، ')}' : ''}');
      }
    } catch (e) {
      setState(() => _result = '❌ خطأ: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('النسخ الاحتياطي للبطاقات')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _card('حفظ نسخة', [
              const Text(
                'يحفظ كل المجموعات والبطاقات في ملف واحد (JSON). لا يشمل تقدّم المستخدمين، ولا ملفات الصور نفسها (فقط أسماؤها).',
                style: TextStyle(fontSize: 12.5, height: 1.5),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تضمين مجموعات المستخدمين الشخصية'),
                value: _includePersonal,
                onChanged: _busy ? null : (v) => setState(() => _includePersonal = v),
              ),
              _btn('إنشاء نسخة احتياطية الآن', _busy ? null : _export),
            ]),
            _card('استعادة نسخة', [
              const Text(
                'اختر ملف نسخة سابقة. لا يحذف الاستعادة أي شيء، وتحافظ على أرقام البطاقات فلا يضيع تقدّم أحد.',
                style: TextStyle(fontSize: 12.5, height: 1.5),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('استبدال الموجود بقيمة النسخة'),
                subtitle: const Text('بدونه: تُضاف المفقودة فقط', style: TextStyle(fontSize: 11.5)),
                value: _overwrite,
                onChanged: _busy ? null : (v) => setState(() => _overwrite = v),
              ),
              _btn('اختيار ملف واستعادته', _busy ? null : _restore),
            ]),
            if (_busy) const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
            if (_result.isNotEmpty) _card('النتيجة', [Text(_result, style: const TextStyle(fontSize: 12.5, height: 1.6))]),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, List<Widget> children) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColor.surfaceColor, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      );

  Widget _btn(String label, VoidCallback? onTap) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(foregroundColor: AppColor.greenColor),
          child: Text(label),
        ),
      );
}
