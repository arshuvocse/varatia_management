import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_context.dart';
import '../../data/models/app_models.dart';

const screenPadding = EdgeInsets.fromLTRB(20, 16, 20, 28);

abstract final class BrandAssets {
  static const logo = 'assets/branding/amar_thikanaa_logo.png';
  static const icon = 'assets/branding/amar_thikanaa_icon.png';
}

class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 60});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: Image.asset(
        BrandAssets.icon,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({super.key, this.width = 220});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      BrandAssets.logo,
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key, this.fontSize = 24});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Amar ',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
            ),
          ),
          TextSpan(
            text: 'Thikanaa',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.demoText(title),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                context.demoText(subtitle),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    context.demoText(title),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  TextButton(
                    onPressed: onAction,
                    child: Text(context.demoText(actionLabel!)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 18),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            context.demoText(label),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.primaryDark),
                ),
                const Spacer(),
                Text(
                  context.demoText(label),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  factory StatusBadge.forProperty(BuildContext context, PropertyStatus status) {
    return StatusBadge(
      label: status == PropertyStatus.rented
          ? context.demoText('Occupied')
          : context.demoText('Vacant'),
      color: status == PropertyStatus.rented
          ? AppColors.success
          : AppColors.warning,
    );
  }

  factory StatusBadge.forPayment(BuildContext context, PaymentStatus status) {
    return StatusBadge(
      label: status == PaymentStatus.paid
          ? context.demoText('Paid')
          : context.demoText('Due'),
      color: status == PaymentStatus.paid
          ? AppColors.success
          : AppColors.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        context.demoText(label),
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class InfoLine extends StatelessWidget {
  const InfoLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              context.demoText(label),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class SimpleMetricChart extends StatelessWidget {
  const SimpleMetricChart({
    super.key,
    required this.items,
    required this.barColor,
  });

  final List<MonthlyMetric> items;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final max = items.fold<double>(0, (value, item) {
      return item.value > value ? item.value : value;
    });

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: max == 0 ? 0 : item.value / max,
                          child: Container(
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(
                                AppRadii.pill,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    context.money(item.value),
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class EntryScaffold extends StatelessWidget {
  const EntryScaffold({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
    this.compact = false,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final listPadding = compact
        ? const EdgeInsets.fromLTRB(20, 10, 20, 20)
        : const EdgeInsets.fromLTRB(20, 14, 20, 28);
    final topGap = compact ? 4.0 : 8.0;
    final logoWidth = compact ? 180.0 : 220.0;
    final sectionGap = compact ? 16.0 : 24.0;
    final textGap = compact ? 6.0 : 8.0;
    final subtitleGap = compact ? 8.0 : 10.0;
    final cardPadding = compact ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF0FF), Color(0xFFF5F7FA), Color(0xFFFFF2E8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: listPadding,
            children: [
              Row(
                children: [
                  if (onBack != null)
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  else
                    const SizedBox(height: 48, width: 48),
                ],
              ),
              SizedBox(height: topGap),
              Center(child: AppBrandLogo(width: logoWidth)),
              SizedBox(height: sectionGap),
              Text(
                context.demoText(eyebrow),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: textGap),
              Text(
                context.demoText(title),
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              SizedBox(height: subtitleGap),
              Text(
                context.demoText(subtitle),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: sectionGap),
              Container(
                padding: EdgeInsets.all(cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.large),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EntryTextField extends StatefulWidget {
  const EntryTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.dense = false,
    this.controller,
    this.enabled = true,
    this.textInputAction,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool dense;
  final TextEditingController? controller;
  final bool enabled;
  final TextInputAction? textInputAction;

  @override
  State<EntryTextField> createState() => _EntryTextFieldState();
}

class _EntryTextFieldState extends State<EntryTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  void didUpdateWidget(EntryTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscureText = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.demoText(widget.label),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: widget.dense ? 8 : 10),
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          keyboardType: widget.keyboardType,
          obscureText: _obscureText,
          textInputAction: widget.textInputAction,
          decoration: InputDecoration(
            hintText: context.demoText(widget.hint),
            prefixIcon: Icon(widget.icon),
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF64748B),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
            isDense: widget.dense,
            contentPadding: EdgeInsets.symmetric(
              vertical: widget.dense ? 14 : 18,
            ),
          ),
        ),
      ],
    );
  }
}

void showComingSoonSnackBar(BuildContext context, String featureName) {
  final localizedFeatureName = context.demoText(featureName);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        context.tr(
          bn: '$localizedFeatureName ফিচারটি এখন ডেমো হিসেবে দেখানো হচ্ছে।',
          en: '$localizedFeatureName is shown as a demo UI action for now.',
        ),
      ),
    ),
  );
}
