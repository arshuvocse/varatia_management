import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_context.dart';
import '../../data/services/auth_session_service.dart';
import '../../data/services/tenant_tutor_api_service.dart';
import '../../viewmodels/role_dashboard_view_models.dart';
import 'home/tenant_tutor_welcome_page.dart';

part 'tenant_tutor_teach_learn_page.dart';

class TenantPaymentCenterPage extends StatelessWidget {
  const TenantPaymentCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();

    return _DetailScaffold(
      title: 'Payment',
      trailing: const Icon(Icons.settings_outlined),
      bottomAction: FilledButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TenantAgreementPreviewPage(),
            ),
          );
        },
        child: Text(context.demoText('Generate Agreement')),
      ),
      child: Column(
        children: [
          _PersonHeroCard(
            person: viewModel.tenantProfile,
            accentColor: AppColors.primary,
            trailingText: 'Payment due',
          ),
          const SizedBox(height: 18),
          _GlassPanel(
            child: Column(
              children: viewModel.paymentBreakdown
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _AgreementInfoRow(item: item),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: viewModel.paymentMethods
                .map(
                  (method) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: method == viewModel.paymentMethods.last ? 0 : 10,
                      ),
                      child: _PaymentOptionCard(method: method),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 18),
          _SignatureCard(
            title: 'Digital Signature',
            subtitle: 'Authorized by tenant and owner',
          ),
        ],
      ),
    );
  }
}

class TenantAgreementPreviewPage extends StatelessWidget {
  const TenantAgreementPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();

    return _DetailScaffold(
      title: 'Agreement Preview',
      bottomAction: FilledButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TenantAgreementDocumentPage(),
            ),
          );
        },
        style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
        child: Text(context.demoText('Review Final Document')),
      ),
      child: Column(
        children: [
          _PersonHeroCard(
            person: viewModel.tenantProfile,
            accentColor: AppColors.accent,
            trailingText: 'Draft ready',
          ),
          const SizedBox(height: 18),
          _GlassPanel(
            child: Column(
              children: viewModel.agreementPreviewFields
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _AgreementInfoRow(item: item),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: const [
              Expanded(child: _MiniSignatureBlock(label: 'Rafiq Ahmed')),
              SizedBox(width: 12),
              Expanded(child: _MiniSignatureBlock(label: 'Omer Hasan')),
            ],
          ),
        ],
      ),
    );
  }
}

class TenantAgreementDocumentPage extends StatelessWidget {
  const TenantAgreementDocumentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();

