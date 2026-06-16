class WaterLog {
  final String id;
  final DateTime timestamp;
  final int amount; // in ml

  WaterLog({
    required this.id,
    required this.timestamp,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'amount': amount,
    };
  }

  factory WaterLog.fromJson(Map<String, dynamic> json) {
    return WaterLog(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      amount: json['amount'] as int,
    );
  }
}
