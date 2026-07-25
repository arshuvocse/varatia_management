import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_context.dart';
import '../../data/services/report_api_service.dart';
import '../../viewmodels/app_view_models.dart';
import '../widgets/app_widgets.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  Future<void> _refresh(BuildContext context) {
    return context.read<ReportViewModel>().refresh();
  }

  Future<void> _exportPayments(BuildContext context) async {
    try {
      final result = await context.read<ReportViewModel>().exportPaymentsCsv();
      if (!context.mounted) {
        return;
      }

      await Clipboard.setData(ClipboardData(text: result.csvContent));
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              bn: '${result.fileName} এর কনটেন্ট clipboard-এ copy হয়েছে।',
              en: '${result.fileName} content was copied to the clipboard.',
            ),
          ),
        ),
      );
    } on ReportApiException catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReportViewModel>();
    final hasMetrics =
        viewModel.incomeMetrics.isNotEmpty ||
        viewModel.expenseMetrics.isNotEmpty;

    if (viewModel.isLoading && !hasMetrics) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: ListView(
        padding: screenPadding,
        children: [
          ScreenHeader(
            title: context.tr(bn: 'রিপোর্টস', en: 'Reports'),
            subtitle: context.tr(
              bn: 'মাসিক আয়, খরচ এবং সামগ্রিক ট্রেন্ড দ্রুত দেখে নিন।',
              en: 'Review monthly income, expenses, and overall trends.',
            ),
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  onPressed: viewModel.isLoading
                      ? null
                      : () => _refresh(context),
                  tooltip: context.tr(bn: 'Refresh', en: 'Refresh'),
                  icon: const Icon(Icons.refresh_rounded),
                ),
                IconButton(
                  onPressed: viewModel.isExporting
                      ? null
                      : () => _exportPayments(context),
                  tooltip: context.tr(
                    bn: 'Copy CSV Export',
                    en: 'Copy CSV Export',
                  ),
                  icon: const Icon(Icons.download_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (viewModel.errorMessage != null) ...[
            SectionCard(
              title: context.tr(bn: 'Sync Status', en: 'Sync Status'),
              child: Text(viewModel.errorMessage!),
            ),
            const SizedBox(height: 18),
          ],
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  label: context.tr(bn: 'সর্বশেষ আয়', en: 'Latest Income'),
                  value: context.money(viewModel.latestIncome),
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  label: context.tr(bn: 'সর্বশেষ খরচ', en: 'Latest Expense'),
                  value: context.money(viewModel.latestExpense),
                  icon: Icons.trending_down_rounded,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: context.tr(bn: 'Summary Snapshot', en: 'Summary Snapshot'),
            child: Column(
              children: [
                InfoLine(
                  label: context.tr(
                    bn: 'Total Properties',
                    en: 'Total Properties',
                  ),
                  value: viewModel.dashboardSummary.totalProperties.toString(),
                ),
                InfoLine(
                  label: context.tr(bn: 'Total Tenants', en: 'Total Tenants'),
                  value: viewModel.dashboardSummary.totalTenants.toString(),
                ),
                InfoLine(
                  label: context.tr(bn: 'Due Rent', en: 'Due Rent'),
                  value: context.money(viewModel.dashboardSummary.dueRent),
                ),
                if (viewModel.generatedAtUtc != null)
                  InfoLine(
                    label: context.tr(bn: 'Generated At', en: 'Generated At'),
                    value: viewModel.generatedAtUtc!.toLocal().toString(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: context.tr(
              bn: 'মাসিক আয়ের চার্ট',
              en: 'Monthly Income Chart',
            ),
            child: SimpleMetricChart(
              items: viewModel.incomeMetrics,
              barColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: context.tr(bn: 'খরচের চার্ট', en: 'Expense Chart'),
            child: SimpleMetricChart(
              items: viewModel.expenseMetrics,
              barColor: AppColors.warning,
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: context.tr(bn: 'ইনসাইট', en: 'Insights'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(
                    bn: 'এপ্রিল মাসে আয় এখন পর্যন্ত ${context.money(viewModel.latestIncome)}।',
                    en: 'Income reached ${context.money(viewModel.latestIncome)} in April.',
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr(
                    bn: 'খরচের সবচেয়ে বড় অংশ ইউটিলিটি ও সার্ভিসে যাচ্ছে।',
                    en: 'Utilities and services remain the biggest expense category.',
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr(
                    bn: 'বকেয়া কমাতে Flat B এবং Flat J এ ফলোআপ জরুরি।',
                    en: 'Flat B and Flat J need follow-up to reduce due rent.',
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
