import 'package:flutter/foundation.dart';
import '../../data/models/device_model.dart';
import '../../data/services/roku_service.dart';
import '../../data/services/ssdp_service.dart';
import '../../data/services/google_tv_service.dart';
import '../../data/services/cast_discovery_service.dart';

class RokuController extends ChangeNotifier {
  final SsdpService _ssdpService = SsdpService();
  final RokuService _rokuService = RokuService();
  final GoogleTvService _googleTvService = GoogleTvService();
  final CastDiscoveryService _castDiscoveryService = CastDiscoveryService();

  List<DeviceModel> _discoveredDevices = [];
  DeviceModel? _selectedDevice;
  bool _isDiscovering = false;
  String? _error;
  bool _testMode = false;
  bool _discoverBoth = true; // Discover both Roku and Google TV by default
  final List<DeviceModel> _mockDevices = [
    DeviceModel(
      ipAddress: '192.168.1.100',
      type: DeviceType.roku,
      name: 'Roku Test Device',
    ),
    DeviceModel(
      ipAddress: '192.168.1.101',
      type: DeviceType.googleTv,
      name: 'Google TV Test Device',
    ),
  ];

  List<DeviceModel> get discoveredDevices => _discoveredDevices;
  DeviceModel? get selectedDevice => _selectedDevice;
  bool get isDiscovering => _isDiscovering;
  String? get error => _error;
  bool get hasDevices => _discoveredDevices.isNotEmpty;
  bool get testMode => _testMode;
  List<DeviceModel> get mockDevices => _mockDevices;
  bool get discoverBoth => _discoverBoth;

  // Toggle test mode
  void toggleTestMode() {
    _testMode = !_testMode;
    if (!_testMode) {
      _discoveredDevices = [];
      _selectedDevice = null;
    }
    notifyListeners();
  }

  // Toggle discover both devices
  void toggleDiscoverBoth() {
    _discoverBoth = !_discoverBoth;
    notifyListeners();
  }

  // Add mock device
  void addMockDevice(String ipAddress, DeviceType type, {String? name}) {
    final device = DeviceModel(ipAddress: ipAddress, type: type, name: name);
    if (!_mockDevices.any((d) => d.ipAddress == ipAddress)) {
      _mockDevices.add(device);
      notifyListeners();
    }
  }

  // Remove mock device
  void removeMockDevice(String ipAddress) {
    _mockDevices.removeWhere((d) => d.ipAddress == ipAddress);
    if (_selectedDevice?.ipAddress == ipAddress) {
      _selectedDevice = null;
    }
    notifyListeners();
  }

  // Discover devices (both Roku and Google TV)
  Future<void> discoverDevices() async {
    _isDiscovering = true;
    _error = null;
    notifyListeners();

    try {
      if (_testMode) {
        // Simulate discovery delay
        await Future.delayed(const Duration(seconds: 2));
        _discoveredDevices = List.from(_mockDevices);
      } else {
        _discoveredDevices = [];
        final deviceSet = <String>{}; // Track IPs to avoid duplicates

        // Discover Roku devices
        if (_discoverBoth || !_discoverBoth) {
          // Always discover Roku for now
          try {
            final rokuIps = await _ssdpService.discoverRoku();
            for (final ip in rokuIps) {
              if (ip.isNotEmpty && !deviceSet.contains(ip)) {
                deviceSet.add(ip);
                _discoveredDevices.add(
                  DeviceModel(ipAddress: ip, type: DeviceType.roku),
                );
              }
            }
          } catch (e) {
            print('Roku discovery error: $e');
          }
        }

        // Discover Google TV devices
        if (_discoverBoth) {
          try {
            print('Starting Google TV discovery in controller...');
            final googleTvDevices = await _castDiscoveryService
                .discoverGoogleTv();
            print(
              'Google TV discovery returned ${googleTvDevices.length} devices',
            );

            for (final data in googleTvDevices) {
              final ip = (data['ip'] ?? data['ipAddress'] ?? '').toString();
              if (ip.isNotEmpty && !deviceSet.contains(ip)) {
                deviceSet.add(ip);
                final device = DeviceModel(
                  ipAddress: ip,
                  type: DeviceType.googleTv,
                  name: data['name']?.toString(),
                );
                print(
                  'Added Google TV device: ${device.displayName} at ${device.ipAddress}',
                );
                _discoveredDevices.add(device);
              } else if (ip.isNotEmpty) {
                print('Skipping duplicate device: $ip');
              }
            }

            print('Total discovered devices: ${_discoveredDevices.length}');
          } catch (e, stackTrace) {
            print('Google TV discovery error: $e');
            print('Stack trace: $stackTrace');
          }
        }
      }

      if (_discoveredDevices.isNotEmpty && _selectedDevice == null) {
        _selectedDevice = _discoveredDevices.first;
      }
    } catch (e) {
      _error = e.toString();
      _discoveredDevices = [];
    } finally {
      _isDiscovering = false;
      notifyListeners();
    }
  }

  // Select a device
  void selectDevice(DeviceModel? device) {
    _selectedDevice = device;
    notifyListeners();
  }

  // Send keypress commands
  Future<void> pressUp() async {
    if (_selectedDevice == null) return;
    try {
      if (_testMode) {
        await Future.delayed(const Duration(milliseconds: 200));
        print(
          'TEST MODE: Sent Up command to ${_selectedDevice!.ipAddress} (${_selectedDevice!.type})',
        );
      } else {
        if (_selectedDevice!.type == DeviceType.roku) {
          await _rokuService.pressUp(_selectedDevice!.ipAddress);
        } else {
          await _googleTvService.pressUp(_selectedDevice!.ipAddress);
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> pressDown() async {
    if (_selectedDevice == null) return;
    try {
      if (_testMode) {
        await Future.delayed(const Duration(milliseconds: 200));
        print(
          'TEST MODE: Sent Down command to ${_selectedDevice!.ipAddress} (${_selectedDevice!.type})',
        );
      } else {
        if (_selectedDevice!.type == DeviceType.roku) {
          await _rokuService.pressDown(_selectedDevice!.ipAddress);
        } else {
          await _googleTvService.pressDown(_selectedDevice!.ipAddress);
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> pressLeft() async {
    if (_selectedDevice == null) return;
    try {
      if (_testMode) {
        await Future.delayed(const Duration(milliseconds: 200));
        print(
          'TEST MODE: Sent Left command to ${_selectedDevice!.ipAddress} (${_selectedDevice!.type})',
        );
      } else {
        if (_selectedDevice!.type == DeviceType.roku) {
          await _rokuService.pressLeft(_selectedDevice!.ipAddress);
        } else {
          await _googleTvService.pressLeft(_selectedDevice!.ipAddress);
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> pressRight() async {
    if (_selectedDevice == null) return;
    try {
      if (_testMode) {
        await Future.delayed(const Duration(milliseconds: 200));
        print(
          'TEST MODE: Sent Right command to ${_selectedDevice!.ipAddress} (${_selectedDevice!.type})',
        );
      } else {
        if (_selectedDevice!.type == DeviceType.roku) {
          await _rokuService.pressRight(_selectedDevice!.ipAddress);
        } else {
          await _googleTvService.pressRight(_selectedDevice!.ipAddress);
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
