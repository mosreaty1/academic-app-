import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import 'subscription_screen.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  int? _grade;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final teacher = s.me!.role == UserRole.teacher;
    final sid = teacher ? null : s.activeStudentId;
    final grade = teacher ? _grade : s.user(sid!).grade;
    final list = s.lessons
        .where((l) => grade == null || l.grade == grade)
        .toList()
      ..sort((a, b) {
        final g = a.grade.compareTo(b.grade);
        return g != 0 ? g : a.order.compareTo(b.order);
      });

    // group by chapter, keeping order
    final groups = <String, List<Lesson>>{};
    for (final l in list) {
      groups.putIfAbsent('${l.grade}|${l.chapter.en}', () => []).add(l);
    }

    final sub = sid == null ? null : s.subscriptionOf(sid);
    final active = sub?.active ?? false;
    final watched = sid == null
        ? 0
        : list.where((l) => s.progressOf(sid, l.id) >= 0.9).length;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('الدروس', 'Video lessons'))),
      floatingActionButton: teacher
          ? FloatingActionButton.extended(
              onPressed: () => showSheet(context, (_) => const _AddLessonForm()),
              icon: const Icon(Icons.video_call_rounded),
              label: Text(context.tr('درس جديد', 'New lesson')),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 92),
        children: [
          if (!teacher)
            AppCard(
              onTap: () => go(context, SubscriptionScreen(studentId: sid!)),
              gradient: LinearGradient(
                colors: active
                    ? const [AppColors.primary, AppColors.primaryDark]
                    : const [AppColors.amber, Color(0xFFD9822B)],
              ),
              border: false,
              child: Row(children: [
                Icon(active ? Icons.workspace_premium_rounded : Icons.lock_open_rounded,
                    color: Colors.white, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          active
                              ? context.tr('اشتراكك فعّال', 'Your subscription is active')
                              : context.tr('افتح كل الدروس', 'Unlock all lessons'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(
                          active
                              ? context.tr('متبقي ${sub!.daysLeft} يوم • $watched/${list.length} درس مكتمل',
                                  '${sub.daysLeft} days left • $watched/${list.length} lessons done')
                              : context.tr('اشترك أو فعّل كود لمشاهدة الدروس المدفوعة',
                                  'Subscribe or enter a code to watch premium lessons'),
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ]),
            ),
          if (teacher) ...[
            ChipSelector<int?>(
              values: const [null, 1, 2, 3],
              selected: _grade,
              label: (g) => g == null ? context.tr('كل الصفوف', 'All grades') : gradeShort(context, g),
              onChanged: (g) => setState(() => _grade = g),
            ),
          ],
          if (list.isEmpty)
            EmptyState(Icons.ondemand_video_rounded,
                context.tr('لا توجد دروس بعد', 'No lessons yet'),
                subtitle: teacher
                    ? context.tr('ارفع أول درس فيديو ليراه الطلاب.', 'Publish your first video lesson for students.')
                    : context.tr('ستظهر الدروس هنا فور نشرها.', 'Lessons will appear here as soon as they are published.'),
                actionLabel: teacher ? context.tr('إضافة درس', 'Add a lesson') : null,
                onAction: () => showSheet(context, (_) => const _AddLessonForm())),
          for (final e in groups.entries) ...[
            SectionHeader(
                '${teacher ? '${gradeShort(context, e.value.first.grade)} • ' : ''}${e.value.first.chapter.of(context)}'),
            for (final l in e.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LessonCard(lesson: l, studentId: sid, teacher: teacher),
              ),
          ],
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final String? studentId;
  final bool teacher;
  const _LessonCard(
      {required this.lesson, required this.studentId, required this.teacher});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final locked = !teacher && !s.canWatch(studentId!, lesson);
    final progress = teacher ? 0.0 : s.progressOf(studentId!, lesson.id);
    final done = progress >= 0.9;

    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () {
        if (locked) {
          showSheet(context, (_) => _PaywallSheet(studentId: studentId!));
        } else {
          go(context, LessonPlayerScreen(lessonId: lesson.id, studentId: studentId));
        }
      },
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 100,
            height: 68,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: locked
                            ? const [Color(0xFF4A5753), Color(0xFF2E3835)]
                            : const [Color(0xFF0D7561), Color(0xFF063F34)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                  ),
                  child: CustomPaint(painter: BioPatternPainter(Colors.white)),
                ),
                Center(
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5))),
                    child: Icon(
                        locked
                            ? Icons.lock_rounded
                            : done
                                ? Icons.check_rounded
                                : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20),
                  ),
                ),
                PositionedDirectional(
                  end: 5,
                  bottom: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(5)),
                    child: Text('${lesson.minutes}:00',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()])),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lesson.title.of(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.schedule_rounded, size: 13, color: context.muted),
                    const SizedBox(width: 4),
                    Text('${lesson.minutes} ${context.tr('د', 'min')}',
                        style: TextStyle(color: context.muted, fontSize: 12)),
                  ]),
                  lesson.premium
                      ? Pill(context.tr('مدفوع', 'Premium'), AppColors.amber,
                          icon: Icons.workspace_premium_rounded)
                      : Pill(context.tr('مجاني', 'Free'), AppColors.leaf),
                ],
              ),
              if (!teacher && progress > 0 && !locked) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      color: AppColors.leaf,
                      backgroundColor: context.line),
                ),
              ],
            ],
          ),
        ),
        if (teacher)
          IconButton(
            tooltip: context.tr('حذف', 'Delete'),
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral),
            onPressed: () async {
              final ok = await confirm(
                  context,
                  context.tr('حذف الدرس؟', 'Delete lesson?'),
                  lesson.title.of(context));
              if (ok) s.removeLesson(lesson.id);
            },
          ),
      ]),
    );
  }
}

