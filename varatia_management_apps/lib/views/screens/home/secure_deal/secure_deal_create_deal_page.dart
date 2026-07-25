part of 'tenant_secure_deal_screen.dart';

class SecureDealCreateDealPage extends StatefulWidget {
  const SecureDealCreateDealPage({super.key});

  @override
  State<SecureDealCreateDealPage> createState() =>
      _SecureDealCreateDealPageState();
}

class _SecureDealCreateDealPageState extends State<SecureDealCreateDealPage> {
  final _projectTitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();

  String? _selectedCategory;
  String? _selectedDeliveryTime;

  static const _categories = <String>[
    'Design & Creative',
    'Home Rental',
    'Property Service',
    'Moving Support',
  ];
  static const _deliveryTimes = <String>['1 Day', '3 Days', '7 Days'];

  @override
  void dispose() {
    _projectTitleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  String get _projectTitle {
    final value = _projectTitleController.text.trim();
    return value.isEmpty ? 'Logo Design for Business' : value;
  }

  String get _description {
    final value = _descriptionController.text.trim();
    return value.isEmpty
        ? 'I need a modern and professional logo for my business.'
        : value;
  }

  int get _budget {
    final digits = _budgetController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 5000;
  }

  @override
  Widget build(BuildContext context) {
    return _SecureDealPageScaffold(
      title: context.tr(bn: 'নতুন ডিল তৈরি করুন', en: 'Create New Deal'),
      body: _CreateDealStep(
        projectTitleController: _projectTitleController,
        descriptionController: _descriptionController,
        budgetController: _budgetController,
        categories: _categories,
        selectedCategory: _selectedCategory,
        onCategoryChanged: (value) {
          if (value != null) {
            setState(() => _selectedCategory = value);
          }
        },
        deliveryTimes: _deliveryTimes,
        selectedDeliveryTime: _selectedDeliveryTime,
        onDeliveryTimeChanged: (value) {
          if (value != null) {
            setState(() => _selectedDeliveryTime = value);
          }
        },
      ),
      bottomAction: _SecureDealBottomAction(
        label: context.tr(bn: 'পরবর্তী ধাপ', en: 'Next Step'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SecureDealConfirmDealPage(
                projectTitle: _projectTitle,
                category: _selectedCategory ?? 'Design & Creative',
                description: _description,
                deliveryTime: _selectedDeliveryTime ?? '3 Days',
                budget: _budget,
              ),
            ),
          );
        },
      ),
    );
  }
}
