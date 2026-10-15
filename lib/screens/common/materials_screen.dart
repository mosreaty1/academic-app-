import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';

/// "2.4 MB" / "18 min" / "24 slides" / "12 images" in the user's language.
String metaLabel(BuildContext c, String meta) {
  if (!c.isAr) return meta;
  final m = RegExp(r'^([\d.]+)\s+(\w+)$').firstMatch(meta);
  if (m == null) return meta;
  const units = {
    'MB': 'ميجابايت',
    'min': 'دقيقة',
    'slides': 'شريحة',
    'images': 'صورة',
  };
  return '${m.group(1)} ${units[m.group(2)] ?? m.group(2)}';
}

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  MaterialKind? _kind;
  int? _grade;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final teacher = s.me!.role == UserRole.teacher;
    final grade = teacher ? _grade : s.me!.grade;
    final list = s.materials
        .where((m) =>
            (grade == null || m.grade == grade || m.grade == 0) &&
            (_kind == null || m.kind == _kind))
        .toList()
      ..sort((a, b) => b.added.compareTo(a.added));
    final studiedCount =
        list.where((m) => s.studied.contains(m.id)).length;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('المواد التعليمية', 'Study materials'))),
      floatingActionButton: teacher
          ? FloatingActionButton.extended(
              onPressed: () => showSheet(context, (_) => const _AddMaterialForm()),
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(context.tr('رفع مادة', 'Upload')),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        children: [
          if (!teacher)
            AppCard(
              child: Row(children: [
                ProgressRing(
                  value: list.isEmpty ? 0 : studiedCount / list.length,
                  color: AppColors.violet,
                  size: 62,
                  stroke: 7,
                  child: Text('$studiedCount/${list.length}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('تقدمك في المذاكرة', 'Your study progress'),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                          context.tr('علّم المادة "تمت المذاكرة" بعد الانتهاء منها',
                              'Mark a material "studied" once you finish it'),
                          style: TextStyle(color: context.muted, fontSize: 12)),
                    ],
                  ),
                ),
              ]),
            ),
          const SizedBox(height: 12),
          if (teacher) ...[
            ChipSelector<int?>(
              values: const [null, 1, 2, 3],
              selected: _grade,
              label: (g) => g == null ? context.tr('كل الصفوف', 'All grades') : gradeShort(context, g),
              onChanged: (g) => setState(() => _grade = g),
            ),
            const SizedBox(height: 8),
          ],
          ChipSelector<MaterialKind?>(
            values: [null, ...MaterialKind.values],
            selected: _kind,
            label: (k) => k == null ? context.tr('الكل', 'All') : materialKindLabel(context, k),
            onChanged: (k) => setState(() => _kind = k),
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            EmptyState(Icons.folder_open_rounded,
                context.tr('لا توجد مواد', 'No materials found')),
          for (final m in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: () => showSheet(context, (_) => _MaterialSheet(m: m)),
                child: Row(children: [
                  IconBadge(materialIcon(m.kind), materialColor(m.kind), size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.title.of(context),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 3),
                        Text(
                            '${m.chapter.of(context)} • ${metaLabel(context, m.meta)}',
                            style: TextStyle(color: context.muted, fontSize: 12)),
                        const SizedBox(height: 3),
                        Text(
                            '${gradeShort(context, m.grade)} • ${fmtDate(context, m.added)}',
                            style: TextStyle(color: context.muted, fontSize: 11.5)),
                      ],
                    ),
                  ),
                  Column(children: [
                    if (s.studied.contains(m.id))
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.leaf, size: 22),
                    if (s.downloaded.contains(m.id))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Icon(Icons.download_done_rounded,
                            color: context.muted, size: 20),
                      ),
                  ]),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _MaterialSheet extends StatelessWidget {
  final StudyMaterial m;
  const _MaterialSheet({required this.m});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final teacher = s.me!.role == UserRole.teacher;
    final color = materialColor(m.kind);
    final downloaded = s.downloaded.contains(m.id);
    final studied = s.studied.contains(m.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.6)]),
          ),
          child: Icon(materialIcon(m.kind), size: 64, color: Colors.white),
        ),
        const SizedBox(height: 14),
        Text(m.title.of(context),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: [
          Pill(materialKindLabel(context, m.kind), color),
          Pill(m.chapter.of(context), AppColors.primary),
          Pill(metaLabel(context, m.meta), AppColors.sky),
        ]),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            toast(
                context,
                m.kind == MaterialKind.video
                    ? context.tr('جارٍ تشغيل الفيديو...', 'Playing video...')
                    : context.tr('جارٍ فتح الملف...', 'Opening file...'));
          },
          icon: Icon(m.kind == MaterialKind.video
              ? Icons.play_arrow_rounded
              : Icons.open_in_new_rounded),
          label: Text(m.kind == MaterialKind.video
              ? context.tr('تشغيل', 'Play')
              : context.tr('فتح', 'Open')),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => s.toggleDownloaded(m.id),
              icon: Icon(downloaded ? Icons.download_done_rounded : Icons.download_rounded),
              label: Text(downloaded
                  ? context.tr('محفوظ', 'Saved offline')
                  : context.tr('تحميل', 'Download')),
            ),
          ),
          if (!teacher) ...[
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => s.toggleStudied(m.id),
                icon: Icon(studied ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded),
                label: Text(studied
                    ? context.tr('تمت المذاكرة', 'Studied')
                    : context.tr('تمت المذاكرة؟', 'Mark studied')),
              ),
            ),
          ],
        ]),
      ],
    );
  }
}