class _PaywallSheet extends StatelessWidget {
  final String studentId;
  const _PaywallSheet({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.lock_rounded, size: 46, color: AppColors.amber),
        const SizedBox(height: 12),
        Text(context.tr('هذا الدرس للمشتركين', 'This lesson is for subscribers'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
            context.tr('اشترك الآن أو فعّل كود الاشتراك لمشاهدة كل الدروس.',
                'Subscribe now or redeem a code to watch every lesson.'),
            textAlign: TextAlign.center,
            style: TextStyle(color: context.muted, height: 1.5)),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            go(context, SubscriptionScreen(studentId: studentId));
          },
          child: Text(context.tr('عرض خطط الاشتراك', 'View subscription plans')),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------- player ----

class LessonPlayerScreen extends StatefulWidget {
  final String lessonId;
  final String? studentId; // null for teachers (no progress tracking)
  const LessonPlayerScreen({super.key, required this.lessonId, this.studentId});

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  VideoPlayerController? _c;
  bool _failed = false;
  bool _ready = false;
  double _speed = 1;
  late final AppState _state;
  late final Lesson _lesson;

  @override
  void initState() {
    super.initState();
    _state = context.read<AppState>();
    _lesson = _state.lessons.firstWhere((l) => l.id == widget.lessonId);
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(_lesson.videoUrl));
      _c = c;
      await c.initialize();
      c.addListener(_onTick);
      if (!mounted) return;
      setState(() => _ready = true);
      c.play();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _onTick() {
    final c = _c;
    if (c == null || !c.value.isInitialized) return;
    final d = c.value.duration.inMilliseconds;
    if (d > 0 && widget.studentId != null) {
      final f = c.value.position.inMilliseconds / d;
      // Persist in coarse steps to avoid spamming the backend.
      final cur = _state.progressOf(widget.studentId!, _lesson.id);
      if (f - cur >= 0.1 || f >= 0.95 && cur < 0.95) {
        _state.setLessonProgress(widget.studentId!, _lesson.id, f);
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c?.removeListener(_onTick);
    _c?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final next = _state.lessonsOfGrade(_lesson.grade);
    final idx = next.indexWhere((l) => l.id == _lesson.id);
    final nextLesson = idx >= 0 && idx < next.length - 1 ? next[idx + 1] : null;

    return Scaffold(
      appBar: AppBar(title: Text(_lesson.title.of(context), style: const TextStyle(fontSize: 18))),
      body: ListView(
        children: [
          Container(
            color: Colors.black,
            child: AspectRatio(
              aspectRatio: _ready ? c!.value.aspectRatio : 16 / 9,
              child: _failed
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 36),
                            const SizedBox(height: 8),
                            Text(
                                context.tr('تعذر تشغيل الفيديو. تحقق من الإنترنت.',
                                    'Could not play the video. Check your connection.'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70)),
                            TextButton(
                              onPressed: () {
                                setState(() => _failed = false);
                                _init();
                              },
                              child: Text(context.tr('إعادة المحاولة', 'Retry')),
                            ),
                          ],
                        ),
                      ),
                    )
                  : !_ready
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : GestureDetector(
                          onTap: () => c.value.isPlaying ? c.pause() : c.play(),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              VideoPlayer(c!),
                              if (!c.value.isPlaying)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                      color: Colors.black45, shape: BoxShape.circle),
                                  child: const Icon(Icons.play_arrow_rounded,
                                      color: Colors.white, size: 44),
                                ),
                            ],
                          ),
                        ),
            ),
          ),
          if (_ready)
            Container(
              color: Colors.black,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Column(children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
                  child: Slider(
                    value: c!.value.position.inMilliseconds
                        .clamp(0, c.value.duration.inMilliseconds)
                        .toDouble(),
                    max: c.value.duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                    onChanged: (v) => c.seekTo(Duration(milliseconds: v.round())),
                  ),
                ),
                Row(children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text('${_fmt(c.value.position)} / ${_fmt(c.value.duration)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => c.seekTo(c.value.position - const Duration(seconds: 10)),
                    icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () => c.value.isPlaying ? c.pause() : c.play(),
                    icon: Icon(c.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white, size: 30),
                  ),
                  IconButton(
                    onPressed: () => c.seekTo(c.value.position + const Duration(seconds: 10)),
                    icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
                  ),
                  PopupMenuButton<double>(
                    tooltip: context.tr('السرعة', 'Speed'),
                    initialValue: _speed,
                    onSelected: (v) {
                      setState(() => _speed = v);
                      c.setPlaybackSpeed(v);
                    },
                    itemBuilder: (_) => [
                      for (final v in const [0.75, 1.0, 1.25, 1.5, 2.0])
                        PopupMenuItem(value: v, child: Text('${v}x')),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('${_speed}x',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_lesson.title.of(context),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  Pill(_lesson.chapter.of(context), AppColors.primary),
                  Pill('${_lesson.minutes} ${context.tr('دقيقة', 'min')}', AppColors.sky),
                  Pill(gradeShort(context, _lesson.grade), AppColors.violet),
                ]),
                const SizedBox(height: 16),
                Text(_lesson.description.of(context), style: const TextStyle(height: 1.6)),
                if (nextLesson != null) ...[
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () {
                      if (widget.studentId != null &&
                          !_state.canWatch(widget.studentId!, nextLesson)) {
                        showSheet(context, (_) => _PaywallSheet(studentId: widget.studentId!));
                        return;
                      }
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => LessonPlayerScreen(
                                  lessonId: nextLesson.id, studentId: widget.studentId)));
                    },
                    icon: const Icon(Icons.skip_next_rounded),
                    label: Text(context.tr('الدرس التالي: ${nextLesson.title.ar}',
                        'Next: ${nextLesson.title.en}')),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------- teacher form --

class _AddLessonForm extends StatefulWidget {
  const _AddLessonForm();

  @override
  State<_AddLessonForm> createState() => _AddLessonFormState();
}

class _AddLessonFormState extends State<_AddLessonForm> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _url = TextEditingController();
  final _min = TextEditingController(text: '20');
  int _grade = 1;
  Bi? _chapter;
  bool _premium = true;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _url.dispose();
    _min.dispose();
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
        Text(context.tr('إضافة درس فيديو', 'Add a video lesson'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        LabeledField(context.tr('عنوان الدرس', 'Lesson title'), _title),
        LabeledField(context.tr('الوصف', 'Description'), _desc, maxLines: 2),
        LabeledField(context.tr('رابط الفيديو (mp4 / m3u8)', 'Video URL (mp4 / m3u8)'), _url,
            keyboard: TextInputType.url, hint: 'https://...'),
        ChipSelector<int>(
          values: const [1, 2, 3],
          selected: _grade,
          label: (g) => gradeShort(context, g),
          onChanged: (g) => setState(() => _grade = g),
        ),
        const SizedBox(height: 12),
        if (chapters.isNotEmpty)
          ChipSelector<String>(
            values: chapters.map((c) => c.en).toList(),
            selected: _chapter!.en,
            label: (en) => chapters.firstWhere((c) => c.en == en).of(context),
            onChanged: (en) =>
                setState(() => _chapter = chapters.firstWhere((c) => c.en == en)),
          ),
        const SizedBox(height: 12),
        LabeledField(context.tr('المدة (دقيقة)', 'Duration (min)'), _min,
            keyboard: TextInputType.number),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _premium,
          onChanged: (v) => setState(() => _premium = v),
          title: Text(context.tr('للمشتركين فقط', 'Subscribers only')),
          subtitle: Text(context.tr('أوقفه لجعل الدرس مجانياً', 'Turn off to make it free')),
        ),
        FilledButton(
          onPressed: () {
            final t = _title.text.trim();
            final u = _url.text.trim();
            if (t.isEmpty || !u.startsWith('http') || _chapter == null) {
              toast(context, context.tr('أدخل العنوان ورابط فيديو صحيح', 'Enter a title and a valid video URL'));
              return;
            }
            final d = _desc.text.trim();
            s.addLesson(Lesson(
              id: 'l${DateTime.now().microsecondsSinceEpoch}',
              title: Bi(t, t),
              description: Bi(d, d),
              grade: _grade,
              chapter: _chapter!,
              videoUrl: u,
              minutes: int.tryParse(_min.text) ?? 20,
              premium: _premium,
              order: s.lessons.length + 1,
              added: DateTime.now(),
            ));
            Navigator.pop(context);
            toast(context, context.tr('تم نشر الدرس', 'Lesson published'));
          },
          child: Text(context.tr('نشر الدرس', 'Publish lesson')),
        ),
      ],
    );
  }
}
