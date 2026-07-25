import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/services/auth_session_service.dart';
import '../../../data/services/sos_api_service.dart';

class EmergencySosScreen extends StatefulWidget {
  const EmergencySosScreen({super.key});

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen> {
  final _sosApiService = SosApiService();

  String? _userId;
  List<SosEmergencyContact> _contacts = [];
  List<SosEmergencyService> _services = [];
  List<SosSafetyTip> _tips = [];
  bool _isLoading = true;
  bool _isSendingSos = false;
  Timer? _safetyTimer;
  int _safetyTimerSecondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _loadSosData();
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _sosApiService.dispose();
    super.dispose();
  }

  Future<void> _loadSosData() async {
    final session = await AuthSessionService().readSession();
    final userId = session?.userId.trim();

    if (mounted) {
      setState(() {
        _userId = userId == null || userId.isEmpty ? null : userId;
        _isLoading = true;
      });
    }

    try {
      final results = await Future.wait([
        if (userId != null && userId.isNotEmpty)
          _sosApiService.getContacts(userId)
        else
          Future<List<SosEmergencyContact>>.value([]),
        _sosApiService.getEmergencyServices(),
        _sosApiService.getSafetyTips(),
      ]);

      if (!mounted) return;
      setState(() {
        _contacts = results[0] as List<SosEmergencyContact>;
        _services = results[1] as List<SosEmergencyService>;
        _tips = results[2] as List<SosSafetyTip>;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('SOS data load failed: $error');
    }
  }

  Future<void> _sendSosAlert() async {
    final userId = _requireUserId();
    if (userId == null || _isSendingSos) return;

    setState(() => _isSendingSos = true);
    try {
      final position = await _getCurrentPositionOrNull();
      await _sosApiService.triggerAlert(
        userId,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );
      if (!mounted) return;
      _showMessage('SOS alert sent successfully.', color: Colors.red);
    } catch (error) {
      if (!mounted) return;
      _showMessage('Failed to send SOS alert: $error');
    } finally {
      if (mounted) setState(() => _isSendingSos = false);
    }
  }

  Future<void> _shareLiveLocation() async {
    final userId = _requireUserId();
    if (userId == null) return;

    try {
      final position = await _getCurrentPositionOrNull();
      if (position == null) {
        _showMessage('Location permission or GPS is not available.');
        return;
      }

      await _sosApiService.updateLocation(
        userId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;
      _showMessage('Live location updated.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Location update failed: $error');
    }
  }

  Future<Position?> _getCurrentPositionOrNull() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  Future<void> _showAddContactDialog() async {
    final userId = _requireUserId();
    if (userId == null) return;

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add emergency contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: relationController,
              decoration: const InputDecoration(labelText: 'Relation'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave != true) return;

    try {
      await _sosApiService.addContact(
        userId: userId,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        relation: relationController.text.trim().isEmpty
            ? null
            : relationController.text.trim(),
      );
      await _loadSosData();
      if (!mounted) return;
      _showMessage('Contact added successfully.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Contact add failed: $error');
    }
  }

  Future<void> _removeContact(SosEmergencyContact contact) async {
    final userId = _requireUserId();
    if (userId == null) return;

    try {
      await _sosApiService.removeContact(userId: userId, contactId: contact.id);
      await _loadSosData();
      if (!mounted) return;
      _showMessage('Contact removed.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Contact remove failed: $error');
    }
  }

  Future<void> _saveEvidence(String fileType) async {
    final userId = _requireUserId();
    if (userId == null) return;

    final result = await FilePicker.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    final file = result?.files.single;
    final path = file?.path ?? file?.name;
    if (path == null || path.trim().isEmpty) return;

    try {
      await _sosApiService.saveEvidence(
        userId: userId,
        fileUrl: path,
        fileType: fileType,
      );
      if (!mounted) return;
      _showMessage('$fileType evidence saved.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Evidence save failed: $error');
    }
  }

  Future<void> _showSafetyTimerDialog() async {
    final minutes = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Safety timer',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('No response after this time will trigger SOS.'),
            ),
            for (final value in const [5, 10, 15, 30])
              ListTile(
                leading: const Icon(Icons.timer_rounded),
                title: Text('$value minutes'),
                onTap: () => Navigator.of(context).pop(value),
              ),
            if (_safetyTimer != null)
              ListTile(
                leading: const Icon(Icons.cancel_rounded),
                title: const Text('Cancel active timer'),
                onTap: () => Navigator.of(context).pop(0),
              ),
          ],
        ),
      ),
    );

    if (minutes == null) return;
    if (minutes == 0) {
      _cancelSafetyTimer();
      return;
    }

    _startSafetyTimer(minutes);
  }

  void _startSafetyTimer(int minutes) {
    _safetyTimer?.cancel();
    setState(() => _safetyTimerSecondsLeft = minutes * 60);

    _safetyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_safetyTimerSecondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _safetyTimer = null;
          _safetyTimerSecondsLeft = 0;
        });
        _sendSosAlert();
        return;
      }

      setState(() => _safetyTimerSecondsLeft--);
    });

    _showMessage('Safety timer started for $minutes minutes.');
  }

  void _cancelSafetyTimer() {
    _safetyTimer?.cancel();
    setState(() {
      _safetyTimer = null;
      _safetyTimerSecondsLeft = 0;
    });
    _showMessage('Safety timer cancelled.');
  }

  Future<void> _callNumber(String phone) async {
    final normalized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (normalized.isEmpty) return;

    final uri = Uri(scheme: 'tel', path: normalized);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      _showMessage('Could not open phone dialer.');
    }
  }

  String? _requireUserId() {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      _showMessage('Please login first.');
      return null;
    }
    return userId;
  }

  void _showMessage(String message, {Color? color}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  void _showServicesSheet() {
    _showListSheet(
      title: 'Emergency services',
      emptyText: 'No emergency services found.',
      children: _services
          .map(
            (service) => ListTile(
              leading: const Icon(Icons.local_phone_rounded),
              title: Text(service.title),
              subtitle: Text('${service.type} - ${service.phone}'),
              trailing: IconButton(
                icon: const Icon(Icons.call_rounded, color: Colors.green),
                onPressed: () => _callNumber(service.phone),
              ),
            ),
          )
          .toList(),
    );
  }

  void _showTipsSheet() {
    _showListSheet(
      title: 'Safety tips',
      emptyText: 'No safety tips found.',
      children: _tips
          .map(
            (tip) => ListTile(
              leading: const Icon(Icons.security_rounded),
              title: Text(tip.title),
              subtitle: Text(tip.description),
            ),
          )
          .toList(),
    );
  }

  void _showContactsSheet() {
    _showListSheet(
      title: 'Emergency contacts',
      emptyText: 'No contact added yet.',
      action: TextButton.icon(
        onPressed: () {
          Navigator.of(context).pop();
          _showAddContactDialog();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
      children: _contacts
          .map(
            (contact) => ListTile(
              leading: CircleAvatar(child: Text(_initial(contact.name))),
              title: Text(contact.name),
              subtitle: Text(
                [
                  contact.phone,
                  if (contact.relation?.isNotEmpty == true) contact.relation!,
                ].join(' - '),
              ),
              trailing: Wrap(
                spacing: 2,
                children: [
                  IconButton(
                    icon: const Icon(Icons.call_rounded, color: Colors.green),
                    onPressed: () => _callNumber(contact.phone),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _removeContact(contact);
                    },
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  void _showListSheet({
    required String title,
    required String emptyText,
    required List<Widget> children,
    Widget? action,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (action != null) action,
                ],
              ),
              const SizedBox(height: 8),
              if (children.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(emptyText),
                )
              else
                Flexible(child: ListView(shrinkWrap: true, children: children)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'SOS Safety',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black),
            onPressed: _loadSosData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSosData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildTopBanner(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_isLoading) const LinearProgressIndicator(),
                  _buildGridOptions(),
                  const SizedBox(height: 16),
                  _buildSafetyTimer(),
                  const SizedBox(height: 16),
                  _buildLiveLocationShare(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      width: double.infinity,
      height: 210,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF7F1D1D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 20,
            bottom: 38,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency\nSafety',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'আপনার নিরাপত্তা,\nআমাদের অগ্রাধিকার',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            top: 36,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _showMessage('Press and hold for 3 seconds.'),
                  onLongPress: _sendSosAlert,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _sosRing(120, 0.25),
                      _sosRing(100, 0.45),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _isSendingSos
                              ? Colors.red.shade300
                              : Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isSendingSos
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'SOS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '৩ সেকেন্ড চাপুন\nজরুরি সাহায্য পাঠাতে',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sosRing(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.red.withValues(alpha: opacity),
          width: 1,
        ),
      ),
    );
  }

  Widget _buildGridOptions() {
    final options = <_SosGridAction>[
      _SosGridAction(
        icon: Icons.sos_rounded,
        title: 'SOS Alert',
        subtitle: 'জরুরি সাহায্য\nপাঠান',
        color: Colors.red,
        onTap: _sendSosAlert,
      ),
      _SosGridAction(
        icon: Icons.location_on_rounded,
        title: 'Live Location',
        subtitle: 'লোকেশন\nশেয়ার করুন',
        color: Colors.green,
        onTap: _shareLiveLocation,
      ),
      _SosGridAction(
        icon: Icons.phone_rounded,
        title: 'Contacts',
        subtitle: 'জরুরি\nযোগাযোগ',
        color: Colors.blue,
        onTap: _showContactsSheet,
      ),
      _SosGridAction(
        icon: Icons.local_police_rounded,
        title: 'Services',
        subtitle: 'পুলিশ/ফায়ার\nঅ্যাম্বুলেন্স',
        color: Colors.indigo,
        onTap: _showServicesSheet,
      ),
      _SosGridAction(
        icon: Icons.mic_rounded,
        title: 'Audio',
        subtitle: 'অডিও\nপ্রমাণ',
        color: Colors.orange,
        onTap: () => _saveEvidence('Audio'),
      ),
      _SosGridAction(
        icon: Icons.videocam_rounded,
        title: 'Video',
        subtitle: 'ভিডিও\nপ্রমাণ',
        color: Colors.blueAccent,
        onTap: () => _saveEvidence('Video'),
      ),
      _SosGridAction(
        icon: Icons.security_rounded,
        title: 'Safety Tips',
        subtitle: 'নিরাপত্তা\nটিপস',
        color: Colors.teal,
        onTap: _showTipsSheet,
      ),
      _SosGridAction(
        icon: Icons.photo_library_rounded,
        title: 'Evidence',
        subtitle: 'ছবি/ফাইল\nসংরক্ষণ',
        color: Colors.pink,
        onTap: () => _saveEvidence('Image'),
      ),
      _SosGridAction(
        icon: Icons.person_rounded,
        title: 'Fake Call',
        subtitle: 'নকল ফোন\nকল',
        color: Colors.amber,
        onTap: () => _showMessage('Fake call mode is ready locally.'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 128,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: option.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: option.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(option.icon, color: option.color, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    option.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSafetyTimer() {
    return _infoCard(
      icon: Icons.access_time_rounded,
      iconColor: Colors.deepPurple,
      title: 'Safety Timer',
      subtitle: _safetyTimerSecondsLeft > 0
          ? 'Auto SOS in ${_formatTimer(_safetyTimerSecondsLeft)}'
          : 'নির্ধারিত সময়ে সাড়া না পেলে অটো SOS পাঠানো হবে',
      buttonText: _safetyTimerSecondsLeft > 0 ? 'Cancel' : 'Set',
      onPressed: _safetyTimerSecondsLeft > 0
          ? _cancelSafetyTimer
          : _showSafetyTimerDialog,
    );
  }

  Widget _buildLiveLocationShare() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.people_rounded, color: Colors.blue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Live location share',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: _showAddContactDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_contacts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'কোনো কন্টাক্ট যোগ করা হয়নি',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _contacts
                    .map(
                      (contact) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onLongPress: () => _removeContact(contact),
                          onTap: () => _callNumber(contact.phone),
                          child: Column(
                            children: [
                              CircleAvatar(child: Text(_initial(contact.name))),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 76,
                                child: Text(
                                  contact.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  String _initial(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
  }

  String _formatTimer(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _SosGridAction {
  const _SosGridAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
}
