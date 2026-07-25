import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_context.dart';
import '../../../core/utils/app_language.dart';
import '../../../data/models/app_models.dart';
import '../../../data/repositories/management_repository.dart';
import '../../../data/services/owner_post_api_service.dart';
import '../../../viewmodels/app_view_models.dart';
import '../../widgets/app_widgets.dart';

class OwnerCreatePostScreen extends StatefulWidget {
  const OwnerCreatePostScreen({super.key});

  @override
  State<OwnerCreatePostScreen> createState() => _OwnerCreatePostScreenState();
}

class _OwnerCreatePostScreenState extends State<OwnerCreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final OwnerPostApiService _ownerPostApiService = OwnerPostApiService();
  final _titleController = TextEditingController();
  final _rentController = TextEditingController();
  final _advanceController = TextEditingController();
  final _areaController = TextEditingController();
  final _serviceChargeController = TextEditingController();
  final _contactController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _remarksController = TextEditingController();

  String? _selectedLocation;
  String? _selectedBuildingId;
  String? _selectedFloorId;
  String? _selectedPropertyId;
  bool _didPrimeSelections = false;
  bool _isPickingImages = false;
  bool _showPhotoError = false;
  bool _showTenantTypeError = false;
  String _fulfillmentStatus = 'not_got';
  _OwnerPostSubmitAction? _submittingAction;

  final Set<_TenantPreference> _tenantPreferences = {_TenantPreference.family};
  final Set<_OwnerPostAmenity> _selectedAmenities = {
    _OwnerPostAmenity.gas,
    _OwnerPostAmenity.security,
  };
  final List<_PickedOwnerPostImage> _images = [];
  final Map<_OwnerPostCounter, int> _counterValues = {
    _OwnerPostCounter.totalFloors: 5,
    _OwnerPostCounter.bedrooms: 2,
    _OwnerPostCounter.balconies: 1,
    _OwnerPostCounter.dining: 1,
    _OwnerPostCounter.drawing: 1,
    _OwnerPostCounter.bathrooms: 2,
    _OwnerPostCounter.kitchens: 1,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrimeSelections) {
      return;
    }

    final repository = context.read<ManagementRepository>();
    _selectedLocation = _firstOrNull(_availableLocations(repository));
    _selectedBuildingId = _firstOrNull(_buildingsForSelection(repository))?.id;
    _selectedFloorId = _firstOrNull(_floorsForSelection(repository))?.id;
    _selectedPropertyId = _firstOrNull(_propertiesForSelection(repository))?.id;
    _applySelectedPropertyDefaults(repository, shouldFillTitle: true);
    _didPrimeSelections = true;
  }

  @override
  void dispose() {
    _ownerPostApiService.dispose();
    _titleController.dispose();
    _rentController.dispose();
    _advanceController.dispose();
    _areaController.dispose();
    _serviceChargeController.dispose();
    _contactController.dispose();
    _descriptionController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  T? _firstOrNull<T>(List<T> values) {
    return values.isEmpty ? null : values.first;
  }

  List<String> _availableLocations(ManagementRepository repository) {
    final locations = <String>[];
    for (final building in repository.buildings) {
      final location = building.location.trim();
      if (location.isNotEmpty && !locations.contains(location)) {
        locations.add(location);
      }
    }
    for (final property in repository.properties) {
      final location = property.location.trim();
      if (location.isNotEmpty && !locations.contains(location)) {
        locations.add(location);
      }
    }
    return locations;
  }

  List<BuildingBlock> _buildingsForSelection(ManagementRepository repository) {
    final location = _selectedLocation;
    final buildings = location == null
        ? repository.buildings
        : repository.buildings
              .where((building) => building.location == location)
              .toList(growable: false);

    return buildings.isEmpty ? repository.buildings : buildings;
  }

  List<BuildingFloor> _floorsForSelection(ManagementRepository repository) {
    final buildingId = _selectedBuildingId;
    final floors = buildingId == null
        ? repository.floors
        : repository.floors
              .where((floor) => floor.buildingId == buildingId)
              .toList(growable: false);

    return floors.isEmpty ? repository.floors : floors;
  }

  List<PropertyUnit> _propertiesForSelection(ManagementRepository repository) {
    final location = _selectedLocation;
    final buildingId = _selectedBuildingId;
    final floorId = _selectedFloorId;
    var properties = repository.properties
        .where((property) {
          final matchesLocation =
              location == null || property.location == location;
          final matchesBuilding =
              buildingId == null || property.buildingId == buildingId;
          final matchesFloor = floorId == null || property.floorId == floorId;
          return matchesLocation && matchesBuilding && matchesFloor;
        })
        .toList(growable: false);

    if (properties.isEmpty && buildingId != null) {
      properties = repository.properties
          .where((property) => property.buildingId == buildingId)
          .toList(growable: false);
    }

    return properties.isEmpty ? repository.properties : properties;
  }

  BuildingBlock? _selectedBuilding(ManagementRepository repository) {
    final selectedId = _selectedBuildingId;
    if (selectedId == null) {
      return null;
    }
    for (final building in repository.buildings) {
      if (building.id == selectedId) {
        return building;
      }
    }
    return null;
  }

  PropertyUnit? _selectedProperty(ManagementRepository repository) {
    final selectedId = _selectedPropertyId;
    if (selectedId == null) {
      return null;
    }
    for (final property in repository.properties) {
      if (property.id == selectedId) {
        return property;
      }
    }
    return null;
  }

  void _applySelectedPropertyDefaults(
    ManagementRepository repository, {
    required bool shouldFillTitle,
  }) {
    final property = _selectedProperty(repository);
    if (property == null) {
      return;
    }

    if (shouldFillTitle && _titleController.text.trim().isEmpty) {
      final titleParts = [
        property.name,
        property.floorLabel,
        property.buildingName,
      ].whereType<String>().where((part) => part.trim().isNotEmpty);
      _titleController.text = titleParts.join(' - ');
    }
    if (_rentController.text.trim().isEmpty && property.monthlyRent > 0) {
      _rentController.text = property.monthlyRent.toString();
    }
  }

  void _handleLocationChanged(String? value) {
    final repository = context.read<ManagementRepository>();
    setState(() {
      _selectedLocation = value;
      _selectedBuildingId = _firstOrNull(
        _buildingsForSelection(repository),
      )?.id;
      _selectedFloorId = _firstOrNull(_floorsForSelection(repository))?.id;
      _selectedPropertyId = _firstOrNull(
        _propertiesForSelection(repository),
      )?.id;
      _applySelectedPropertyDefaults(repository, shouldFillTitle: false);
    });
  }

  void _handleBuildingChanged(String? value) {
    final repository = context.read<ManagementRepository>();
    setState(() {
      _selectedBuildingId = value;
      final building = _selectedBuilding(repository);
      if (building != null) {
        _selectedLocation = building.location;
      }
      _selectedFloorId = _firstOrNull(_floorsForSelection(repository))?.id;
      _selectedPropertyId = _firstOrNull(
        _propertiesForSelection(repository),
      )?.id;
      _applySelectedPropertyDefaults(repository, shouldFillTitle: false);
    });
  }

  void _handleFloorChanged(String? value) {
    final repository = context.read<ManagementRepository>();
    setState(() {
      _selectedFloorId = value;
      _selectedPropertyId = _firstOrNull(
        _propertiesForSelection(repository),
      )?.id;
      _applySelectedPropertyDefaults(repository, shouldFillTitle: false);
    });
  }

  void _handlePropertyChanged(String? value) {
    final repository = context.read<ManagementRepository>();
    setState(() {
      _selectedPropertyId = value;
      final property = _selectedProperty(repository);
      if (property != null) {
        _selectedLocation = property.location;
        _selectedBuildingId = property.buildingId ?? _selectedBuildingId;
        _selectedFloorId = property.floorId ?? _selectedFloorId;
      }
      _applySelectedPropertyDefaults(repository, shouldFillTitle: false);
    });
  }

  Future<void> _pickImages() async {
    setState(() {
      _isPickingImages = true;
    });

    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        withData: true,
      );

      if (result == null) {
        return;
      }

      final pickedImages = result.files
          .where((file) => file.bytes != null)
          .map(
            (file) =>
                _PickedOwnerPostImage(name: file.name, bytes: file.bytes!),
          )
          .toList(growable: false);

      if (pickedImages.isEmpty) {
        return;
      }

      setState(() {
        _images.addAll(pickedImages);
        _showPhotoError = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImages = false;
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _toggleTenantPreference(_TenantPreference preference, bool selected) {
    setState(() {
      if (selected) {
        _tenantPreferences.add(preference);
        _showTenantTypeError = false;
      } else {
        _tenantPreferences.remove(preference);
      }
    });
  }

  void _toggleAmenity(_OwnerPostAmenity amenity, bool selected) {
    setState(() {
      if (selected) {
        _selectedAmenities.add(amenity);
      } else {
        _selectedAmenities.remove(amenity);
      }
    });
  }

  void _updateCounter(_OwnerPostCounter counter, int delta) {
    final minValue = counter == _OwnerPostCounter.totalFloors ? 1 : 0;
    final currentValue = _counterValues[counter] ?? minValue;
    final nextValue = (currentValue + delta).clamp(minValue, 50);
    setState(() {
      _counterValues[counter] = nextValue;
    });
  }

  String _readTr({required String bn, required String en}) {
    final language = context.read<SettingsViewModel>().language;
    return language == AppLanguage.bangla ? bn : en;
  }

  String? _requiredTextValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _readTr(bn: 'এই তথ্য দিন', en: 'Enter this information');
    }
    return null;
  }

  String? _requiredNumberValidator(String? value) {
    final normalizedValue = value?.trim() ?? '';
    if (normalizedValue.isEmpty) {
      return _readTr(bn: 'পরিমাণ দিন', en: 'Enter an amount');
    }
    if (num.tryParse(normalizedValue) == null) {
      return _readTr(bn: 'সঠিক সংখ্যা দিন', en: 'Enter a valid number');
    }
    return null;
  }

  bool get _isSubmittingPost => _submittingAction != null;

  Future<void> _submitPost(_OwnerPostSubmitAction action) async {
    if (_isSubmittingPost) {
      return;
    }

    final repository = context.read<ManagementRepository>();
    final shouldPublish = action == _OwnerPostSubmitAction.publish;
    final isFormValid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _showPhotoError = shouldPublish && _images.isEmpty;
      _showTenantTypeError = shouldPublish && _tenantPreferences.isEmpty;
    });

    if (!isFormValid ||
        (shouldPublish && (_images.isEmpty || _tenantPreferences.isEmpty))) {
      return;
    }

    final propertyName =
        _selectedProperty(repository)?.name ?? _titleController.text.trim();
    final status = shouldPublish ? 'published' : 'draft';

    setState(() {
      _submittingAction = action;
    });

    try {
      final result = await _ownerPostApiService.submitPost(
        body: _buildOwnerPostBody(repository, status: status),
      );

      if (!mounted) {
        return;
      }

      final fallbackMessage = shouldPublish
          ? '$propertyName post published.'
          : '$propertyName draft saved.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              result.message.trim().isEmpty ? fallbackMessage : result.message,
            ),
          ),
        );
    } on OwnerPostApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _readTr(
                bn: 'পোস্ট সেভ করা যায়নি। আবার চেষ্টা করুন।',
                en: 'Unable to save post. Please try again.',
              ),
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _submittingAction = null;
        });
      }
    }
  }

  Map<String, Object?> _buildOwnerPostBody(
    ManagementRepository repository, {
    required String status,
  }) {
    final property = _selectedProperty(repository);
    final building = _selectedBuilding(repository);
    final location =
        (_selectedLocation ?? property?.location ?? building?.location ?? '')
            .trim();
    final title = _titleController.text.trim().isEmpty
        ? property?.name ?? ''
        : _titleController.text.trim();

    return {
      'postType': 'rent',
      'status': status,
      'property': <String, Object?>{
        'location': location,
        'lat': null,
        'long': null,
        'latLongAddress': location,
        'buildingId': _selectedBuildingId ?? property?.buildingId,
        'floorId': _selectedFloorId ?? property?.floorId,
        'propertyId': _selectedPropertyId ?? property?.id,
        'title': title,
      },
      'photos': _images
          .map<Map<String, Object?>>(
            (image) => {'fileName': image.name, 'url': _imageDataUrl(image)},
          )
          .toList(growable: false),
      'tenantPreferences': _tenantPreferences
          .map((preference) => preference.name)
          .toList(growable: false),
      'rooms': <String, Object?>{
        for (final counter in _OwnerPostCounter.values)
          counter.name: _counterValues[counter] ?? 0,
      },
      'amenities': _selectedAmenities
          .map((amenity) => amenity.name)
          .toList(growable: false),
      'pricing': <String, Object?>{
        'monthlyRent': _readInteger(_rentController),
        'advance': _readInteger(_advanceController),
        'serviceCharge': _readInteger(_serviceChargeController),
      },
      'areaSqft': _readInteger(_areaController),
      'contactNumber': _contactController.text.trim(),
      'description': _descriptionController.text.trim(),
      'fulfillmentStatus': _fulfillmentStatus,
      'remarks': _remarksController.text.trim(),
    };
  }

  int _readInteger(TextEditingController controller) {
    return (num.tryParse(controller.text.trim()) ?? 0).round();
  }

  String _imageDataUrl(_PickedOwnerPostImage image) {
    return 'data:${_mimeTypeForFileName(image.name)};base64,'
        '${base64Encode(image.bytes)}';
  }

  String _mimeTypeForFileName(String fileName) {
    final normalizedName = fileName.toLowerCase();
    if (normalizedName.endsWith('.png')) {
      return 'image/png';
    }
    if (normalizedName.endsWith('.webp')) {
      return 'image/webp';
    }
    if (normalizedName.endsWith('.gif')) {
      return 'image/gif';
    }

    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<ManagementRepository>();
    final locations = _availableLocations(repository);
    final buildings = _buildingsForSelection(repository);
    final floors = _floorsForSelection(repository);
    final properties = _propertiesForSelection(repository);

    final selectedLocation = locations.contains(_selectedLocation)
        ? _selectedLocation
        : null;
    final selectedBuildingId =
        buildings.any((building) => building.id == _selectedBuildingId)
        ? _selectedBuildingId
        : null;
    final selectedFloorId = floors.any((floor) => floor.id == _selectedFloorId)
        ? _selectedFloorId
        : null;
    final selectedPropertyId =
        properties.any((property) => property.id == _selectedPropertyId)
        ? _selectedPropertyId
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr(bn: 'নতুন পোস্ট', en: 'New Post')),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              ScreenHeader(
                title: context.tr(
                  bn: 'ভাড়ার পোস্ট তৈরি করুন',
                  en: 'Create Rent Post',
                ),
                subtitle: context.tr(
                  bn: 'লোকেশন, বিল্ডিং, ফ্লোর, ছবি এবং বাসার বিস্তারিত দিয়ে পোস্ট প্রস্তুত করুন।',
                  en: 'Choose location, building, floor, photos, and property details.',
                ),
              ),
              const SizedBox(height: 18),
              SectionCard(
                title: context.tr(
                  bn: 'প্রপার্টি নির্বাচন',
                  en: 'Property Selection',
                ),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedLocation,
                      isExpanded: true,
                      items: locations
                          .map(
                            (location) => DropdownMenuItem<String>(
                              value: location,
                              child: Text(location),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: locations.isEmpty
                          ? null
                          : _handleLocationChanged,
                      validator: _requiredTextValidator,
                      decoration: InputDecoration(
                        labelText: context.tr(bn: 'লোকেশন', en: 'Location'),
                        prefixIcon: const Icon(Icons.location_on_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedBuildingId,
                      isExpanded: true,
                      items: buildings
                          .map(
                            (building) => DropdownMenuItem<String>(
                              value: building.id,
                              child: Text(building.name),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: buildings.isEmpty
                          ? null
                          : _handleBuildingChanged,
                      validator: _requiredTextValidator,
                      decoration: InputDecoration(
                        labelText: context.tr(bn: 'বিল্ডিং', en: 'Building'),
                        prefixIcon: const Icon(Icons.apartment_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedFloorId,
                      isExpanded: true,
                      items: floors
                          .map(
                            (floor) => DropdownMenuItem<String>(
                              value: floor.id,
                              child: Text(
                                '${floor.label} (${floor.totalUnits} units)',
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: floors.isEmpty ? null : _handleFloorChanged,
                      validator: _requiredTextValidator,
                      decoration: InputDecoration(
                        labelText: context.tr(bn: 'ফ্লোর', en: 'Floor'),
                        prefixIcon: const Icon(Icons.layers_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedPropertyId,
                      isExpanded: true,
                      items: properties
                          .map(
                            (property) => DropdownMenuItem<String>(
                              value: property.id,
                              child: Text(
                                '${property.name} - ${property.status.name}',
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: properties.isEmpty
                          ? null
                          : _handlePropertyChanged,
                      validator: _requiredTextValidator,
                      decoration: InputDecoration(
                        labelText: context.tr(
                          bn: 'ফ্ল্যাট / ইউনিট',
                          en: 'Flat / Unit',
                        ),
                        prefixIcon: const Icon(Icons.home_work_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SectionCard(
                title: context.tr(bn: 'ছবি আপলোড', en: 'Upload Photos'),
                child: _OwnerPostImagePicker(
                  images: _images,
                  isPicking: _isPickingImages,
                  showError: _showPhotoError,
                  onPick: _pickImages,
                  onRemove: _removeImage,
                ),
              ),
              const SizedBox(height: 18),
              SectionCard(
                title: context.tr(bn: 'ভাড়াটিয়ার ধরন', en: 'Tenant Preference'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _tenantPreferenceOptions
                          .map(
                            (option) => FilterChip(
                              selected: _tenantPreferences.contains(
                                option.preference,
                              ),
                              label: Text(
                                context.tr(
                                  bn: option.bnLabel,
                                  en: option.enLabel,
                                ),
                              ),
                              avatar: Icon(option.icon, size: 18),
                              onSelected: (selected) => _toggleTenantPreference(
                                option.preference,
                                selected,
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    if (_showTenantTypeError) ...[
                      const SizedBox(height: 10),
                      Text(
                        context.tr(
                          bn: 'কমপক্ষে একটি ধরন নির্বাচন করুন',
                          en: 'Select at least one preference',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SectionCard(
                title: context.tr(
                  bn: 'রুম ও ফ্যাসিলিটি',
                  en: 'Rooms and Facilities',
                ),
                child: Column(
                  children: [
                    _OwnerPostCounterGrid(
                      values: _counterValues,
                      onChanged: _updateCounter,
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _amenityOptions
                            .map(
                              (option) => FilterChip(
                                selected: _selectedAmenities.contains(
                                  option.amenity,
                                ),
                                label: Text(
                                  context.tr(
                                    bn: option.bnLabel,
                                    en: option.enLabel,
                                  ),
                                ),
                                avatar: Icon(option.icon, size: 18),
                                onSelected: (selected) =>
                                    _toggleAmenity(option.amenity, selected),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SectionCard(
                title: context.tr(
                  bn: 'ভাড়া ও বর্ণনা',
                  en: 'Rent and Description',
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      validator: _requiredTextValidator,
                      decoration: InputDecoration(
                        labelText: context.tr(
                          bn: 'পোস্ট টাইটেল',
                          en: 'Post Title',
                        ),
                        prefixIcon: const Icon(Icons.title_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _OwnerPostTwoColumnFields(
                      children: [
                        TextFormField(
                          controller: _rentController,
                          keyboardType: TextInputType.number,
                          validator: _requiredNumberValidator,
                          decoration: InputDecoration(
                            labelText: context.tr(
                              bn: 'মাসিক ভাড়া',
                              en: 'Monthly Rent',
                            ),
                            prefixIcon: const Icon(Icons.payments_outlined),
                          ),
                        ),
                        TextFormField(
                          controller: _advanceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: context.tr(bn: 'অগ্রিম', en: 'Advance'),
                            prefixIcon: const Icon(
                              Icons.account_balance_wallet_outlined,
                            ),
                          ),
                        ),
                        TextFormField(
                          controller: _areaController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: context.tr(
                              bn: 'স্কয়ার ফিট',
                              en: 'Square Feet',
                            ),
                            prefixIcon: const Icon(Icons.square_foot_rounded),
                          ),
                        ),
                        TextFormField(
                          controller: _serviceChargeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: context.tr(
                              bn: 'সার্ভিস চার্জ',
                              en: 'Service Charge',
                            ),
                            prefixIcon: const Icon(
                              Icons.miscellaneous_services_rounded,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      validator: _requiredTextValidator,
                      decoration: InputDecoration(
                        labelText: context.tr(
                          bn: 'যোগাযোগ নম্বর',
                          en: 'Contact Number',
                        ),
                        prefixIcon: const Icon(Icons.call_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: context.tr(
                          bn: 'বর্ণনা / নিয়ম',
                          en: 'Description / Rules',
                        ),
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 72),
                          child: Icon(Icons.notes_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SectionCard(
                title: context.tr(bn: 'পোস্টের ফলাফল', en: 'Post Result'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment<String>(
                          value: 'not_got',
                          icon: const Icon(Icons.hourglass_empty_rounded),
                          label: Text(
                            context.tr(bn: 'এখনও পায়নি', en: 'Not got yet'),
                          ),
                        ),
                        ButtonSegment<String>(
                          value: 'got',
                          icon: const Icon(Icons.check_circle_rounded),
                          label: Text(context.tr(bn: 'পেয়ে গেছে', en: 'Got')),
                        ),
                      ],
                      selected: {_fulfillmentStatus},
                      onSelectionChanged: (values) {
                        setState(() => _fulfillmentStatus = values.first);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _remarksController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: context.tr(bn: 'রিমার্কস', en: 'Remarks'),
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 48),
                          child: Icon(Icons.comment_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final buttons = [
                    OutlinedButton.icon(
                      onPressed: _isSubmittingPost
                          ? null
                          : () => _submitPost(_OwnerPostSubmitAction.draft),
                      icon: _submittingAction == _OwnerPostSubmitAction.draft
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.drafts_rounded),
                      label: Text(
                        context.tr(bn: 'ড্রাফট সেভ', en: 'Save Draft'),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _isSubmittingPost
                          ? null
                          : () => _submitPost(_OwnerPostSubmitAction.publish),
                      icon: _submittingAction == _OwnerPostSubmitAction.publish
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_rounded),
                      label: Text(
                        context.tr(bn: 'পোস্ট করুন', en: 'Publish Post'),
                      ),
                    ),
                  ];

                  if (constraints.maxWidth < 420) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buttons[0],
                        const SizedBox(height: 10),
                        buttons[1],
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: buttons[0]),
                      const SizedBox(width: 12),
                      Expanded(child: buttons[1]),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerPostImagePicker extends StatelessWidget {
  const _OwnerPostImagePicker({
    required this.images,
    required this.isPicking,
    required this.showError,
    required this.onPick,
    required this.onRemove,
  });

  final List<_PickedOwnerPostImage> images;
  final bool isPicking;
  final bool showError;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(
            bn: 'একসাথে একাধিক ছবি নির্বাচন করুন।',
            en: 'Select multiple photos at once.',
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 520 ? 4 : 2;
            return GridView.builder(
              itemCount: images.length + 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 118,
              ),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _OwnerPostAddImageTile(
                    isPicking: isPicking,
                    onTap: onPick,
                  );
                }

                return _OwnerPostImageTile(
                  image: images[index - 1],
                  onRemove: () => onRemove(index - 1),
                );
              },
            );
          },
        ),
        if (showError) ...[
          const SizedBox(height: 10),
          Text(
            context.tr(
              bn: 'কমপক্ষে একটি ছবি আপলোড করুন',
              en: 'Upload at least one photo',
            ),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.danger),
          ),
        ],
      ],
    );
  }
}

class _OwnerPostAddImageTile extends StatelessWidget {
  const _OwnerPostAddImageTile({required this.isPicking, required this.onTap});

  final bool isPicking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isPicking ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Center(
            child: isPicking
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr(bn: 'ছবি যোগ', en: 'Add Photos'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _OwnerPostImageTile extends StatelessWidget {
  const _OwnerPostImageTile({required this.image, required this.onRemove});

  final _PickedOwnerPostImage image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(image.bytes, fit: BoxFit.cover),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xAA0F172A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 22, 8, 8),
                child: Text(
                  image.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xCC0F172A),
                foregroundColor: Colors.white,
                minimumSize: const Size(34, 34),
              ),
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerPostCounterGrid extends StatelessWidget {
  const _OwnerPostCounterGrid({required this.values, required this.onChanged});

  final Map<_OwnerPostCounter, int> values;
  final void Function(_OwnerPostCounter counter, int delta) onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 560 ? 3 : 2;
        return GridView.builder(
          itemCount: _counterOptions.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 112,
          ),
          itemBuilder: (context, index) {
            final option = _counterOptions[index];
            return _OwnerPostCounterTile(
              label: context.tr(bn: option.bnLabel, en: option.enLabel),
              icon: option.icon,
              value: values[option.counter] ?? 0,
              onDecrease: () => onChanged(option.counter, -1),
              onIncrease: () => onChanged(option.counter, 1),
            );
          },
        );
      },
    );
  }
}

class _OwnerPostCounterTile extends StatelessWidget {
  const _OwnerPostCounterTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final IconData icon;
  final int value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _CounterIconButton(icon: Icons.remove_rounded, onTap: onDecrease),
              Expanded(
                child: Text(
                  context.digitsText(value),
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              _CounterIconButton(icon: Icons.add_rounded, onTap: onIncrease),
            ],
          ),
        ],
      ),
    );
  }
}

class _CounterIconButton extends StatelessWidget {
  const _CounterIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        height: 34,
        width: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }
}

class _OwnerPostTwoColumnFields extends StatelessWidget {
  const _OwnerPostTwoColumnFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: child,
                  ),
                )
                .toList(growable: false),
          );
        }

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: children
              .map(
                (child) => SizedBox(
                  width: (constraints.maxWidth - 14) / 2,
                  child: child,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _PickedOwnerPostImage {
  const _PickedOwnerPostImage({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

enum _TenantPreference { bachelor, male, female, family }

enum _OwnerPostSubmitAction { draft, publish }

enum _OwnerPostAmenity { gas, lift, parking, generator, security, cctv }

enum _OwnerPostCounter {
  totalFloors,
  bedrooms,
  balconies,
  dining,
  drawing,
  bathrooms,
  kitchens,
}

class _TenantPreferenceOption {
  const _TenantPreferenceOption({
    required this.preference,
    required this.bnLabel,
    required this.enLabel,
    required this.icon,
  });

  final _TenantPreference preference;
  final String bnLabel;
  final String enLabel;
  final IconData icon;
}

class _AmenityOption {
  const _AmenityOption({
    required this.amenity,
    required this.bnLabel,
    required this.enLabel,
    required this.icon,
  });

  final _OwnerPostAmenity amenity;
  final String bnLabel;
  final String enLabel;
  final IconData icon;
}

class _CounterOption {
  const _CounterOption({
    required this.counter,
    required this.bnLabel,
    required this.enLabel,
    required this.icon,
  });

  final _OwnerPostCounter counter;
  final String bnLabel;
  final String enLabel;
  final IconData icon;
}

const _tenantPreferenceOptions = [
  _TenantPreferenceOption(
    preference: _TenantPreference.bachelor,
    bnLabel: 'ব্যাচেলর',
    enLabel: 'Bachelor',
    icon: Icons.person_outline_rounded,
  ),
  _TenantPreferenceOption(
    preference: _TenantPreference.male,
    bnLabel: 'পুরুষ',
    enLabel: 'Male',
    icon: Icons.male_rounded,
  ),
  _TenantPreferenceOption(
    preference: _TenantPreference.female,
    bnLabel: 'নারী',
    enLabel: 'Female',
    icon: Icons.female_rounded,
  ),
  _TenantPreferenceOption(
    preference: _TenantPreference.family,
    bnLabel: 'ফ্যামিলি',
    enLabel: 'Family',
    icon: Icons.family_restroom_rounded,
  ),
];

const _amenityOptions = [
  _AmenityOption(
    amenity: _OwnerPostAmenity.gas,
    bnLabel: 'গ্যাস',
    enLabel: 'Gas',
    icon: Icons.local_fire_department_rounded,
  ),
  _AmenityOption(
    amenity: _OwnerPostAmenity.lift,
    bnLabel: 'লিফট',
    enLabel: 'Lift',
    icon: Icons.elevator_rounded,
  ),
  _AmenityOption(
    amenity: _OwnerPostAmenity.parking,
    bnLabel: 'পার্কিং',
    enLabel: 'Parking',
    icon: Icons.local_parking_rounded,
  ),
  _AmenityOption(
    amenity: _OwnerPostAmenity.generator,
    bnLabel: 'জেনারেটর',
    enLabel: 'Generator',
    icon: Icons.electric_bolt_rounded,
  ),
  _AmenityOption(
    amenity: _OwnerPostAmenity.security,
    bnLabel: 'সিকিউরিটি',
    enLabel: 'Security',
    icon: Icons.security_rounded,
  ),
  _AmenityOption(
    amenity: _OwnerPostAmenity.cctv,
    bnLabel: 'সিসিটিভি',
    enLabel: 'CCTV',
    icon: Icons.videocam_rounded,
  ),
];

const _counterOptions = [
  _CounterOption(
    counter: _OwnerPostCounter.totalFloors,
    bnLabel: 'মোট তলা',
    enLabel: 'Total Floors',
    icon: Icons.domain_rounded,
  ),
  _CounterOption(
    counter: _OwnerPostCounter.bedrooms,
    bnLabel: 'বেডরুম',
    enLabel: 'Bedrooms',
    icon: Icons.bed_rounded,
  ),
  _CounterOption(
    counter: _OwnerPostCounter.balconies,
    bnLabel: 'বারান্দা',
    enLabel: 'Balconies',
    icon: Icons.balcony_rounded,
  ),
  _CounterOption(
    counter: _OwnerPostCounter.dining,
    bnLabel: 'ডাইনিং',
    enLabel: 'Dining',
    icon: Icons.dining_rounded,
  ),
  _CounterOption(
    counter: _OwnerPostCounter.drawing,
    bnLabel: 'ড্রয়িং',
    enLabel: 'Drawing',
    icon: Icons.chair_rounded,
  ),
  _CounterOption(
    counter: _OwnerPostCounter.bathrooms,
    bnLabel: 'বাথরুম',
    enLabel: 'Bathrooms',
    icon: Icons.bathroom_rounded,
  ),
  _CounterOption(
    counter: _OwnerPostCounter.kitchens,
    bnLabel: 'কিচেন',
    enLabel: 'Kitchens',
    icon: Icons.kitchen_rounded,
  ),
];
