import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final List<String>? imageUrls;
  final int inStock; // new field
  final String description; // new field
  final List<Map<String, dynamic>>? sizes; // Add this

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrls,
    this.inStock = 0, // default to 0
    this.description = '', // default to empty string
    this.sizes,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrls: data['imageUrls'] != null
          ? (data['imageUrls'] as List).map((e) => e.toString()).toList()
          : null,
      inStock: data['inStock'] ?? 0,
      description: data['description'] ?? '',
      sizes: data['sizes'] != null
          ? (data['sizes'] as List).map((e) {
              final sizeMap = Map<String, dynamic>.from(e as Map);
              // Ensure imageUrls is a List<String>
              if (sizeMap['imageUrls'] != null) {
                sizeMap['imageUrls'] = (sizeMap['imageUrls'] as List)
                    .map((img) => img.toString())
                    .toList();
              }
              return sizeMap;
            }).toList()
          : null,
    );
  }
}