class _AddMaterialForm extends StatefulWidget {
  const _AddMaterialForm();

  @override
  State<_AddMaterialForm> createState() => _AddMaterialFormState();
}

class _AddMaterialFormState extends State<_AddMaterialForm> {
  final _title = TextEditingController();
  int _grade = 1;
  MaterialKind _kind = MaterialKind.pdf;
  Bi? _chapter;
  bool _picked = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final chapters = s.chaptersOf(_grade);
    if (_chapter == null || !chapters.any((c) => c.en == _chapter!.en)) {
      _chapter = chapters.isEmpty ? null : chapters.first;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('رفع مادة تعليمية', 'Upload study material'),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        LabeledField(context.tr('العنوان', 'Title'), _title),
        ChipSelector<int>(
          values: const [1, 2, 3],
          selected: _grade,
          label: (g) => gradeShort(context, g),
          onChanged: (g) => setState(() => _grade = g),
        ),
        const SizedBox(height: 10),
        if (chapters.isNotEmpty)
          ChipSelector<String>(
            values: chapters.map((c) => c.en).toList(),
            selected: _chapter!.en,
            label: (en) => chapters.firstWhere((c) => c.en == en).of(context),
            onChanged: (en) =>
                setState(() => _chapter = chapters.firstWhere((c) => c.en == en)),
          ),
        const SizedBox(height: 10),
        ChipSelector<MaterialKind>(
          values: MaterialKind.values,
          selected: _kind,
          label: (k) => materialKindLabel(context, k),
          onChanged: (k) => setState(() => _kind = k),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => setState(() => _picked = !_picked),
          icon: Icon(_picked ? Icons.check_circle_rounded : Icons.attach_file_rounded),
          label: Text(_picked
              ? context.tr('تم اختيار الملف', 'File selected')
              : context.tr('اختيار ملف من الجهاز', 'Choose file from device')),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () {
            if (_title.text.trim().isEmpty || _chapter == null) {
              toast(context, context.tr('اكتب عنوان المادة', 'Enter a title'));
              return;
            }
            final t = _title.text.trim();
            s.addMaterial(StudyMaterial(
              id: 'm${DateTime.now().microsecondsSinceEpoch}',
              title: Bi(t, t),
              kind: _kind,
              grade: _grade,
              chapter: _chapter!,
              meta: _kind == MaterialKind.video ? '12 min' : '1.2 MB',
              added: DateTime.now(),
            ));
            Navigator.pop(context);
            toast(context, context.tr('تم رفع المادة للطلاب', 'Material published to students'));
          },
          child: Text(context.tr('نشر', 'Publish')),
        ),
      ],
    );
  }
}
