import 'package:flutter/material.dart';

import '../../core/models/money.dart';
import '../icons.dart';
import '../theme.dart';
import '../tokens.dart';
import '../typography.dart';

/// Page body with the standard gutter, centered and capped on tablets.
class PageBody extends StatelessWidget {
  const PageBody({required this.children, this.padding, this.controller, super.key});
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: Sizes.maxContent),
      child: ListView(
        controller: controller,
        padding: padding ?? const EdgeInsets.fromLTRB(Space.gutter, Space.xs, Space.gutter, Space.xxl),
        children: children,
      ),
    ),
  );
}

/// Title above a group of cards, with an optional trailing link.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {this.trailing, super.key});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Space.xl, bottom: Space.sm),
    child: Row(
      children: [
        Expanded(child: Text(title, style: context.text.titleMedium, semanticsLabel: title)),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

/// White card with a hairline border. Tappable when [onTap] is set.
class AppCard extends StatelessWidget {
  const AppCard({required this.child, this.onTap, this.padding = const EdgeInsets.all(Space.md), this.color, super.key});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) => Card(
    color: color,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

/// Navy card for the one most important fact of a screen (your next turn,
/// the round being collected). Text on it is white; the accent is for progress.
class HeroCard extends StatelessWidget {
  const HeroCard({required this.child, this.onTap, super.key});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.hero,
      borderRadius: BorderRadius.circular(Radii.xl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: colors.onHero),
          child: IconTheme.merge(
            data: IconThemeData(color: colors.onHero),
            child: Padding(padding: const EdgeInsets.all(Space.lg), child: child),
          ),
        ),
      ),
    );
  }
}

/// An exact amount with its currency, always left-to-right digits grouping,
/// tabular figures, in the app language.
class AmountText extends StatelessWidget {
  const AmountText(this.money, {this.large = false, this.color, super.key});
  final Money money;
  final bool large;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final style = (large ? DairaType.amountL : DairaType.amountM).copyWith(color: color ?? DefaultTextStyle.of(context).style.color);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: money.amount(locale)),
          TextSpan(
            text: ' ${money.currency}',
            style: style.copyWith(fontSize: (style.fontSize ?? 16) * 0.55, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      style: style,
      textDirection: TextDirection.ltr,
      semanticsLabel: money.format(locale),
    );
  }
}

/// Round progress: share of the round already confirmed. Accent on the track.
class ProgressBar extends StatelessWidget {
  const ProgressBar(this.value, {this.onHero = false, super.key});
  final double value;
  final bool onHero;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.pill),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1)),
        duration: context.reduceMotion ? Duration.zero : Motion.emphasis,
        curve: Motion.easing,
        builder: (context, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: 6,
          color: colors.accent,
          backgroundColor: onHero ? colors.onHero.withValues(alpha: 0.16) : colors.track,
        ),
      ),
    );
  }
}

/// Initials in a soft circle, for members.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.name, {this.size = Sizes.avatar, this.highlight = false, super.key});
  final String name;
  final double size;

  /// The signed-in person or the round recipient.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.length == 1
        ? parts.first.characters.first
        : '${parts.first.characters.first}${parts.last.characters.first}';
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: highlight ? colors.accentContainer : colors.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Text(
          initials.toUpperCase(),
          style: TextStyle(
            fontFamily: DairaType.family,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.38,
            height: 1,
            color: colors.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

/// Settings-style row: icon, title, optional value, chevron.
class NavRow extends StatelessWidget {
  const NavRow({required this.icon, required this.title, this.value, this.onTap, this.danger = false, super.key});
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = danger ? colors.danger : colors.text;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: danger ? colors.danger : colors.textMuted),
      title: Text(title, style: context.text.bodyLarge?.copyWith(color: color, fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null) Text(value!, style: context.text.bodySmall),
          if (onTap != null && !danger) ...[
            const SizedBox(width: Space.xxs),
            DirectionalIcon(AppIcons.forward, size: 18, color: colors.textDisabled),
          ],
        ],
      ),
    );
  }
}

/// Opens a bottom sheet with the app's shape, safe area and keyboard padding.
Future<T?> showAppSheet<T>(BuildContext context, {required WidgetBuilder builder}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.xl),
      child: builder(context),
    ),
  ),
);
