import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_context.dart';
import '../../data/models/app_models.dart';
import '../../viewmodels/app_view_models.dart';
import '../widgets/app_widgets.dart';
import '../widgets/flat_rent_payment_notice_card.dart';
import 'support_screens.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentViewModel>().loadPaymentsFromApi();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PaymentViewModel>();

    return ListView(
      padding: screenPadding,
      children: [
        ScreenHeader(
          title: context.tr(bn: 'রেন্ট ও পেমেন্ট', en: 'Rent & Payment'),
          subtitle: context.tr(
            bn: 'মাসিক ভাড়া, পরিশোধ, ডিউ এবং কালেকশন ট্র্যাক করুন।',
            en: 'Track rent collection, payment status, and due amounts.',
          ),
          trailing: FilledButton.icon(
            onPressed: () => showComingSoonSnackBar(
              context,
              context.tr(bn: 'নতুন পেমেন্ট', en: 'New payment'),
            ),
            icon: const Icon(Icons.add_card_rounded),
            label: Text(context.tr(bn: 'যোগ', en: 'Add')),
          ),
        ),
        const SizedBox(height: 14),
        FlatRentPaymentNoticeCard(
          propertyName: viewModel.payments.isNotEmpty
              ? viewModel.payments.first.propertyName
              : 'Flat A',
          tenantName: viewModel.payments.isNotEmpty
              ? viewModel.payments.first.tenantName
              : null,
          amount: viewModel.totalDue > 0 ? viewModel.totalDue : 15000,
          isDismissible: false,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(bn: 'মোট বকেয়া ভাড়া', en: 'Total Due Rent'),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.money(viewModel.totalDue),
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ExpensesScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                ),
                icon: const Icon(Icons.receipt_long_rounded),
                label: Text(context.tr(bn: 'বিল', en: 'Bills')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (viewModel.isLoadingPayments)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          )
        else
          SectionCard(
            title: context.tr(bn: 'পেমেন্ট তালিকা', en: 'Payment List'),
            child: viewModel.payments.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      context.tr(
                        bn: 'কোনো পেমেন্ট রেকর্ড নেই।',
                        en: 'No payment records found.',
                      ),
                    ),
                  )
                : Column(
                    children: viewModel.payments
                        .map((payment) => _PaymentTile(payment: payment))
                        .toList(growable: false),
                  ),
          ),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});

  final RentPayment payment;

  @override
  Widget build(BuildContext context) {
    final paidLabel = payment.paidOn == null
        ? context.tr(bn: 'পেমেন্ট এখনো বাকি', en: 'Payment pending')
        : context.tr(
            bn: 'পরিশোধ: ${context.shortDateText(payment.paidOn!)}',
            en: 'Paid on ${context.shortDateText(payment.paidOn!)}',
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.propertyName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${payment.tenantName} • ${payment.monthLabel}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    paidLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge.forPayment(context, payment.status),
                const SizedBox(height: 10),
                Text(
                  context.money(payment.amount),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
