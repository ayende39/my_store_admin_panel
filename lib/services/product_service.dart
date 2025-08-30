import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
  });

  // Add this factory constructor:
  factory Product.fromMap(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'],
    );
  }

  // You can keep the fromFirestore constructor if you want:
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product.fromMap(data, doc.id);
  }
}