    return _DetailScaffold(
      title: 'Agreement',
      bottomAction: FilledButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TenantAgreementCreatedPage(),
            ),
          );
        },
        child: Text(context.demoText('Create Agreement')),
      ),
      child: Column(
        children: [
          _PersonHeroCard(
            person: viewModel.ownerProfile,
            accentColor: AppColors.success,
            trailingText: 'Agreement approved',
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.success, Color(0xFF34D399)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    context.demoText('Create Agreement'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  context.demoText(
                    'This agreement confirms the rental terms between tenant and owner for the selected property.',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                const Row(
                  children: [
                    Expanded(child: _MiniSignatureBlock(label: 'Rafiq Ahmed')),
                    SizedBox(width: 12),
                    Expanded(child: _MiniSignatureBlock(label: 'Omer Hasan')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TenantAgreementCreatedPage extends StatelessWidget {
  const TenantAgreementCreatedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();

    return _DetailScaffold(
      title: 'Payment',
      bottomAction: FilledButton(
        onPressed: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
        style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
        child: Text(context.demoText('Pay Now')),
      ),
      child: Column(
        children: [
          _GlassPanel(
            child: Column(
              children: [
                Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.success,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  context.demoText('Agreement Created!'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  context.demoText(
                    'Your agreement has been generated. Download the PDF or continue to payment.',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: Text(context.demoText('Download PDF')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                        ),
                        child: Text(context.demoText('Continue')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: viewModel.paymentMethods
                .map(
                  (method) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: method == viewModel.paymentMethods.last ? 0 : 10,
                      ),
                      child: _PaymentOptionCard(method: method),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class TenantMonthlyBillsPage extends StatelessWidget {
  const TenantMonthlyBillsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();

    return _DetailScaffold(
      title: 'Monthly Bills',
      trailing: const Icon(Icons.crop_square_rounded),
      bottomAction: _BottomAmountBar(
        prefix: 'View Rent',
        amount: '3,650',
        buttonLabel: 'Pay Now',
      ),
      child: Column(
        children: [
          _BlueSummaryCard(
            person: viewModel.managerProfile,
            primaryAction: 'Pay Owner',
            secondaryAction: 'Messages',
          ),
          const SizedBox(height: 18),
          _GlassPanel(
            child: Column(
              children: viewModel.monthlyBillEntries
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _MonthlyBillTile(item: item),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class PropertyManagerDetailsPage extends StatelessWidget {
  const PropertyManagerDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();

    return _DetailScaffold(
      title: 'Manager Details',
      trailing: const Icon(Icons.expand_circle_down_outlined),
      bottomAction: _BottomAmountBar(
        prefix: 'Total',
        amount: '3,560',
        buttonLabel: 'Pay Now',
      ),
      child: Column(
        children: [
          _PersonHeroCard(
            person: viewModel.managerProfile,
            accentColor: AppColors.primary,
            trailingText: 'Property active',
          ),
          const SizedBox(height: 18),
          _GlassPanel(
            child: Column(
              children: viewModel.monthlyBillEntries
                  .take(4)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _MonthlyBillTile(item: item),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class OwnerProfileDetailsPage extends StatelessWidget {
  const OwnerProfileDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();

    return _DetailScaffold(
      title: 'Owner Profile',
      trailing: const Icon(Icons.settings_outlined),
      child: Column(
        children: [
          _PersonHeroCard(
            person: viewModel.ownerProfile,
            accentColor: AppColors.primary,
            trailingText: 'Verified owner',
          ),
          const SizedBox(height: 14),
          Row(
            children: viewModel.ownerActions
                .map(
                  (action) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: action == viewModel.ownerActions.last ? 0 : 10,
                      ),
                      child: _ContactShortcutButton(action: action),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 18),
          _ReferenceListingCard(listing: viewModel.highlightedListing),
        ],
      ),
    );
  }
}

class TenantConfirmMoveInPage extends StatelessWidget {
  const TenantConfirmMoveInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantExperienceViewModel>();

    return _DetailScaffold(
      title: 'Tenant Confirm Move-In',
      child: Column(
        children: [
          _PersonHeroCard(
            person: viewModel.tenantProfile,
            accentColor: AppColors.primary,
            trailingText: 'Move-in pending',
          ),
          const SizedBox(height: 18),
          Row(
            children: viewModel.moveInActions
                .map(
                  (action) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: action == viewModel.moveInActions.last ? 0 : 10,
                      ),
                      child: _QuickActionSquare(action: action),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 18),
          _GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.demoText('Assisting Broker'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.surfaceSoft,
                      child: Text(
                        viewModel.brokerProfile.name.characters.first,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            viewModel.brokerProfile.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            viewModel.brokerProfile.subtitle,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            viewModel.brokerProfile.phone,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({
    required this.title,
    required this.child,
    this.bottomAction,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? bottomAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.demoText(title)),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: [
          if (trailing != null)
            Padding(padding: const EdgeInsets.only(right: 12), child: trailing),
        ],
      ),
      bottomNavigationBar: bottomAction == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: bottomAction,
              ),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [child],
      ),
    );
  }
}

class _PersonHeroCard extends StatelessWidget {
  const _PersonHeroCard({
    required this.person,
    required this.accentColor,
    required this.trailingText,
  });

  final PersonOverviewData person;
  final Color accentColor;
  final String trailingText;

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
      child: Row(
        children: [
          Container(
            height: 60,
            width: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor, accentColor.withValues(alpha: 0.7)],
              ),
              shape: BoxShape.circle,
            ),
            child: Text(
              person.name.characters.first,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        person.name,
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (person.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_rounded,
                        color: AppColors.success,
                        size: 18,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${person.subtitle} • ${person.identifier}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    person.badgeLabel,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Text(
            trailingText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

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
      child: child,
    );
  }
}

class _AgreementInfoRow extends StatelessWidget {
  const _AgreementInfoRow({required this.item});

  final AgreementFieldData item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            item.label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.primaryValue,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (item.secondaryValue != null) ...[
                const SizedBox(height: 4),
                Text(
                  item.secondaryValue!,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  const _PaymentOptionCard({required this.method});

  final PaymentMethodOption method;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: method.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(method.icon, color: method.color),
          ),
          const SizedBox(height: 10),
          Text(method.label, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _SignatureCard extends StatelessWidget {
  const _SignatureCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          Container(
            height: 58,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              'Signature authorized',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSignatureBlock extends StatelessWidget {
  const _MiniSignatureBlock({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Signature',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _BlueSummaryCard extends StatelessWidget {
  const _BlueSummaryCard({
    required this.person,
    required this.primaryAction,
    required this.secondaryAction,
  });

  final PersonOverviewData person;
  final String primaryAction;
  final String secondaryAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Icon(Icons.person_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${person.identifier} • ${person.phone}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  person.badgeLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionPill(
                  label: primaryAction,
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionPill(
                  label: secondaryAction,
                  icon: Icons.message_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _MonthlyBillTile extends StatelessWidget {
  const _MonthlyBillTile({required this.item});

  final MonthlyBillEntryData item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, size: 18, color: item.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(width: 12),
        Text(item.amountLabel, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: 8),
        Text(item.timeLabel, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _BottomAmountBar extends StatelessWidget {
  const _BottomAmountBar({
    required this.prefix,
    required this.amount,
    required this.buttonLabel,
  });

  final String prefix;
  final String amount;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Text(
            prefix,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const Spacer(),
          Text(
            amount,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(96, 44),
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _ContactShortcutButton extends StatelessWidget {
  const _ContactShortcutButton({required this.action});

  final ContactShortcutData action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: action.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(action.icon, color: action.color, size: 18),
          const SizedBox(width: 8),
          Text(
            action.label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: action.color),
          ),
        ],
      ),
    );
  }
}

class _ReferenceListingCard extends StatelessWidget {
  const _ReferenceListingCard({required this.listing});

  final FeaturedListingData listing;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            height: 190,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: listing.imageGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadii.card),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: const Text(
                      'Pay Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    height: 38,
                    width: 38,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border_rounded),
                  ),
                ),
                Center(
                  child: Icon(listing.imageIcon, size: 58, color: Colors.white),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  listing.address,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '${listing.priceLabel} ${listing.priceSuffix}'.trim(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PropertyFeatureChip(
                      label: '${listing.bedrooms} Bed',
                      icon: Icons.bed_rounded,
                    ),
                    _PropertyFeatureChip(
                      label: '${listing.bathrooms} Bath',
                      icon: Icons.bathtub_outlined,
                    ),
                    _PropertyFeatureChip(
                      label: '${listing.areaSqft} sqft',
                      icon: Icons.square_foot_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyFeatureChip extends StatelessWidget {
  const _PropertyFeatureChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _QuickActionSquare extends StatelessWidget {
  const _QuickActionSquare({required this.action});

  final ContactShortcutData action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: action.backgroundColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(action.icon, color: action.color),
          ),
          const SizedBox(height: 10),
          Text(
            action.label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
