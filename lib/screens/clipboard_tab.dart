import 'package:flutter/material.dart';
import '../services/clipboard_service.dart';
import '../services/device_discovery_service.dart';
import '../services/file_transfer_service.dart';
import '../models/device.dart';

class ClipboardTab extends StatefulWidget {
  final ClipboardService clipboardService;
  final DeviceDiscoveryService discoveryService;
  final FileTransferService fileTransferService;

  const ClipboardTab({
    super.key,
    required this.clipboardService,
    required this.discoveryService,
    required this.fileTransferService,
  });

  @override
  State<ClipboardTab> createState() => _ClipboardTabState();
}

class _ClipboardTabState extends State<ClipboardTab> {
  final List<String> _clipboardHistory = [];

  @override
  void initState() {
    super.initState();
    widget.clipboardService.clipboardStream.listen((content) {
      setState(() {
        _clipboardHistory.insert(0, content);
        if (_clipboardHistory.length > 50) {
          _clipboardHistory.removeLast();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showSendToDeviceDialog,
                  icon: const Icon(Icons.send),
                  label: const Text('Send Current Clipboard'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _refreshClipboard,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: _clipboardHistory.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.content_copy, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No clipboard history',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Copy something to see it here',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _clipboardHistory.length,
                  itemBuilder: (context, index) {
                    final content = _clipboardHistory[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.content_copy),
                        title: Text(
                          content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('${content.length} characters'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) =>
                              _handleClipboardAction(content, value),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'copy',
                              child: ListTile(
                                leading: Icon(Icons.copy),
                                title: Text('Copy'),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'send',
                              child: ListTile(
                                leading: Icon(Icons.send),
                                title: Text('Send to Device'),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete),
                                title: Text('Delete'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _refreshClipboard() async {
    final content = await widget.clipboardService.getClipboardContent();
    if (content != null && content.isNotEmpty) {
      setState(() {
        if (!_clipboardHistory.contains(content)) {
          _clipboardHistory.insert(0, content);
        }
      });
    }
  }

  void _showSendToDeviceDialog() async {
    final content = await widget.clipboardService.getClipboardContent();
    if (content == null || content.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard is empty')),
        );
      }
      return;
    }

    final devices =
        widget.discoveryService.devices.where((d) => d.isPaired).toList();
    if (devices.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No paired devices found')),
        );
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Send to Device'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Send clipboard content to:'),
              const SizedBox(height: 16),
              ...devices.map((device) => ListTile(
                    leading: Icon(
                      device.type == 'mobile'
                          ? Icons.phone_android
                          : Icons.computer,
                    ),
                    title: Text(device.name),
                    onTap: () {
                      Navigator.of(context).pop();
                      _sendClipboardToDevice(device, content);
                    },
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }
  }

  void _sendClipboardToDevice(Device device, String content) async {
    await widget.fileTransferService.sendClipboard(device, content);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Clipboard sent to ${device.name}')),
      );
    }
  }

  void _handleClipboardAction(String content, String action) async {
    switch (action) {
      case 'copy':
        await widget.clipboardService.setClipboardContent(content);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Copied to clipboard')),
          );
        }
        break;
      case 'send':
        _showSendToDeviceDialog();
        break;
      case 'delete':
        setState(() {
          _clipboardHistory.remove(content);
        });
        break;
    }
  }
}
