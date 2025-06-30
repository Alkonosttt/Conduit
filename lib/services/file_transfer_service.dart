import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../models/transfer_item.dart';
import '../models/device.dart';

class FileTransferService {
  static final FileTransferService _instance = FileTransferService._internal();
  factory FileTransferService() => _instance;
  FileTransferService._internal();

  final StreamController<List<TransferItem>> _transfersController =
      StreamController<List<TransferItem>>.broadcast();
  final List<TransferItem> _transfers = [];
  ServerSocket? _server;

  Stream<List<TransferItem>> get transfersStream => _transfersController.stream;
  List<TransferItem> get transfers => List.unmodifiable(_transfers);

  Future<void> startServer() async {
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, 8889);
      _server?.listen(_handleConnection);
    } catch (e) {
      print('Error starting file transfer server: $e');
    }
  }

  void stopServer() {
    _server?.close();
  }

  void _handleConnection(Socket socket) {
    socket.listen(
      (data) => _handleIncomingData(socket, data),
      onError: (error) => print('Socket error: $error'),
      onDone: () => socket.close(),
    );
  }

  void _handleIncomingData(Socket socket, Uint8List data) {
    try {
      final message = utf8.decode(data);
      final transferData = jsonDecode(message);

      if (transferData['type'] == 'clipboard') {
        _handleClipboardTransfer(transferData);
      } else if (transferData['type'] == 'file') {
        _handleFileTransfer(transferData);
      }
    } catch (e) {
      print('Error handling incoming data: $e');
    }
  }

  void _handleClipboardTransfer(Map<String, dynamic> data) {
    final transfer = TransferItem(
      id: data['id'],
      name: 'Clipboard Content',
      type: TransferType.clipboard,
      content: data['content'],
      fromDevice: data['fromDevice'],
      toDevice: 'this_device',
      status: TransferStatus.completed,
      timestamp: DateTime.parse(data['timestamp']),
      progress: 1.0,
    );

    _addTransfer(transfer);
  }

  void _handleFileTransfer(Map<String, dynamic> data) {
    final transfer = TransferItem(
      id: data['id'],
      name: data['fileName'],
      type: TransferType.file,
      fileSize: data['fileSize'],
      fromDevice: data['fromDevice'],
      toDevice: 'this_device',
      status: TransferStatus.inProgress,
      timestamp: DateTime.parse(data['timestamp']),
    );

    _addTransfer(transfer);
    // TODO: replace with file transfer
    _simulateFileTransfer(transfer);
  }

  Future<void> _simulateFileTransfer(TransferItem transfer) async {
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      final updatedTransfer = transfer.copyWith(
        progress: i / 100.0,
        status: i == 100 ? TransferStatus.completed : TransferStatus.inProgress,
      );
      _updateTransfer(updatedTransfer);
    }
  }

  Future<void> sendClipboard(Device device, String content) async {
    final transfer = TransferItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Clipboard Content',
      type: TransferType.clipboard,
      content: content,
      fromDevice: 'this_device',
      toDevice: device.id,
      status: TransferStatus.pending,
      timestamp: DateTime.now(),
    );

    _addTransfer(transfer);

    try {
      final socket = await Socket.connect(device.ipAddress, device.port);

      final message = jsonEncode({
        'id': transfer.id,
        'type': 'clipboard',
        'content': content,
        'fromDevice': 'this_device',
        'timestamp': transfer.timestamp.toIso8601String(),
      });

      socket.write(message);
      await socket.close();

      _updateTransfer(
          transfer.copyWith(status: TransferStatus.completed, progress: 1.0));
    } catch (e) {
      print('Error sending clipboard: $e');
      _updateTransfer(transfer.copyWith(status: TransferStatus.failed));
    }
  }

  Future<void> sendFile(Device device, String filePath) async {
    final file = File(filePath);
    final fileName = file.path.split('/').last;
    final fileSize = await file.length();

    final transfer = TransferItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: fileName,
      type: TransferType.file,
      filePath: filePath,
      fileSize: fileSize,
      fromDevice: 'this_device',
      toDevice: device.id,
      status: TransferStatus.pending,
      timestamp: DateTime.now(),
    );

    _addTransfer(transfer);

    try {
      final socket = await Socket.connect(device.ipAddress, device.port);

      final message = jsonEncode({
        'id': transfer.id,
        'type': 'file',
        'fileName': fileName,
        'fileSize': fileSize,
        'fromDevice': 'this_device',
        'timestamp': transfer.timestamp.toIso8601String(),
      });

      socket.write(message);

      // TODO: send the actual file data
      _simulateFileTransfer(transfer);

      await socket.close();
    } catch (e) {
      print('Error sending file: $e');
      _updateTransfer(transfer.copyWith(status: TransferStatus.failed));
    }
  }

  void _addTransfer(TransferItem transfer) {
    _transfers.add(transfer);
    _transfersController.add(List.from(_transfers));
  }

  void _updateTransfer(TransferItem updatedTransfer) {
    final index = _transfers.indexWhere((t) => t.id == updatedTransfer.id);
    if (index != -1) {
      _transfers[index] = updatedTransfer;
      _transfersController.add(List.from(_transfers));
    }
  }

  void dispose() {
    stopServer();
    _transfersController.close();
  }
}
