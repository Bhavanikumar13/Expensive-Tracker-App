class BudgetModel {
  final String id;
  final String category;
  final double limitAmount;
  final String monthYear; // Format: "yyyy-MM"
  final String userId;

  BudgetModel({
    required this.id,
    required this.category,
    required this.limitAmount,
    required this.monthYear,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'limitAmount': limitAmount,
      'monthYear': monthYear,
      'userId': userId,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] ?? '',
      category: map['category'] ?? '',
      limitAmount: (map['limitAmount'] as num).toDouble(),
      monthYear: map['monthYear'] ?? '',
      userId: map['userId'] ?? '',
    );
  }

  BudgetModel copyWith({
    String? id,
    String? category,
    double? limitAmount,
    String? monthYear,
    String? userId,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
      monthYear: monthYear ?? this.monthYear,
      userId: userId ?? this.userId,
    );
  }
}
