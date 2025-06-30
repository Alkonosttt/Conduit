enum TransferType { clipboard, file, folder }

enum TransferStatus { pending, inProgress, completed, failed }

class TransferItem {
  final String id;
  final String name;
  final TransferType type;
  final String? content;
  final String? filePath;
  final int? fileSize;
  final String fromDevice;
  final String toDevice;
  final TransferStatus status;
  final DateTime timestamp;
  final double progress;

  TransferItem({
    required this.id,
    required this.name,
    required this.type,
    this.content,
    this.filePath,
    this.fileSize,
    required this.fromDevice,
    required this.toDevice,
    this.status = TransferStatus.pending,
    required this.timestamp,
    this.progress = 0.0,
  });

  TransferItem copyWith({
    String? id,
    String? name,
    TransferType? type,
    String? content,
    String? filePath,
    int? fileSize,
    String? fromDevice,
    String? toDevice,
    TransferStatus? status,
    DateTime? timestamp,
    double? progress,
  }) {
    return TransferItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      content: content ?? this.content,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      fromDevice: fromDevice ?? this.fromDevice,
      toDevice: toDevice ?? this.toDevice,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      progress: progress ?? this.progress,
    );
  }
}
