import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final String unit; // e.g. "pack", "kg", "litre", "item"
  final IconData icon;
  final Color color;
  final bool isCustom;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.unit = 'pack',
    required this.icon,
    required this.color,
    this.isCustom = false,
  });

  String get formattedPrice {
    if (unit == 'kg' || unit == 'litre') {
      return '₹${price.toStringAsFixed(0)}/$unit';
    }
    return '₹${price.toStringAsFixed(0)}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'unit': unit,
      'iconCodePoint': icon.codePoint,
      'colorValue': color.toARGB32(),
      'isCustom': isCustom ? 1 : 0,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      unit: map['unit'] as String? ?? 'pack',
      icon: IconData(
        map['iconCodePoint'] as int? ?? 0xe59c,
        fontFamily: 'MaterialIcons',
      ),
      color: Color(map['colorValue'] as int? ?? 0xFF0F9D58),
      isCustom: (map['isCustom'] as int? ?? 0) == 1,
    );
  }
}
