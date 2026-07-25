import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_context.dart';
import '../../data/models/app_models.dart';
import '../../data/services/dhaka_police_zone_api_service.dart';
import '../../data/services/property_management_api_service.dart';
import '../../viewmodels/app_view_models.dart';
import '../widgets/app_widgets.dart';

class PropertyScreen extends StatelessWidget {
  const PropertyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PropertyViewModel>();

    return ListView(
      padding: screenPadding,
      children: [
        ScreenHeader(
          title: context.tr(
            bn: 'Property Management',
            en: 'Property Management',
          ),
          subtitle: context.tr(
            bn: 'Manage buildings, floors, and units in a clear hierarchy.',
            en: 'Manage buildings, floors, and units in a clear hierarchy.',
          ),
          trailing: FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AddBuildingScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: Text(context.tr(bn: 'Building', en: 'Building')),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AddFloorScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.layers_outlined),
                label: Text(context.tr(bn: 'Add Floor', en: 'Add Floor')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AddUnitScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.door_front_door_outlined),
                label: Text(context.tr(bn: 'Add Unit', en: 'Add Unit')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: context.tr(bn: 'Building List', en: 'Building List'),
          child: Column(
            children: viewModel.buildings
                .map(
                  (building) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BuildingTile(building: building),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: context.tr(bn: 'Unit Directory', en: 'Unit Directory'),
          child: Column(
            children: viewModel.properties
                .map(
                  (property) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _UnitDirectoryTile(property: property),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class BuildingFloorsScreen extends StatelessWidget {
  const BuildingFloorsScreen({super.key, required this.building});

  final BuildingBlock building;

  Future<void> _deleteBuilding(
    BuildContext context,
    BuildingBlock currentBuilding,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr(bn: 'Delete', en: 'Delete')),
          content: Text(
            context.tr(
              bn: 'Do you want to delete ${currentBuilding.name}?',
              en: 'Do you want to delete ${currentBuilding.name}?',
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
      final propertyViewModel = context.read<PropertyViewModel>();
      final result = await propertyViewModel.deleteBuilding(
        buildingId: currentBuilding.id,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      Navigator.of(context).pop();
    } on PropertyManagementApiException catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _deleteFloor(BuildContext context, BuildingFloor floor) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr(bn: 'Delete', en: 'Delete')),
          content: Text(
            context.tr(
              bn: 'Do you want to delete ${floor.label}?',
              en: 'Do you want to delete ${floor.label}?',
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
      final propertyViewModel = context.read<PropertyViewModel>();
      final result = await propertyViewModel.deleteFloor(floorId: floor.id);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } on PropertyManagementApiException catch (error) {
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
    final viewModel = context.watch<PropertyViewModel>();
    final currentBuilding = viewModel.buildings.firstWhere(
      (item) => item.id == building.id,
      orElse: () => building,
    );
    final floors = viewModel.floorsForBuilding(currentBuilding.id);
    final units = viewModel.unitsForBuilding(currentBuilding.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr(
            bn: 'Floors (${currentBuilding.name})',
            en: 'Floors (${currentBuilding.name})',
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => EditBuildingScreen(building: currentBuilding),
                ),
              );
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: () => _deleteBuilding(context, currentBuilding),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      AddFloorScreen(initialBuildingId: currentBuilding.id),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: screenPadding,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentBuilding.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  currentBuilding.location,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 14),
                Text(
                  context.tr(
                    bn: '${building.totalFloors} floors • ${units.length} units',
                    en: '${building.totalFloors} floors • ${units.length} units',
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...floors.map(
            (floor) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(18),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => UnitsScreen(
                          building: currentBuilding,
                          floor: floor,
                        ),
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
                      Icons.layers_rounded,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  title: Text(floor.label),
                  subtitle: Text(
                    context.tr(
                      bn: '${floor.totalUnits} units',
                      en: '${floor.totalUnits} units',
                    ),
                  ),
                  trailing: Wrap(
                    spacing: 2,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => EditFloorScreen(floor: floor),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                      IconButton(
                        onPressed: () => _deleteFloor(context, floor),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UnitsScreen extends StatelessWidget {
  const UnitsScreen({super.key, required this.building, required this.floor});

  final BuildingBlock building;
  final BuildingFloor floor;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PropertyViewModel>();
    final units = viewModel.unitsForFloor(floor.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr(
            bn: 'Units (${floor.label})',
            en: 'Units (${floor.label})',
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AddUnitScreen(
                    initialBuildingId: building.id,
                    initialFloorId: floor.id,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: screenPadding,
        children: [
          Text(
            '${building.name} • ${floor.label}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          ...units.map(
            (unit) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(18),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PropertyDetailsScreen(property: unit),
                      ),
                    );
                  },
                  title: Text(unit.name),
                  subtitle: Text(context.money(unit.monthlyRent)),
                  trailing: StatusBadge.forProperty(context, unit.status),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PropertyDetailsScreen extends StatefulWidget {
  const PropertyDetailsScreen({super.key, required this.property});

  final PropertyUnit property;

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  late PropertyUnit _property;

  @override
  void initState() {
    super.initState();
    _property = widget.property;
  }

  Future<void> _editProperty() async {
    final updatedProperty = await Navigator.of(context).push<PropertyUnit>(
      MaterialPageRoute<PropertyUnit>(
        builder: (_) => EditUnitScreen(property: _property),
      ),
    );

    if (updatedProperty != null && mounted) {
      setState(() => _property = updatedProperty);
    }
  }

  Future<void> _deleteProperty() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr(bn: 'Delete', en: 'Delete')),
          content: Text(
            context.tr(
              bn: 'Do you want to delete ${_property.name}?',
              en: 'Do you want to delete ${_property.name}?',
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

    if (shouldDelete != true || !mounted) {
      return;
    }

    try {
      final result = await context.read<PropertyViewModel>().deleteProperty(
        propertyId: _property.id,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      Navigator.of(context).pop(true);
    } on PropertyManagementApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = _property;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr(
            bn: '${property.name} Details',
            en: '${property.name} Details',
          ),
        ),
      ),
      body: ListView(
        padding: screenPadding,
        children: [
          SectionCard(
            title: context.tr(bn: 'Unit Details', en: 'Unit Details'),
            child: Column(
              children: [
                InfoLine(
                  label: context.tr(bn: 'Rent', en: 'Rent'),
                  value: context.money(property.monthlyRent),
                ),
                InfoLine(
                  label: context.tr(bn: 'Location', en: 'Location'),
                  value: property.location,
                ),
                InfoLine(
                  label: context.tr(bn: 'Building', en: 'Building'),
                  value: property.buildingName ?? '-',
                ),
                InfoLine(
                  label: context.tr(bn: 'Floor', en: 'Floor'),
                  value: property.floorLabel ?? '-',
                ),
                InfoLine(
                  label: context.tr(bn: 'Tenant', en: 'Tenant'),
                  value:
                      property.tenantName ??
                      context.tr(bn: 'Vacant', en: 'Vacant'),
                ),
                InfoLine(
                  label: context.tr(bn: 'Status', en: 'Status'),
                  value: property.status == PropertyStatus.rented
                      ? context.tr(bn: 'Rented', en: 'Rented')
                      : context.tr(bn: 'Available', en: 'Available'),
                ),
                if (property.dueAmount > 0)
                  InfoLine(
                    label: context.tr(bn: 'Due Rent', en: 'Due Rent'),
                    value: context.money(property.dueAmount),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _editProperty,
            child: Text(context.tr(bn: 'Edit', en: 'Edit')),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _deleteProperty,
            child: Text(context.tr(bn: 'Delete', en: 'Delete')),
          ),
        ],
      ),
    );
  }
}

class AddBuildingScreen extends StatefulWidget {
  const AddBuildingScreen({super.key});

  @override
  State<AddBuildingScreen> createState() => _AddBuildingScreenState();
}

class _AddBuildingScreenState extends State<AddBuildingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _totalFloorsController = TextEditingController();
  final DhakaPoliceZoneApiService _dhakaPoliceZoneApiService =
      DhakaPoliceZoneApiService();

  DhakaPoliceCascadingOptions _areaOptions = const DhakaPoliceCascadingOptions(
    zones: [],
    stations: [],
    wards: [],
  );
  String? _selectedZoneId;
  String? _selectedStationId;
  int? _selectedWardId;
  bool _isLoadingAreaOptions = true;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  String? _areaErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadAreaOptions();
    _loadCurrentLocation(showSuccessMessage: false);
  }

  @override
  void dispose() {
    _dhakaPoliceZoneApiService.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _totalFloorsController.dispose();
    super.dispose();
  }

  Future<void> _loadAreaOptions({String? zoneId, String? stationId}) async {
    setState(() {
      _isLoadingAreaOptions = true;
      _areaErrorMessage = null;
    });

    try {
      final options = await _dhakaPoliceZoneApiService.getCascadingOptions(
        zoneId: zoneId,
        stationId: stationId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _areaOptions = options;
        _selectedZoneId = _readValidZoneId(zoneId ?? _selectedZoneId, options);
        _selectedStationId = _readValidStationId(
          stationId ?? _selectedStationId,
          options,
        );
        _selectedWardId = _readValidWardId(_selectedWardId, options);
        _isLoadingAreaOptions = false;
      });
    } on DhakaPoliceZoneApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _areaErrorMessage = error.message;
        _isLoadingAreaOptions = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _areaErrorMessage = 'Unable to load area options. Please try again.';
        _isLoadingAreaOptions = false;
      });
    }
  }

  Future<void> _submit() async {
    final totalFloors = int.tryParse(_totalFloorsController.text.trim());
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    final validationMessage = _buildingDetailsValidationMessage(
      context,
      name: _nameController.text,
      address: _addressController.text,
      latitude: latitude,
      longitude: longitude,
      selectedZoneId: _selectedZoneId,
      selectedStationId: _selectedStationId,
      selectedWardId: _selectedWardId,
      totalFloors: totalFloors,
    );
    if (validationMessage != null) {
      _showMessage(validationMessage);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await context.read<PropertyViewModel>().createBuilding(
        name: _nameController.text.trim(),
        location: _addressController.text.trim(),
        totalFloors: totalFloors!,
        address: _addressController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        zoneId: _selectedZoneId,
        stationId: _selectedStationId,
        wardId: _selectedWardId,
      );

      if (!mounted) {
        return;
      }

      _showMessage(result.message);
      Navigator.of(context).pop();
    } on PropertyManagementApiException catch (error) {
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

  Future<void> _loadCurrentLocation({bool showSuccessMessage = true}) async {
    if (_isLoadingLocation) {
      return;
    }

    setState(() => _isLoadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) {
        return;
      }

      if (!serviceEnabled) {
        _showMessage(
          context.tr(
            bn: 'Please turn on device location.',
            en: 'Please turn on device location.',
          ),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (!mounted) {
        return;
      }

      if (permission == LocationPermission.denied) {
        _showMessage(
          context.tr(
            bn: 'Location permission is required.',
            en: 'Location permission is required.',
          ),
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage(
          context.tr(
            bn: 'Enable location permission from app settings.',
            en: 'Enable location permission from app settings.',
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
      });

      if (showSuccessMessage) {
        _showMessage(
          context.tr(bn: 'GPS location loaded.', en: 'GPS location loaded.'),
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          context.tr(
            bn: 'Unable to load GPS location.',
            en: 'Unable to load GPS location.',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  String? _readValidZoneId(String? value, DhakaPoliceCascadingOptions options) {
    if (value == null) {
      return null;
    }

    return options.zones.any((zone) => zone.id == value) ? value : null;
  }

  String? _readValidStationId(
    String? value,
    DhakaPoliceCascadingOptions options,
  ) {
    if (value == null) {
      return null;
    }

    return options.stations.any((station) => station.id == value)
        ? value
        : null;
  }

  int? _readValidWardId(int? value, DhakaPoliceCascadingOptions options) {
    if (value == null) {
      return null;
    }

    return options.wards.any((ward) => ward.id == value) ? value : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(bn: 'Add Building', en: 'Add Building')),
      ),
      body: ListView(
        padding: screenPadding,
        children: [
          EntryTextField(
            controller: _nameController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Building Name', en: 'Building Name'),
            hint: context.tr(bn: 'Enter name', en: 'Enter name'),
            icon: Icons.business_rounded,
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _addressController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Address', en: 'Address'),
            hint: context.tr(bn: 'House, road, area', en: 'House, road, area'),
            icon: Icons.place_outlined,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: EntryTextField(
                  controller: _latitudeController,
                  enabled: !_isSubmitting && !_isLoadingLocation,
                  label: context.tr(bn: 'Latitude', en: 'Latitude'),
                  hint: context.tr(bn: '23.8103', en: '23.8103'),
                  icon: Icons.my_location_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: EntryTextField(
                  controller: _longitudeController,
                  enabled: !_isSubmitting && !_isLoadingLocation,
                  label: context.tr(bn: 'Longitude', en: 'Longitude'),
                  hint: context.tr(bn: '90.4125', en: '90.4125'),
                  icon: Icons.explore_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 31),
                child: IconButton.filledTonal(
                  tooltip: context.tr(
                    bn: 'Use current GPS location',
                    en: 'Use current GPS location',
                  ),
                  onPressed: _isSubmitting || _isLoadingLocation
                      ? null
                      : _loadCurrentLocation,
                  icon: _isLoadingLocation
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingAreaOptions) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
          ],
          if (_areaErrorMessage != null) ...[
            Text(
              _areaErrorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
          ],
          _LabeledDropdown(
            label: context.tr(bn: 'Police Zone', en: 'Police Zone'),
            hint: context.tr(bn: 'Select zone', en: 'Select zone'),
            value: _selectedZoneId,
            items: _areaOptions.zones
                .map(
                  (zone) => DropdownMenuItem<String>(
                    value: zone.id,
                    child: Text(context.tr(bn: zone.nameBn, en: zone.nameEn)),
                  ),
                )
                .toList(growable: false),
            onChanged: _isLoadingAreaOptions
                ? null
                : (value) {
                    setState(() {
                      _selectedZoneId = value;
                      _selectedStationId = null;
                      _selectedWardId = null;
                    });
                    _loadAreaOptions(zoneId: value);
                  },
          ),
          const SizedBox(height: 16),
          _LabeledDropdown(
            label: context.tr(bn: 'Police Station', en: 'Police Station'),
            hint: context.tr(bn: 'Select station', en: 'Select station'),
            value: _selectedStationId,
            items: _areaOptions.stations
                .map(
                  (station) => DropdownMenuItem<String>(
                    value: station.id,
                    child: Text(
                      context.tr(bn: station.nameBn, en: station.nameEn),
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: _isLoadingAreaOptions || _selectedZoneId == null
                ? null
                : (value) {
                    setState(() {
                      _selectedStationId = value;
                      _selectedWardId = null;
                    });
                    _loadAreaOptions(zoneId: _selectedZoneId, stationId: value);
                  },
          ),
          const SizedBox(height: 16),
          _LabeledIntDropdown(
            label: context.tr(bn: 'Ward', en: 'Ward'),
            hint: context.tr(bn: 'Select ward', en: 'Select ward'),
            value: _selectedWardId,
            items: _areaOptions.wards
                .map(
                  (ward) => DropdownMenuItem<int>(
                    value: ward.id,
                    child: Text(context.tr(bn: ward.nameBn, en: ward.nameEn)),
                  ),
                )
                .toList(growable: false),
            onChanged: _isLoadingAreaOptions || _selectedStationId == null
                ? null
                : (value) => setState(() => _selectedWardId = value),
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _totalFloorsController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Total Floors', en: 'Total Floors'),
            hint: context.tr(bn: 'Enter number', en: 'Enter number'),
            icon: Icons.layers_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(context.tr(bn: 'Save Building', en: 'Save Building')),
          ),
        ],
      ),
    );
  }
}

class EditBuildingScreen extends StatefulWidget {
  const EditBuildingScreen({super.key, required this.building});

  final BuildingBlock building;

  @override
  State<EditBuildingScreen> createState() => _EditBuildingScreenState();
}

class _EditBuildingScreenState extends State<EditBuildingScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _totalFloorsController;
  final DhakaPoliceZoneApiService _dhakaPoliceZoneApiService =
      DhakaPoliceZoneApiService();

  DhakaPoliceCascadingOptions _areaOptions = const DhakaPoliceCascadingOptions(
    zones: [],
    stations: [],
    wards: [],
  );
  String? _selectedZoneId;
  String? _selectedStationId;
  int? _selectedWardId;
  bool _isLoadingAreaOptions = true;
  bool _isSubmitting = false;
  String? _areaErrorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.building.name);
    _addressController = TextEditingController(
      text: widget.building.address ?? widget.building.location,
    );
    _latitudeController = TextEditingController(
      text: widget.building.latitude?.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: widget.building.longitude?.toString() ?? '',
    );
    _totalFloorsController = TextEditingController(
      text: widget.building.totalFloors.toString(),
    );
    _selectedZoneId = widget.building.zoneId;
    _selectedStationId = widget.building.stationId;
    _selectedWardId = widget.building.wardId;
    _loadAreaOptions(zoneId: _selectedZoneId, stationId: _selectedStationId);
  }

  @override
  void dispose() {
    _dhakaPoliceZoneApiService.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _totalFloorsController.dispose();
    super.dispose();
  }

  Future<void> _loadAreaOptions({String? zoneId, String? stationId}) async {
    setState(() {
      _isLoadingAreaOptions = true;
      _areaErrorMessage = null;
    });

    try {
      final options = await _dhakaPoliceZoneApiService.getCascadingOptions(
        zoneId: zoneId,
        stationId: stationId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _areaOptions = options;
        _selectedZoneId = _readValidZoneId(zoneId ?? _selectedZoneId, options);
        _selectedStationId = _readValidStationId(
          stationId ?? _selectedStationId,
          options,
        );
        _selectedWardId = _readValidWardId(_selectedWardId, options);
        _isLoadingAreaOptions = false;
      });
    } on DhakaPoliceZoneApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _areaErrorMessage = error.message;
        _isLoadingAreaOptions = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _areaErrorMessage = 'Unable to load area options. Please try again.';
        _isLoadingAreaOptions = false;
      });
    }
  }

  Future<void> _submit() async {
    final totalFloors = int.tryParse(_totalFloorsController.text.trim());
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    final validationMessage = _buildingDetailsValidationMessage(
      context,
      name: _nameController.text,
      address: _addressController.text,
      latitude: latitude,
      longitude: longitude,
      selectedZoneId: _selectedZoneId,
      selectedStationId: _selectedStationId,
      selectedWardId: _selectedWardId,
      totalFloors: totalFloors,
    );
    if (validationMessage != null) {
      _showMessage(validationMessage);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await context.read<PropertyViewModel>().updateBuilding(
        buildingId: widget.building.id,
        name: _nameController.text.trim(),
        location: _addressController.text.trim(),
        totalFloors: totalFloors!,
        address: _addressController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        zoneId: _selectedZoneId,
        stationId: _selectedStationId,
        wardId: _selectedWardId,
      );

      if (!mounted) {
        return;
      }

      _showMessage(result.message);
      Navigator.of(context).pop();
    } on PropertyManagementApiException catch (error) {
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

  String? _readValidZoneId(String? value, DhakaPoliceCascadingOptions options) {
    if (value == null) {
      return null;
    }

    return options.zones.any((zone) => zone.id == value) ? value : null;
  }

  String? _readValidStationId(
    String? value,
    DhakaPoliceCascadingOptions options,
  ) {
    if (value == null) {
      return null;
    }

    return options.stations.any((station) => station.id == value)
        ? value
        : null;
  }

  int? _readValidWardId(int? value, DhakaPoliceCascadingOptions options) {
    if (value == null) {
      return null;
    }

    return options.wards.any((ward) => ward.id == value) ? value : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(bn: 'Edit Building', en: 'Edit Building')),
      ),
      body: ListView(
        padding: screenPadding,
        children: [
          EntryTextField(
            controller: _nameController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Building Name', en: 'Building Name'),
            hint: context.tr(bn: 'Enter name', en: 'Enter name'),
            icon: Icons.business_rounded,
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _addressController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Address', en: 'Address'),
            hint: context.tr(bn: 'House, road, area', en: 'House, road, area'),
            icon: Icons.place_outlined,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: EntryTextField(
                  controller: _latitudeController,
                  enabled: !_isSubmitting,
                  label: context.tr(bn: 'Latitude', en: 'Latitude'),
                  hint: context.tr(bn: '23.8103', en: '23.8103'),
                  icon: Icons.my_location_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: EntryTextField(
                  controller: _longitudeController,
                  enabled: !_isSubmitting,
                  label: context.tr(bn: 'Longitude', en: 'Longitude'),
                  hint: context.tr(bn: '90.4125', en: '90.4125'),
                  icon: Icons.explore_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingAreaOptions) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
          ],
          if (_areaErrorMessage != null) ...[
            Text(
              _areaErrorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
          ],
          _LabeledDropdown(
            label: context.tr(bn: 'Police Zone', en: 'Police Zone'),
            hint: context.tr(bn: 'Select zone', en: 'Select zone'),
            value: _selectedZoneId,
            items: _areaOptions.zones
                .map(
                  (zone) => DropdownMenuItem<String>(
                    value: zone.id,
                    child: Text(context.tr(bn: zone.nameBn, en: zone.nameEn)),
                  ),
                )
                .toList(growable: false),
            onChanged: _isLoadingAreaOptions
                ? null
                : (value) {
                    setState(() {
                      _selectedZoneId = value;
                      _selectedStationId = null;
                      _selectedWardId = null;
                    });
                    _loadAreaOptions(zoneId: value);
                  },
          ),
          const SizedBox(height: 16),
          _LabeledDropdown(
            label: context.tr(bn: 'Police Station', en: 'Police Station'),
            hint: context.tr(bn: 'Select station', en: 'Select station'),
            value: _selectedStationId,
            items: _areaOptions.stations
                .map(
                  (station) => DropdownMenuItem<String>(
                    value: station.id,
                    child: Text(
                      context.tr(bn: station.nameBn, en: station.nameEn),
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: _isLoadingAreaOptions || _selectedZoneId == null
                ? null
                : (value) {
                    setState(() {
                      _selectedStationId = value;
                      _selectedWardId = null;
                    });
                    _loadAreaOptions(zoneId: _selectedZoneId, stationId: value);
                  },
          ),
          const SizedBox(height: 16),
          _LabeledIntDropdown(
            label: context.tr(bn: 'Ward', en: 'Ward'),
            hint: context.tr(bn: 'Select ward', en: 'Select ward'),
            value: _selectedWardId,
            items: _areaOptions.wards
                .map(
                  (ward) => DropdownMenuItem<int>(
                    value: ward.id,
                    child: Text(context.tr(bn: ward.nameBn, en: ward.nameEn)),
                  ),
                )
                .toList(growable: false),
            onChanged: _isLoadingAreaOptions || _selectedStationId == null
                ? null
                : (value) => setState(() => _selectedWardId = value),
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _totalFloorsController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Total Floors', en: 'Total Floors'),
            hint: context.tr(bn: 'Enter number', en: 'Enter number'),
            icon: Icons.layers_rounded,
            keyboardType: TextInputType.number,
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

class AddFloorScreen extends StatefulWidget {
  const AddFloorScreen({super.key, this.initialBuildingId});

  final String? initialBuildingId;

  @override
  State<AddFloorScreen> createState() => _AddFloorScreenState();
}

class _AddFloorScreenState extends State<AddFloorScreen> {
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _totalUnitsController = TextEditingController();

  String? _selectedBuildingId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<PropertyViewModel>();
    _selectedBuildingId =
        widget.initialBuildingId ??
        (viewModel.buildings.isEmpty ? null : viewModel.buildings.first.id);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _totalUnitsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final buildingId = _selectedBuildingId;
    final totalUnits = int.tryParse(_totalUnitsController.text.trim());
    if (buildingId == null ||
        _labelController.text.trim().isEmpty ||
        totalUnits == null ||
        totalUnits <= 0) {
      _showMessage('Enter valid floor details.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await context.read<PropertyViewModel>().createFloor(
        buildingId: buildingId,
        label: _labelController.text.trim(),
        totalUnits: totalUnits,
      );

      if (!mounted) {
        return;
      }

      _showMessage(result.message);
      Navigator.of(context).pop();
    } on PropertyManagementApiException catch (error) {
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
    final viewModel = context.watch<PropertyViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(bn: 'Add Floor', en: 'Add Floor')),
      ),
      body: ListView(
        padding: screenPadding,
        children: [
          _LabeledDropdown(
            label: context.tr(bn: 'Select Building', en: 'Select Building'),
            value: _selectedBuildingId,
            items: viewModel.buildings
                .map(
                  (building) => DropdownMenuItem<String>(
                    value: building.id,
                    child: Text(building.name),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              setState(() {
                _selectedBuildingId = value;
              });
            },
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _labelController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Floor Number', en: 'Floor Number'),
            hint: context.tr(bn: 'Example: 1', en: 'Example: 1'),
            icon: Icons.format_list_numbered_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _totalUnitsController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Total Units', en: 'Total Units'),
            hint: context.tr(bn: 'Example: 4', en: 'Example: 4'),
            icon: Icons.grid_view_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(context.tr(bn: 'Save Floor', en: 'Save Floor')),
          ),
        ],
      ),
    );
  }
}

class EditFloorScreen extends StatefulWidget {
  const EditFloorScreen({super.key, required this.floor});

  final BuildingFloor floor;

  @override
  State<EditFloorScreen> createState() => _EditFloorScreenState();
}

class _EditFloorScreenState extends State<EditFloorScreen> {
  late final TextEditingController _labelController;
  late final TextEditingController _totalUnitsController;
  String? _selectedBuildingId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.floor.label);
    _totalUnitsController = TextEditingController(
      text: widget.floor.totalUnits.toString(),
    );
    _selectedBuildingId = widget.floor.buildingId;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _totalUnitsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final buildingId = _selectedBuildingId;
    final totalUnits = int.tryParse(_totalUnitsController.text.trim());
    if (buildingId == null ||
        _labelController.text.trim().isEmpty ||
        totalUnits == null ||
        totalUnits <= 0) {
      _showMessage('Enter valid floor details.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await context.read<PropertyViewModel>().updateFloor(
        floorId: widget.floor.id,
        buildingId: buildingId,
        label: _labelController.text.trim(),
        totalUnits: totalUnits,
      );

      if (!mounted) {
        return;
      }

      _showMessage(result.message);
      Navigator.of(context).pop();
    } on PropertyManagementApiException catch (error) {
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
    final viewModel = context.watch<PropertyViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(bn: 'Edit Floor', en: 'Edit Floor')),
      ),
      body: ListView(
        padding: screenPadding,
        children: [
          _LabeledDropdown(
            label: context.tr(bn: 'Select Building', en: 'Select Building'),
            value: _selectedBuildingId,
            items: viewModel.buildings
                .map(
                  (building) => DropdownMenuItem<String>(
                    value: building.id,
                    child: Text(building.name),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              setState(() {
                _selectedBuildingId = value;
              });
            },
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _labelController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Floor Number', en: 'Floor Number'),
            hint: context.tr(bn: 'Example: 1', en: 'Example: 1'),
            icon: Icons.format_list_numbered_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _totalUnitsController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Total Units', en: 'Total Units'),
            hint: context.tr(bn: 'Example: 4', en: 'Example: 4'),
            icon: Icons.grid_view_rounded,
            keyboardType: TextInputType.number,
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

class AddUnitScreen extends StatefulWidget {
  const AddUnitScreen({super.key, this.initialBuildingId, this.initialFloorId});

  final String? initialBuildingId;
  final String? initialFloorId;

  @override
  State<AddUnitScreen> createState() => _AddUnitScreenState();
}

class _AddUnitScreenState extends State<AddUnitScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rentController = TextEditingController();

  String? _selectedBuildingId;
  String? _selectedFloorId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<PropertyViewModel>();
    _selectedBuildingId =
        widget.initialBuildingId ??
        (viewModel.buildings.isEmpty ? null : viewModel.buildings.first.id);
    final floors = _selectedBuildingId == null
        ? <BuildingFloor>[]
        : viewModel.floorsForBuilding(_selectedBuildingId!);
    _selectedFloorId =
        widget.initialFloorId ?? (floors.isEmpty ? null : floors.first.id);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final buildingId = _selectedBuildingId;
    final floorId = _selectedFloorId;
    final monthlyRent = int.tryParse(_rentController.text.trim());
    if (buildingId == null ||
        floorId == null ||
        _nameController.text.trim().isEmpty ||
        monthlyRent == null ||
        monthlyRent <= 0) {
      _showMessage('Enter valid unit details.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await context.read<PropertyViewModel>().createProperty(
        name: _nameController.text.trim(),
        monthlyRent: monthlyRent,
        buildingId: buildingId,
        floorId: floorId,
      );

      if (!mounted) {
        return;
      }

      _showMessage(result.message);
      Navigator.of(context).pop();
    } on PropertyManagementApiException catch (error) {
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
    final viewModel = context.watch<PropertyViewModel>();
    final floors = _selectedBuildingId == null
        ? <BuildingFloor>[]
        : viewModel.floorsForBuilding(_selectedBuildingId!);
    if (floors.isNotEmpty &&
        !floors.any((floor) => floor.id == _selectedFloorId)) {
      _selectedFloorId = floors.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(bn: 'Add Unit', en: 'Add Unit')),
      ),
      body: ListView(
        padding: screenPadding,
        children: [
          _LabeledDropdown(
            label: context.tr(bn: 'Building', en: 'Building'),
            value: _selectedBuildingId,
            items: viewModel.buildings
                .map(
                  (building) => DropdownMenuItem<String>(
                    value: building.id,
                    child: Text(building.name),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedBuildingId = value;
                final nextFloors = viewModel.floorsForBuilding(value);
                _selectedFloorId = nextFloors.isEmpty
                    ? null
                    : nextFloors.first.id;
              });
            },
          ),
          const SizedBox(height: 16),
          _LabeledDropdown(
            label: context.tr(bn: 'Floor', en: 'Floor'),
            value: _selectedFloorId,
            items: floors
                .map(
                  (floor) => DropdownMenuItem<String>(
                    value: floor.id,
                    child: Text(floor.label),
                  ),
                )
                .toList(growable: false),
            onChanged: floors.isEmpty
                ? null
                : (value) {
                    setState(() => _selectedFloorId = value);
                  },
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _nameController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Unit Name', en: 'Unit Name'),
            hint: context.tr(bn: 'Example: 1A', en: 'Example: 1A'),
            icon: Icons.meeting_room_outlined,
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _rentController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Rent Amount', en: 'Rent Amount'),
            hint: context.tr(bn: '5000', en: '5000'),
            icon: Icons.payments_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(context.tr(bn: 'Save Unit', en: 'Save Unit')),
          ),
        ],
      ),
    );
  }
}

class EditUnitScreen extends StatefulWidget {
  const EditUnitScreen({super.key, required this.property});

  final PropertyUnit property;

  @override
  State<EditUnitScreen> createState() => _EditUnitScreenState();
}

class _EditUnitScreenState extends State<EditUnitScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _rentController;

  String? _selectedBuildingId;
  String? _selectedFloorId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<PropertyViewModel>();
    _nameController = TextEditingController(text: widget.property.name);
    _rentController = TextEditingController(
      text: widget.property.monthlyRent.toString(),
    );
    _selectedBuildingId =
        widget.property.buildingId ??
        (viewModel.buildings.isEmpty ? null : viewModel.buildings.first.id);
    final floors = _selectedBuildingId == null
        ? <BuildingFloor>[]
        : viewModel.floorsForBuilding(_selectedBuildingId!);
    _selectedFloorId =
        widget.property.floorId ?? (floors.isEmpty ? null : floors.first.id);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final buildingId = _selectedBuildingId;
    final floorId = _selectedFloorId;
    final monthlyRent = int.tryParse(_rentController.text.trim());
    if (buildingId == null ||
        floorId == null ||
        _nameController.text.trim().isEmpty ||
        monthlyRent == null ||
        monthlyRent <= 0) {
      _showMessage('Enter valid unit details.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await context.read<PropertyViewModel>().updateProperty(
        propertyId: widget.property.id,
        name: _nameController.text.trim(),
        monthlyRent: monthlyRent,
        buildingId: buildingId,
        floorId: floorId,
      );

      if (!mounted) {
        return;
      }

      _showMessage(result.message);
      Navigator.of(context).pop(result.property);
    } on PropertyManagementApiException catch (error) {
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
    final viewModel = context.watch<PropertyViewModel>();
    final floors = _selectedBuildingId == null
        ? <BuildingFloor>[]
        : viewModel.floorsForBuilding(_selectedBuildingId!);
    if (floors.isNotEmpty &&
        !floors.any((floor) => floor.id == _selectedFloorId)) {
      _selectedFloorId = floors.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(bn: 'Edit Unit', en: 'Edit Unit')),
      ),
      body: ListView(
        padding: screenPadding,
        children: [
          _LabeledDropdown(
            label: context.tr(bn: 'Building', en: 'Building'),
            value: _selectedBuildingId,
            items: viewModel.buildings
                .map(
                  (building) => DropdownMenuItem<String>(
                    value: building.id,
                    child: Text(building.name),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedBuildingId = value;
                final nextFloors = viewModel.floorsForBuilding(value);
                _selectedFloorId = nextFloors.isEmpty
                    ? null
                    : nextFloors.first.id;
              });
            },
          ),
          const SizedBox(height: 16),
          _LabeledDropdown(
            label: context.tr(bn: 'Floor', en: 'Floor'),
            value: _selectedFloorId,
            items: floors
                .map(
                  (floor) => DropdownMenuItem<String>(
                    value: floor.id,
                    child: Text(floor.label),
                  ),
                )
                .toList(growable: false),
            onChanged: floors.isEmpty
                ? null
                : (value) {
                    setState(() => _selectedFloorId = value);
                  },
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _nameController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Unit Name', en: 'Unit Name'),
            hint: context.tr(bn: 'Example: 1A', en: 'Example: 1A'),
            icon: Icons.meeting_room_outlined,
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _rentController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Rent Amount', en: 'Rent Amount'),
            hint: context.tr(bn: '5000', en: '5000'),
            icon: Icons.payments_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(context.tr(bn: 'Save', en: 'Save')),
          ),
        ],
      ),
    );
  }
}

class _BuildingTile extends StatelessWidget {
  const _BuildingTile({required this.building});

  final BuildingBlock building;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => BuildingFloorsScreen(building: building),
            ),
          );
        },
        leading: Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.business_rounded,
            color: AppColors.primaryDark,
          ),
        ),
        title: Text(building.name),
        subtitle: Text(
          context.tr(
            bn: '${building.totalFloors} floors • ${building.location}',
            en: '${building.totalFloors} floors • ${building.location}',
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
      ),
    );
  }
}

String? _buildingDetailsValidationMessage(
  BuildContext context, {
  required String name,
  required String address,
  required double? latitude,
  required double? longitude,
  required String? selectedZoneId,
  required String? selectedStationId,
  required int? selectedWardId,
  required int? totalFloors,
}) {
  if (name.trim().length < 2) {
    return context.tr(bn: 'Building name din.', en: 'Enter building name.');
  }

  if (address.trim().length < 3) {
    return context.tr(
      bn: 'Building address din.',
      en: 'Enter building address.',
    );
  }

  if (latitude == null || longitude == null) {
    return context.tr(
      bn: 'GPS location load korun or latitude/longitude din.',
      en: 'Load GPS location or enter latitude/longitude.',
    );
  }

  if (selectedZoneId == null) {
    return context.tr(
      bn: 'Police zone select korun.',
      en: 'Select police zone.',
    );
  }

  if (selectedStationId == null) {
    return context.tr(
      bn: 'Police station select korun.',
      en: 'Select police station.',
    );
  }

  if (selectedWardId == null) {
    return context.tr(bn: 'Ward select korun.', en: 'Select ward.');
  }

  if (totalFloors == null || totalFloors <= 0) {
    return context.tr(
      bn: 'Valid total floors din.',
      en: 'Enter valid total floors.',
    );
  }

  return null;
}

class _UnitDirectoryTile extends StatelessWidget {
  const _UnitDirectoryTile({required this.property});

  final PropertyUnit property;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PropertyDetailsScreen(property: property),
            ),
          );
        },
        title: Text(property.name),
        subtitle: Text(
          '${context.money(property.monthlyRent)} • ${property.buildingName} • ${property.floorLabel}',
        ),
        trailing: StatusBadge.forProperty(context, property.status),
      ),
    );
  }
}

class _LabeledDropdown extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final String? hint;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hint ?? label),
          disabledHint: Text(hint ?? label),
          items: items,
          onChanged: onChanged,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }
}

class _LabeledIntDropdown extends StatelessWidget {
  const _LabeledIntDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final String? hint;
  final int? value;
  final List<DropdownMenuItem<int>> items;
  final ValueChanged<int?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          value: value,
          hint: Text(hint ?? label),
          disabledHint: Text(hint ?? label),
          items: items,
          onChanged: onChanged,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }
}
