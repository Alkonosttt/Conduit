class Device {
  final String id;
  final String name;
  final String type;
  final String ipAddress;
  final int port;
  final bool isPaired;
  final DateTime lastSeen;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.ipAddress,
    required this.port,
    this.isPaired = false,
    required this.lastSeen,
  });

  Device copyWith({
    String? id,
    String? name,
    String? type,
    String? ipAddress,
    int? port,
    bool? isPaired,
    DateTime? lastSeen,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      isPaired: isPaired ?? this.isPaired,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'ipAddress': ipAddress,
      'port': port,
      'isPaired': isPaired,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      ipAddress: json['ipAddress'],
      port: json['port'],
      isPaired: json['isPaired'] ?? false,
      lastSeen: DateTime.parse(json['lastSeen']),
    );
  }
}
