import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_context.dart';
import '../../data/models/app_models.dart';
import '../../data/services/communication_api_service.dart';
import '../../data/services/expense_api_service.dart';
import '../../data/services/notification_api_service.dart';
import '../../data/services/owner_tenant_api_service.dart';
import '../../viewmodels/app_view_models.dart';
import '../widgets/app_widgets.dart';

class TenantScreen extends StatefulWidget {
  const TenantScreen({super.key});

  @override
  State<TenantScreen> createState() => _TenantScreenState();
}

class _TenantScreenState extends State<TenantScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TenantViewModel>().loadTenantsFromApi();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TenantProfile> _filterTenants(List<TenantProfile> tenants) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return tenants;
    }

    return tenants
        .where((tenant) {
          final searchableText = [
            tenant.id,
            tenant.name,
            tenant.phone,
            tenant.nid,
            tenant.propertyName,
          ].join(' ').toLowerCase();

          return searchableText.contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _openEditTenantSheet(
    BuildContext context,
    TenantProfile tenant,
  ) async {
    final viewModel = context.read<TenantViewModel>();
    final updatedTenant = await showModalBottomSheet<TenantProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _TenantEditBottomSheet(viewModel: viewModel, tenant: tenant),
    );

    if (updatedTenant == null || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(
            bn: '${updatedTenant.name} was updated successfully.',
            en: '${updatedTenant.name} was updated successfully.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantViewModel>();
    final tenants = viewModel.tenants;
    final filteredTenants = _filterTenants(tenants);
    final shouldShowSearch = tenants.isNotEmpty || _searchQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(bn: 'টেন্যান্ট তালিকা', en: 'Tenant List')),
        actions: [
          IconButton(
            onPressed: () => showComingSoonSnackBar(
              context,
              context.tr(bn: 'নতুন টেন্যান্ট', en: 'New tenant'),
            ),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (shouldShowSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: context.tr(
                    bn: 'Search tenants by name, phone, NID, or property',
                    en: 'Search tenants by name, phone, NID, or property',
                  ),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: context.tr(bn: 'Clear', en: 'Clear'),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: screenPadding,
              itemCount: filteredTenants.isEmpty ? 1 : filteredTenants.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (context.watch<TenantViewModel>().isLoadingTenants) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (tenants.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        context.tr(
                          bn: 'No tenants found.',
                          en: 'No tenants found.',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                }

                if (filteredTenants.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          const Icon(Icons.search_off_rounded),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              context.tr(
                                bn: 'No matching tenants found.',
                                en: 'No matching tenants found.',
                              ),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final tenant = filteredTenants[index];
                final propertyName = tenant.propertyName.trim().isEmpty
                    ? context.tr(bn: 'No unit assigned', en: 'No unit assigned')
                    : tenant.propertyName;

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TenantDetailsScreen(tenant: tenant),
                        ),
                      );
                    },
                    leading: Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    title: Text(tenant.name),
                    subtitle: Text('${tenant.phone} - $propertyName'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: context.tr(bn: 'Edit', en: 'Edit'),
                          onPressed: viewModel.isUpdatingTenant
                              ? null
                              : () => _openEditTenantSheet(context, tenant),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantEditBottomSheet extends StatefulWidget {
  const _TenantEditBottomSheet({required this.viewModel, required this.tenant});

  final TenantViewModel viewModel;
  final TenantProfile tenant;

  @override
  State<_TenantEditBottomSheet> createState() => _TenantEditBottomSheetState();
}

class _TenantEditBottomSheetState extends State<_TenantEditBottomSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _nidController;

  String? _validationError;

  @override
  void initState() {
    super.initState();
    widget.viewModel.clearTenantUpdateError();
    _nameController = TextEditingController(text: widget.tenant.name);
    _phoneController = TextEditingController(text: widget.tenant.phone);
    _nidController = TextEditingController(text: widget.tenant.nid);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nidController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final fullName = _nameController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final nid = _nidController.text.trim();
    final validationError = _validate(
      fullName: fullName,
      phoneNumber: phoneNumber,
      nid: nid,
    );

    if (validationError != null) {
      setState(() {
        _validationError = validationError;
      });
      return;
    }

    setState(() {
      _validationError = null;
    });

    final updatedTenant = await widget.viewModel.updateTenant(
      tenantId: widget.tenant.id,
      fullName: fullName,
      phoneNumber: phoneNumber,
      nid: nid,
    );

    if (!mounted || updatedTenant == null) {
      return;
    }

    Navigator.of(context).pop(updatedTenant);
  }

  String? _validate({
    required String fullName,
    required String phoneNumber,
    required String nid,
  }) {
    final normalizedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (fullName.length < 3) {
      return context.tr(
        bn: 'Tenant name must contain at least 3 characters.',
        en: 'Tenant name must contain at least 3 characters.',
      );
    }

    if (normalizedPhoneNumber.length < 10 ||
        normalizedPhoneNumber.length > 15) {
      return context.tr(
        bn: 'Phone number must contain 10 to 15 digits.',
        en: 'Phone number must contain 10 to 15 digits.',
      );
    }

    if (nid.length < 10) {
      return context.tr(
        bn: 'NID must contain at least 10 characters.',
        en: 'NID must contain at least 10 characters.',
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        final isSubmitting = widget.viewModel.isUpdatingTenant;
        final errorMessage =
            _validationError ?? widget.viewModel.tenantUpdateError;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppShadows.card,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.tr(bn: 'Edit Tenant', en: 'Edit Tenant'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    EntryTextField(
                      controller: _nameController,
                      enabled: !isSubmitting,
                      textInputAction: TextInputAction.next,
                      label: context.tr(bn: 'Tenant Name', en: 'Tenant Name'),
                      hint: context.tr(
                        bn: 'Enter tenant full name',
                        en: 'Enter tenant full name',
                      ),
                      icon: Icons.person_outline_rounded,
                      dense: true,
                    ),
                    const SizedBox(height: 14),
                    EntryTextField(
                      controller: _phoneController,
                      enabled: !isSubmitting,
                      textInputAction: TextInputAction.next,
                      label: context.tr(bn: 'Phone Number', en: 'Phone Number'),
                      hint: context.tr(
                        bn: 'Enter tenant phone number',
                        en: 'Enter tenant phone number',
                      ),
                      icon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                      dense: true,
                    ),
                    const SizedBox(height: 14),
                    EntryTextField(
                      controller: _nidController,
                      enabled: !isSubmitting,
                      textInputAction: TextInputAction.done,
                      label: context.tr(bn: 'NID Number', en: 'NID Number'),
                      hint: context.tr(
                        bn: 'Enter tenant NID',
                        en: 'Enter tenant NID',
                      ),
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      dense: true,
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFECDD3)),
                        ),
                        child: Text(
                          errorMessage,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: const Color(0xFFB42318),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: Text(context.tr(bn: 'Cancel', en: 'Cancel')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: isSubmitting ? null : _submit,
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    context.tr(
                                      bn: 'Save Changes',
                                      en: 'Save Changes',
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class TenantDetailsScreen extends StatelessWidget {
  const TenantDetailsScreen({super.key, required this.tenant});

  final TenantProfile tenant;

  String _propertyLabel(BuildContext context) {
    final propertyName = tenant.propertyName.trim();
    if (propertyName.isEmpty) {
      return context.tr(bn: 'No unit assigned', en: 'No unit assigned');
    }

    return propertyName;
  }

  Future<void> _moveOutTenant(BuildContext context) async {
    final shouldMoveOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr(bn: 'Move Out', en: 'Move Out')),
          content: Text(
            context.tr(
              bn: 'Do you want to move out ${tenant.name} from this unit?',
              en: 'Do you want to move out ${tenant.name} from this unit?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.tr(bn: 'Cancel', en: 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: Text(context.tr(bn: 'Move Out', en: 'Move Out')),
            ),
          ],
        );
      },
    );

    if (shouldMoveOut != true) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final tenantViewModel = context.read<TenantViewModel>();
    final propertyViewModel = context.read<PropertyViewModel>();

    try {
      final result = await tenantViewModel.moveOutTenant(tenantId: tenant.id);

      if (!context.mounted) {
        return;
      }

      propertyViewModel.markPropertyVacant(
        propertyId: result.previousPropertyId,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      Navigator.of(context).pop();
    } on OwnerTenantApiException catch (error) {
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
    return Scaffold(
      appBar: AppBar(title: Text(tenant.name)),
      body: ListView(
        padding: screenPadding,
        children: [
          SectionCard(
            title: context.tr(bn: 'Tenant Details', en: 'Tenant Details'),
            child: Column(
              children: [
                InfoLine(
                  label: context.tr(bn: 'নাম', en: 'Name'),
                  value: tenant.name,
                ),
                InfoLine(
                  label: context.tr(bn: 'ফোন', en: 'Phone'),
                  value: tenant.phone,
                ),
                InfoLine(
                  label: context.tr(bn: 'এনআইডি', en: 'NID'),
                  value: tenant.nid,
                ),
                InfoLine(
                  label: context.tr(bn: 'প্রপার্টি', en: 'Property'),
                  value: _propertyLabel(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: tenant.propertyName.trim().isEmpty
                ? null
                : () => _moveOutTenant(context),
            child: Text(context.tr(bn: 'Move Out', en: 'Move Out')),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => showComingSoonSnackBar(
              context,
              context.tr(bn: 'Edit tenant', en: 'Edit tenant'),
            ),
            child: Text(context.tr(bn: 'Edit', en: 'Edit')),
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAsRead(
    BuildContext context,
    AppNotificationItem item,
  ) async {
    if (!item.isUnread || item.id <= 0) {
      return;
    }

    try {
      await context.read<NotificationViewModel>().markAsRead(
        notificationId: item.id,
      );
    } on NotificationApiException catch (error) {
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
    final viewModel = context.watch<NotificationViewModel>();

    if (viewModel.isLoading && viewModel.notifications.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(bn: 'নোটিফিকেশনস', en: 'Notifications')),
        actions: [
          IconButton(
            onPressed: viewModel.isLoading ? null : () => viewModel.refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SendNotificationScreen(),
                ),
              );
            },
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<NotificationViewModel>().refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: screenPadding,
          children: [
            if (viewModel.errorMessage != null) ...[
              SectionCard(
                title: context.tr(bn: 'Sync Status', en: 'Sync Status'),
                child: Text(viewModel.errorMessage!),
              ),
              const SizedBox(height: 12),
            ],
            if (viewModel.notifications.isEmpty)
              SectionCard(
                title: context.tr(bn: 'Notifications', en: 'Notifications'),
                child: Text(
                  context.tr(
                    bn: 'এখনও কোনো notification পাওয়া যায়নি।',
                    en: 'No notifications were found yet.',
                  ),
                ),
              )
            else
              ...viewModel.notifications.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(18),
                      onTap: () => _markAsRead(context, item),
                      leading: Container(
                        height: 14,
                        width: 14,
                        decoration: BoxDecoration(
                          color: item.isUnread
                              ? AppColors.accent
                              : AppColors.border,
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(item.title),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${item.subtitle}\n${context.shortDateText(item.createdAt)}',
                        ),
                      ),
                      trailing: item.isUnread
                          ? Text(
                              context.tr(bn: 'Unread', en: 'Unread'),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _userIdController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_userIdController.text.trim().isEmpty ||
        _titleController.text.trim().length < 2 ||
        _bodyController.text.trim().length < 2) {
      _showMessage('Enter valid notification details.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await context
          .read<NotificationViewModel>()
          .sendNotification(
            userId: _userIdController.text.trim(),
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
          );

      if (!mounted) {
        return;
      }

      await _showSuccessDialog(result);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } on NotificationApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showSuccessDialog(NotificationSendResult result) async {
    final messageId = result.firebaseMessageId.trim().isEmpty
        ? '-'
        : result.firebaseMessageId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            context.tr(bn: 'Notification Sent', en: 'Notification Sent'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.message),
              const SizedBox(height: 12),
              InfoLine(
                label: context.tr(bn: 'User Id', en: 'User Id'),
                value: result.userId,
              ),
              InfoLine(
                label: context.tr(
                  bn: 'Firebase Message Id',
                  en: 'Firebase Message Id',
                ),
                value: messageId,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.tr(bn: 'OK', en: 'OK')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr(bn: 'Send Notification', en: 'Send Notification'),
        ),
      ),
      body: ListView(
        padding: screenPadding,
        children: [
          EntryTextField(
            controller: _userIdController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'User Id', en: 'User Id'),
            hint: context.tr(
              bn: 'Target user GUID দিন',
              en: 'Enter the target user GUID',
            ),
            icon: Icons.person_pin_outlined,
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _titleController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Title', en: 'Title'),
            hint: context.tr(bn: 'Rent reminder', en: 'Rent reminder'),
            icon: Icons.title_rounded,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr(bn: 'Message', en: 'Message'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bodyController,
            enabled: !_isSubmitting,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: context.tr(
                bn: 'যে notification পাঠাতে চান সেটা লিখুন',
                en: 'Write the notification body',
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.message_outlined),
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(context.tr(bn: 'Send', en: 'Send')),
          ),
        ],
      ),
    );
  }
}

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  Future<void> _editExpense(BuildContext context, ExpenseItem expense) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditExpenseScreen(expense: expense),
      ),
    );
  }

  Future<void> _deleteExpense(BuildContext context, ExpenseItem expense) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr(bn: 'Delete', en: 'Delete')),
          content: Text(
            context.tr(
              bn: 'Do you want to delete ${expense.title}?',
              en: 'Do you want to delete ${expense.title}?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.tr(bn: 'Cancel', en: 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: Text(context.tr(bn: 'Delete', en: 'Delete')),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    try {
      final expenseViewModel = context.read<ExpenseViewModel>();
      final result = await expenseViewModel.deleteExpense(
        expenseId: expense.id,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } on ExpenseApiException catch (error) {
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
    final viewModel = context.watch<ExpenseViewModel>();

    if (viewModel.isLoading && viewModel.expenses.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(bn: 'বিল ও খরচ', en: 'Bills & Expenses')),
        actions: [
          IconButton(
            onPressed: viewModel.isLoading ? null : () => viewModel.refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AddExpenseScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ExpenseViewModel>().refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: screenPadding,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(bn: 'মোট খরচ', en: 'Total Expenses'),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.money(viewModel.totalExpenses),
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: Colors.white),
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
              const SizedBox(height: 12),
            ],
            if (viewModel.expenses.isEmpty)
              SectionCard(
                title: context.tr(bn: 'Expenses', en: 'Expenses'),
                child: Text(
                  context.tr(
                    bn: 'এখনও কোনো expense পাওয়া যায়নি।',
                    en: 'No expenses were found yet.',
                  ),
                ),
              )
            else
              ...viewModel.expenses.map(
                (expense) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(18),
                      leading: Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      title: Text(expense.title),
                      subtitle: Text(
                        '${expense.category} - ${expense.monthLabel}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            context.money(expense.amount),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editExpense(context, expense);
                                return;
                              }

                              _deleteExpense(context, expense);
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Text(context.tr(bn: 'Edit', en: 'Edit')),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Text(
                                  context.tr(bn: 'Delete', en: 'Delete'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  _AddExpenseScreenState()
    : _monthLabelController = TextEditingController(text: _defaultMonthLabel());

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _monthLabelController;
  bool _isSubmitting = false;

  static String _defaultMonthLabel() {
    const monthNames = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final now = DateTime.now();
    return '${monthNames[now.month - 1]} ${now.year}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _amountController.dispose();
    _monthLabelController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_amountController.text.trim());
    if (_titleController.text.trim().length < 2 ||
        _categoryController.text.trim().length < 2 ||
        amount == null ||
        amount <= 0 ||
        _monthLabelController.text.trim().isEmpty) {
      _showMessage('Enter valid expense details.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await context.read<ExpenseViewModel>().createExpense(
        title: _titleController.text.trim(),
        category: _categoryController.text.trim(),
        amount: amount,
        monthLabel: _monthLabelController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      _showMessage(result.message);
      Navigator.of(context).pop();
    } on ExpenseApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(bn: 'New Expense', en: 'New Expense')),
      ),
      body: ListView(
        padding: screenPadding,
        children: [
          EntryTextField(
            controller: _titleController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Expense Title', en: 'Expense Title'),
            hint: context.tr(
              bn: 'Example: Electricity Bill',
              en: 'Example: Electricity Bill',
            ),
            icon: Icons.receipt_long_rounded,
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _categoryController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Category', en: 'Category'),
            hint: context.tr(bn: 'Example: Utility', en: 'Example: Utility'),
            icon: Icons.category_outlined,
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _amountController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Amount', en: 'Amount'),
            hint: context.tr(bn: '5000', en: '5000'),
            icon: Icons.payments_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _monthLabelController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Month Label', en: 'Month Label'),
            hint: context.tr(bn: 'April 2026', en: 'April 2026'),
            icon: Icons.calendar_month_outlined,
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(context.tr(bn: 'Save Expense', en: 'Save Expense')),
          ),
        ],
      ),
    );
  }
}

class EditExpenseScreen extends StatefulWidget {
  const EditExpenseScreen({super.key, required this.expense});

  final ExpenseItem expense;

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _categoryController;
  late final TextEditingController _amountController;
  late final TextEditingController _monthLabelController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense.title);
    _categoryController = TextEditingController(text: widget.expense.category);
    _amountController = TextEditingController(
      text: widget.expense.amount.toString(),
    );
    _monthLabelController = TextEditingController(
      text: widget.expense.monthLabel,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _amountController.dispose();
    _monthLabelController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_amountController.text.trim());
    if (_titleController.text.trim().length < 2 ||
        _categoryController.text.trim().length < 2 ||
        amount == null ||
        amount <= 0 ||
        _monthLabelController.text.trim().isEmpty) {
      _showMessage('Enter valid expense details.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await context.read<ExpenseViewModel>().updateExpense(
        expenseId: widget.expense.id,
        title: _titleController.text.trim(),
        category: _categoryController.text.trim(),
        amount: amount,
        monthLabel: _monthLabelController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      _showMessage(result.message);
      Navigator.of(context).pop();
    } on ExpenseApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(bn: 'Edit Expense', en: 'Edit Expense')),
      ),
      body: ListView(
        padding: screenPadding,
        children: [
          EntryTextField(
            controller: _titleController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Expense Title', en: 'Expense Title'),
            hint: context.tr(
              bn: 'Example: Electricity Bill',
              en: 'Example: Electricity Bill',
            ),
            icon: Icons.receipt_long_rounded,
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _categoryController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Category', en: 'Category'),
            hint: context.tr(bn: 'Example: Utility', en: 'Example: Utility'),
            icon: Icons.category_outlined,
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _amountController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Amount', en: 'Amount'),
            hint: context.tr(bn: '5000', en: '5000'),
            icon: Icons.payments_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _monthLabelController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Month Label', en: 'Month Label'),
            hint: context.tr(bn: 'April 2026', en: 'April 2026'),
            icon: Icons.calendar_month_outlined,
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(context.tr(bn: 'Save Changes', en: 'Save Changes')),
          ),
        ],
      ),
    );
  }
}

class CommunicationScreen extends StatelessWidget {
  const CommunicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CommunicationViewModel>();

    if (viewModel.isLoading && viewModel.messages.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(bn: 'মেসেজ', en: 'Messages')),
        actions: [
          IconButton(
            onPressed: viewModel.isLoading ? null : () => viewModel.refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CreateMessageScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_comment_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<CommunicationViewModel>().refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: screenPadding,
          children: [
            if (viewModel.errorMessage != null) ...[
              SectionCard(
                title: context.tr(bn: 'Sync Status', en: 'Sync Status'),
                child: Text(viewModel.errorMessage!),
              ),
              const SizedBox(height: 12),
            ],
            if (viewModel.messages.isEmpty)
              SectionCard(
                title: context.tr(bn: 'Messages', en: 'Messages'),
                child: Text(
                  context.tr(
                    bn: 'এখনও কোনো message পাওয়া যায়নি।',
                    en: 'No messages were found yet.',
                  ),
                ),
              )
            else
              ...viewModel.messages.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.sender,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              Text(
                                item.timeLabel,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.propertyName,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.message,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CreateMessageScreen extends StatefulWidget {
  const CreateMessageScreen({super.key});

  @override
  State<CreateMessageScreen> createState() => _CreateMessageScreenState();
}

class _CreateMessageScreenState extends State<CreateMessageScreen> {
  final TextEditingController _senderController = TextEditingController();
  final TextEditingController _propertyController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _senderController.dispose();
    _propertyController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_senderController.text.trim().length < 2 ||
        _propertyController.text.trim().isEmpty ||
        _messageController.text.trim().length < 2) {
      _showMessage('Enter valid message details.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await context.read<CommunicationViewModel>().createMessage(
        sender: _senderController.text.trim(),
        propertyName: _propertyController.text.trim(),
        message: _messageController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      _showMessage(result.message);
      Navigator.of(context).pop();
    } on CommunicationApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(bn: 'New Message', en: 'New Message')),
      ),
      body: ListView(
        padding: screenPadding,
        children: [
          EntryTextField(
            controller: _senderController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Sender', en: 'Sender'),
            hint: context.tr(bn: 'Rahim', en: 'Rahim'),
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _propertyController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Property', en: 'Property'),
            hint: context.tr(bn: 'Flat A', en: 'Flat A'),
            icon: Icons.home_work_outlined,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr(bn: 'Message', en: 'Message'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _messageController,
            enabled: !_isSubmitting,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: context.tr(
                bn: 'যে message পাঠাতে চান সেটা লিখুন',
                en: 'Write the message',
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.message_outlined),
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(context.tr(bn: 'Send Message', en: 'Send Message')),
          ),
        ],
      ),
    );
  }
}
