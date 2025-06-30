import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../models/device.dart';

class DeviceDiscoveryService {
  static final DeviceDiscoveryService _instance =
      DeviceDiscoveryService._internal();
  factory DeviceDiscoveryService() => _instance;
  DeviceDiscoveryService._internal();

  final StreamController<List<Device>> _devicesController =
      StreamController<List<Device>>.broadcast();
  final List<Device> _discoveredDevices = [];
  Timer? _discoveryTimer;
  RawDatagramSocket? _socket;

  Stream<List<Device>> get devicesStream => _devicesController.stream;
  List<Device> get devices => List.unmodifiable(_discoveredDevices);

  Future<void> startDiscovery() async {
    try {
      // bind to multicast address for device discovery
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8888);
      _socket?.listen(_handleIncomingData);

      // start broadcasting our presence
      _discoveryTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _broadcastPresence();
      });

      // initial broadcast
      _broadcastPresence();
    } catch (e) {
      print('Error starting discovery: $e');
    }
  }

  void stopDiscovery() {
    _discoveryTimer?.cancel();
    _socket?.close();
  }

  void _broadcastPresence() {
    final deviceInfo = {
      'id': _getDeviceId(),
      'name': _getDeviceName(),
      'type': _getDeviceType(),
      'port': 8889,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final message = jsonEncode(deviceInfo);
    final data = utf8.encode(message);

    // broadcast to local network
    _socket?.send(data, InternetAddress('255.255.255.255'), 8888);
  }

  void _handleIncomingData(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final datagram = _socket?.receive();
      if (datagram != null) {
        try {
          final message = utf8.decode(datagram.data);
          final deviceInfo = jsonDecode(message);

          // device doesn't add itself
          if (deviceInfo['id'] != _getDeviceId()) {
            _addOrUpdateDevice(deviceInfo, datagram.address.address);
          }
        } catch (e) {
          print('Error parsing device info: $e');
        }
      }
    }
  }

  void _addOrUpdateDevice(Map<String, dynamic> deviceInfo, String ipAddress) {
    final device = Device(
      id: deviceInfo['id'],
      name: deviceInfo['name'],
      type: deviceInfo['type'],
      ipAddress: ipAddress,
      port: deviceInfo['port'],
      lastSeen: DateTime.now(),
    );

    final existingIndex =
        _discoveredDevices.indexWhere((d) => d.id == device.id);
    if (existingIndex != -1) {
      _discoveredDevices[existingIndex] = device;
    } else {
      _discoveredDevices.add(device);
    }

    // removes devices not seen for more than 30 seconds
    _discoveredDevices.removeWhere(
      (device) => DateTime.now().difference(device.lastSeen).inSeconds > 30,
    );

    _devicesController.add(List.from(_discoveredDevices));
  }

  String _getDeviceId() {
    // replace with a persistent unique identifier
    return 'device_${Random().nextInt(10000)}';
  }

  String _getDeviceName() {
    if (Platform.isAndroid) return 'Android Device';
    if (Platform.isIOS) return 'iPhone';
    if (Platform.isWindows) return 'Windows PC';
    if (Platform.isMacOS) return 'Mac';
    if (Platform.isLinux) return 'Linux PC';
    return 'Unknown Device';
  }

  String _getDeviceType() {
    if (Platform.isAndroid || Platform.isIOS) return 'mobile';
    return 'desktop';
  }

  void dispose() {
    stopDiscovery();
    _devicesController.close();
  }
}
