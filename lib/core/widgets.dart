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
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
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
    this.radius = 20,
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
            color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
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
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: context.theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!,
                  style: TextStyle(
                      color: context.brand,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconBadge(this.icon, this.color, {super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.22 : 0.13),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(20),
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
                  color: color, fontSize: 11.5, fontWeight: FontWeight.w800)),
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
              fontWeight: FontWeight.w800,
              fontSize: radius * 0.85)),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const EmptyState(this.icon, this.title, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                  color: context.brandSoft, shape: BoxShape.circle),
              child: Icon(icon, size: 38, color: context.brand),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: context.theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.muted)),
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
      ..color = color.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.07)
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
      ..color = color.withValues(alpha: 0.08)
      ..strokeWidth = 2;
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors ??
              const [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        child: CustomPaint(
          painter: BioPatternPainter(Colors.white),
          child: SafeArea(
            bottom: false,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon, color, size: 38),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.muted, fontSize: 12.5)),
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
                  color: v == selected ? Colors.white : context.ink,
                ),
                selectedColor: context.cs.primary,
                backgroundColor: context.card,
                side: BorderSide(
                    color: v == selected ? context.cs.primary : context.line),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 6),
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
