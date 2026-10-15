import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'l10n.dart';
import 'theme.dart';

void toast(BuildContext c, String msg) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

Future<T?> go<T>(BuildContext c, Widget page) =>
    Navigator.push<T>(c, MaterialPageRoute(builder: (_) => page));

Future<T?> showSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.card,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: ctx.line, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            builder(ctx),
          ],
        ),
      ),
    ),
  );
}

Future<bool> confirm(BuildContext context, String title, String body,
    {String? ok}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      content: Text(body),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('إلغاء', 'Cancel'))),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ok ?? ctx.tr('تأكيد', 'Confirm')),
        ),
      ],
    ),
  );
  return r ?? false;
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final double radius;
  final bool border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.color,
    this.gradient,
    this.radius = 18,
    this.border = true,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? context.card) : null,
        gradient: gradient,
        borderRadius: r,
        border: border ? Border.all(color: context.line) : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2A23)
                .withValues(alpha: context.isDark ? 0.30 : 0.045),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 28, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: context.theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.1)),
          ),
          if (action != null)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(action!,
                    style: TextStyle(
                        color: context.brand,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Maps any accent to one of four curated tones so icons read as one family:
/// brand teal, gold, indigo and terracotta.
Color toneOf(BuildContext context, Color c) {
  final h = HSLColor.fromColor(c).hue;
  final dark = context.isDark;
  if (h >= 85 && h < 195) return dark ? const Color(0xFF4FC29B) : AppColors.primary;
  if (h >= 20 && h < 85) return dark ? const Color(0xFFE2B04A) : const Color(0xFFB8821F);
  if (h >= 195 && h < 290) return dark ? const Color(0xFF8394E0) : const Color(0xFF4A5FB0);
  return dark ? const Color(0xFFE48479) : const Color(0xFFB9574B);
}

class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconBadge(this.icon, this.color, {super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final c = toneOf(context, color);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withValues(alpha: context.isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(size * 0.30),
      ),
      child: Icon(icon, color: c, size: size * 0.48),
    );
  }
}

class Pill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const Pill(this.label, this.color, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.22 : 0.11),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final String text;
  final Color color;
  final double radius;
  const Avatar(this.text, this.color, {super.key, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(text,
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: radius * 0.85)),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState(this.icon, this.title,
      {super.key, this.subtitle, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                  color: context.brandSoft, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: context.brand),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: context.theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.muted, height: 1.5)),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                    minimumSize: const Size(160, 48)),
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Donut progress indicator.
class ProgressRing extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final double size;
  final double stroke;
  final Widget? child;
  const ProgressRing(
      {super.key,
      required this.value,
      required this.color,
      this.size = 84,
      this.stroke = 9,
      this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(value.clamp(0, 1).toDouble(), color,
            context.line, stroke),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v;
  final Color color;
  final Color track;
  final double stroke;
  _RingPainter(this.v, this.color, this.track, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, math.pi * 2, false, p..color = track);
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * v, false, p..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.v != v || o.color != color || o.track != track;
}

/// Decorative biology pattern: cells and a DNA helix.
class BioPatternPainter extends CustomPainter {
  final Color color;
  BioPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.045)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.2), 46, fill);
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.2), 22, stroke);
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.95), 60, fill);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.1), 14, stroke);

    // DNA helix
    final x0 = size.width * 0.86;
    final h = size.height;
    final a = Path();
    final b = Path();
    for (double t = 0; t <= 1.0001; t += 0.02) {
      final y = h * t;
      final dx = math.sin(t * math.pi * 4) * 20;
      if (t == 0) {
        a.moveTo(x0 + dx, y);
        b.moveTo(x0 - dx, y);
      } else {
        a.lineTo(x0 + dx, y);
        b.lineTo(x0 - dx, y);
      }
    }
    canvas.drawPath(a, stroke);
    canvas.drawPath(b, stroke);
    final rung = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..strokeWidth = 1.6;
    for (double t = 0.04; t < 1; t += 0.06) {
      final y = h * t;
      final dx = math.sin(t * math.pi * 4) * 20;
      canvas.drawLine(Offset(x0 + dx, y), Offset(x0 - dx, y), rung);
    }
  }

  @override
  bool shouldRepaint(BioPatternPainter o) => o.color != color;
}

class HeroHeader extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final List<Color>? colors;
  const HeroHeader(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 28),
      this.colors});

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(bottom: Radius.circular(30));
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors ?? const [Color(0xFF0D7561), AppColors.primaryDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // soft light from the top corner
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.9, -1.2),
                    radius: 1.1,
                    colors: [
                      Colors.white.withValues(alpha: 0.14),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: BioPatternPainter(Colors.white)),
            ),
            SafeArea(
              bottom: false,
              child: Padding(padding: padding, child: child),
            ),
          ],
        ),
      ),
    );
  }
}

/// Translucent stat tile used in hero headers.
class HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback onTap;
  const HeroStat(
      {super.key, required this.value, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.white.withValues(alpha: 0.11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(children: [
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()])),
                const SizedBox(height: 4),
                Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82), fontSize: 12)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades and slides a child in once; use [index] to stagger lists.
