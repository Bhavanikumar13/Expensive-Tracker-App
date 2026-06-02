class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime dateTime;
  final bool isIncome;
  final String notes;
  final String userId;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.dateTime,
    required this.isIncome,
    this.notes = '',
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'dateTime': dateTime.toIso8601String(),
      'isIncome': isIncome,
      'notes': notes,
      'userId': userId,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      isIncome: map['isIncome'] ?? false,
      notes: map['notes'] ?? '',
      userId: map['userId'] ?? '',
    );
  }

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? dateTime,
    bool? isIncome,
    String? notes,
    String? userId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      dateTime: dateTime ?? this.dateTime,
      isIncome: isIncome ?? this.isIncome,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
    );
  }
}
