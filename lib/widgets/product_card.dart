import 'package:flutter/material.dart';
import '../../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductCard({
    required this.product,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget leadingWidget;

    if (product.imageUrls != null && product.imageUrls!.isNotEmpty) {
      if (product.imageUrls!.length == 1) {
        // Show single image
        leadingWidget = Image.network(
          product.imageUrls!.first,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 50),
        );
      } else {
        // Show horizontal list of images thumbnails
        leadingWidget = SizedBox(
          width: 100, // limit width of ListView
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: product.imageUrls!.length,
            itemBuilder: (context, index) {
              final url = product.imageUrls![index];
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Image.network(
                  url,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, size: 50),
                ),
              );
            },
          ),
        );
      }
    } else {
      leadingWidget = const Icon(Icons.image_not_supported, size: 50);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: leadingWidget,
        title: Text(product.name),
        subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
