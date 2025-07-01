import 'package:flutter/material.dart';
import '../services/file_transfer_service.dart';
import '../models/transfer_item.dart';

class TransfersTab extends StatelessWidget {
  final FileTransferService fileTransferService;

  const TransfersTab({
    super.key,
    required this.fileTransferService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransferItem>>(
      stream: fileTransferService.transfersStream,
      builder: (context, snapshot) {
        final transfers = snapshot.data ?? [];

        if (transfers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No transfers yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Send files or clipboard content to see transfers here',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transfers.length,
          itemBuilder: (context, index) {
            final transfer = transfers[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(transfer.status),
                  child: Icon(
                    _getTransferIcon(transfer.type),
                    color: Colors.white,
                  ),
                ),
                title: Text(transfer.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${transfer.fromDevice} → ${transfer.toDevice}'),
                    Text(_getStatusText(transfer.status)),
                    if (transfer.status == TransferStatus.inProgress)
                      LinearProgressIndicator(value: transfer.progress),
                    if (transfer.fileSize != null)
                      Text(_formatFileSize(transfer.fileSize!)),
                  ],
                ),
                trailing: Text(
                  _formatTime(transfer.timestamp),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(TransferStatus status) {
    switch (status) {
      case TransferStatus.pending:
        return Colors.orange;
      case TransferStatus.inProgress:
        return Colors.blue;
      case TransferStatus.completed:
        return Colors.green;
      case TransferStatus.failed:
        return Colors.red;
    }
  }

  IconData _getTransferIcon(TransferType type) {
    switch (type) {
      case TransferType.clipboard:
        return Icons.content_copy;
      case TransferType.file:
        return Icons.insert_drive_file;
      case TransferType.folder:
        return Icons.folder;
    }
  }

  String _getStatusText(TransferStatus status) {
    switch (status) {
      case TransferStatus.pending:
        return 'Pending';
      case TransferStatus.inProgress:
        return 'In Progress';
      case TransferStatus.completed:
        return 'Completed';
      case TransferStatus.failed:
        return 'Failed';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
