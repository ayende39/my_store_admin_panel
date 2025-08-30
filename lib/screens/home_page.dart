import 'package:flutter/material.dart';
import 'products/products_list_page.dart';
import 'orders/orders_list_page.dart'; // Import your orders page

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final gridItems = [
      {
        'title': 'Products',
        'icon': Icons.inventory_2,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductListPage()),
        ),
      },
      {
        'title': 'Orders',
        'icon': Icons.receipt_long,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OrdersListPage()),
        ),
      },
      // Add more grid items here for users, settings, etc.
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Home')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: gridItems.length,
          itemBuilder: (context, index) {
            final item = gridItems[index];
            return GestureDetector(
              onTap: item['onTap'] as VoidCallback,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 48,
                        color: Colors.indigo,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item['title'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
