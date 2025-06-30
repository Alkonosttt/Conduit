import 'package:flutter/material.dart';
import '../services/device_discovery_service.dart';
import '../services/file_transfer_service.dart';
import '../services/clipboard_service.dart';
import '../models/device.dart';

class DevicesTab extends StatelessWidget {
  final DeviceDiscoveryService discoveryService;
  final FileTransferService fileTransferService;
  final ClipboardService clipboardService;

  const DevicesTab({
    super.key,
    required this.discoveryService,
    required this.fileTransferService,
    required this.clipboardService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Device>>(
      stream: discoveryService.devicesStream,
      builder: (context, snapshot) {
        final devices = snapshot.data ?? [];

        if (devices.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Searching for devices...',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Make sure other devices are running Conduit',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      device.isPaired ? Colors.green : Colors.orange,
                  child: Icon(
                    device.type == 'mobile'
                        ? Icons.phone_android
                        : Icons.computer,
                    color: Colors.white,
                  ),
                ),
                title: Text(device.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${device.ipAddress}:${device.port}'),
                    Text(
                      device.isPaired ? 'Paired' : 'Not paired',
                      style: TextStyle(
                        color: device.isPaired ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) =>
                      _handleDeviceAction(context, device, value),
                  itemBuilder: (context) => [
                    if (!device.isPaired)
                      const PopupMenuItem(
                        value: 'pair',
                        child: ListTile(
                          leading: Icon(Icons.link),
                          title: Text('Pair Device'),
                        ),
                      ),
                    if (device.isPaired) ...[
                      const PopupMenuItem(
                        value: 'send_clipboard',
                        child: ListTile(
                          leading: Icon(Icons.content_copy),
                          title: Text('Send Clipboard'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'send_file',
                        child: ListTile(
                          leading: Icon(Icons.file_upload),
                          title: Text('Send File'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'unpair',
                        child: ListTile(
                          leading: Icon(Icons.link_off),
                          title: Text('Unpair'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleDeviceAction(
      BuildContext context, Device device, String action) async {
    switch (action) {
      case 'pair':
        _showPairingDialog(context, device);
        break;
      case 'send_clipboard':
        final content = await clipboardService.getClipboardContent();
        if (content != null && content.isNotEmpty) {
          await fileTransferService.sendClipboard(device, content);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Clipboard sent to ${device.name}')),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Clipboard is empty')),
            );
          }
        }
        break;
      case 'send_file':
        // In a real app, this would open a file picker
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File picker not implemented in demo')),
        );
        break;
      case 'unpair':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unpaired from ${device.name}')),
        );
        break;
    }
  }

  void _showPairingDialog(BuildContext context, Device device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pair with ${device.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the PIN shown on the other device:'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'PIN',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Paired with ${device.name}')),
              );
            },
            child: const Text('Pair'),
          ),
        ],
      ),
    );
  }
}
