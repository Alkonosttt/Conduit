import 'package:flutter/material.dart';
import '../services/device_discovery_service.dart';
import '../services/clipboard_service.dart';
import '../services/file_transfer_service.dart';
import 'package:conduit/models/device.dart';
import 'package:conduit/models/transfer_item.dart';
import 'devices_tab.dart';
import 'transfers_tab.dart';
import 'clipboard_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final DeviceDiscoveryService _discoveryService = DeviceDiscoveryService();
  final ClipboardService _clipboardService = ClipboardService();
  final FileTransferService _fileTransferService = FileTransferService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _discoveryService.startDiscovery();
    await _fileTransferService.startServer();
    _clipboardService.startMonitoring();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _discoveryService.dispose();
    _clipboardService.dispose();
    _fileTransferService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CrossShare'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.devices), text: 'Devices'),
            Tab(icon: Icon(Icons.content_copy), text: 'Clipboard'),
            Tab(icon: Icon(Icons.swap_horiz), text: 'Transfers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DevicesTab(
            discoveryService: _discoveryService,
            fileTransferService: _fileTransferService,
            clipboardService: _clipboardService,
          ),
          ClipboardTab(
            clipboardService: _clipboardService,
            discoveryService: _discoveryService,
            fileTransferService: _fileTransferService,
          ),
          TransfersTab(fileTransferService: _fileTransferService),
        ],
      ),
    );
  }
}