class Reveal extends StatelessWidget {
  final Widget child;
  final int index;
  const Reveal({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index * 55),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 14), child: c),
      ),
      child: child,
    );
  }
}

/// A small stat card (icon, big number, caption).
class StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final VoidCallback? onTap;
  const StatCard(
      {super.key,
      required this.icon,
      required this.color,
      required this.value,
      required this.label,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon, color, size: 38),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()])),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Segmented chip selector.
class ChipSelector<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  const ChipSelector(
      {super.key,
      required this.values,
      required this.selected,
      required this.label,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final v in values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(label(v)),
                selected: v == selected,
                showCheckmark: false,
                onSelected: (_) => onChanged(v),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: v == selected ? Colors.white : context.ink,
                ),
                selectedColor: context.cs.primary,
                backgroundColor: context.card,
                side: BorderSide(
                    color: v == selected ? context.cs.primary : context.line),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Standard page scaffold with a clean app bar.
class PageScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? fab;
  final PreferredSizeWidget? bottom;
  const PageScaffold(
      {super.key,
      required this.title,
      required this.body,
      this.actions,
      this.fab,
      this.bottom});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions, bottom: bottom),
      floatingActionButton: fab,
      body: body,
    );
  }
}

class LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboard;
  final String? hint;
  final IconData? icon;
  const LabeledField(this.label, this.controller,
      {super.key, this.maxLines = 1, this.keyboard, this.hint, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboard,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: icon == null ? null : Icon(icon, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

/// One-shot confetti burst. Wrap a screen in a [Stack] and add this on top.
class Confetti extends StatefulWidget {
  const Confetti({super.key});

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2600))
    ..forward();
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    final r = math.Random(7);
    const palette = [
      AppColors.leaf,
      AppColors.gold,
      AppColors.sky,
      AppColors.coral,
      AppColors.primary,
      Color(0xFFFFFFFF),
    ];
    _pieces = List.generate(
        44,
        (i) => _Piece(
              x: 0.5 + (r.nextDouble() - 0.5) * 0.2,
              vx: (r.nextDouble() - 0.5) * 1.5,
              vy: -(0.6 + r.nextDouble() * 0.9),
              size: 5 + r.nextDouble() * 6,
              spin: r.nextDouble() * 8,
              color: palette[i % palette.length],
              round: r.nextBool(),
            ));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_pieces, _c.value),
        ),
      ),
    );
  }
}

class _Piece {
  final double x, vx, vy, size, spin;
  final Color color;
  final bool round;
  _Piece(
      {required this.x,
      required this.vx,
      required this.vy,
      required this.size,
      required this.spin,
      required this.color,
      required this.round});
}

class _ConfettiPainter extends CustomPainter {
  final List<_Piece> pieces;
  final double t;
  _ConfettiPainter(this.pieces, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final fade = t < 0.75 ? 1.0 : (1 - t) / 0.25;
    for (final p in pieces) {
      final dx = size.width * (p.x + p.vx * t * 0.6);
      final dy = size.height * (0.32 + p.vy * t * 0.5 + 0.9 * t * t);
      final paint = Paint()..color = p.color.withValues(alpha: fade.clamp(0, 1));
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.spin * t);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
                const Radius.circular(2)),
            paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter o) => o.t != t;
}

/// Celebration dialog: bouncing check, confetti, a warm message and one clear
/// next step.
Future<void> showSuccess(BuildContext context,
    {required String title,
    required String message,
    String? ctaLabel,
    VoidCallback? onCta,
    bool confetti = true}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            decoration: BoxDecoration(
              color: ctx.card,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  builder: (_, v, c) => Transform.scale(scale: v, child: c),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.leaf.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.leaf.withValues(alpha: 0.30),
                            blurRadius: 24,
                            spreadRadius: 2),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppColors.leaf, size: 44),
                  ),
                ),
                const SizedBox(height: 24),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ctx.muted, height: 1.5)),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onCta?.call();
                  },
                  child: Text(ctaLabel ?? ctx.tr('متابعة', 'Continue')),
                ),
              ],
            ),
          ),
          if (confetti) const Positioned.fill(child: Confetti()),
        ],
      ),
    ),
  );
}

/// Recent + popular search chips shown under an empty search field.
class SearchSuggestions extends StatelessWidget {
  final List<String> recent;
  final List<String> popular;
  final ValueChanged<String> onPick;
  const SearchSuggestions(
      {super.key, required this.recent, required this.popular, required this.onPick});

  @override
  Widget build(BuildContext context) {
    Widget group(String label, IconData icon, List<String> items) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 16, color: context.muted),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 12, color: context.muted)),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in items)
                ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  onPressed: () => onPick(s),
                  backgroundColor: context.card,
                  side: BorderSide(color: context.line),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
            ]),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recent.isNotEmpty)
          group(context.tr('عمليات بحث سابقة', 'Recent'), Icons.history_rounded, recent),
        group(context.tr('الأكثر بحثاً', 'Popular'), Icons.trending_up_rounded, popular),
      ],
    );
  }
}
