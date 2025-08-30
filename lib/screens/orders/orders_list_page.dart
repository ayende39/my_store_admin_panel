import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrdersListPage extends StatelessWidget {
  const OrdersListPage({super.key});

  void _showOrderMenu(
    BuildContext context,
    DocumentSnapshot doc,
    Map<String, dynamic> data,
  ) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        final orderId = doc.id;
        final customerName = data['customerName'] ?? 'Unknown';
        final total = data['total'] ?? 0;
        final status = data['status'] ?? 'Pending';
        final date = data['date'] != null
            ? DateTime.tryParse(data['date'].toString())
            : null;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #$orderId',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Customer: $customerName'),
              Text('Total: \$${total.toStringAsFixed(2)}'),
              Text('Status: $status'),
              if (date != null)
                Text('Date: ${date.toLocal().toString().split(' ')[0]}'),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('Print Shipping Label'),
                    onPressed: () {
                      // TODO: Implement print logic
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Printing label...')),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Change Status'),
                    onPressed: () async {
                      Navigator.pop(context);
                      final newStatus = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          String selected = status;
                          return AlertDialog(
                            title: const Text('Change Order Status'),
                            content: DropdownButton<String>(
                              value: selected,
                              items:
                                  [
                                        'Pending',
                                        'Processing',
                                        'Shipped',
                                        'Delivered',
                                        'Cancelled',
                                      ]
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (val) {
                                if (val != null) selected = val;
                                Navigator.of(context).pop(val);
                              },
                            ),
                          );
                        },
                      );
                      if (newStatus != null && newStatus != status) {
                        await doc.reference.update({'status': newStatus});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Status changed to $newStatus'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Processing':
        return Colors.blue;
      case 'Shipped':
        return Colors.purple;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersRef = FirebaseFirestore.instance.collection(
      'orders',
    ); // Make sure this matches your Firestore collection

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading orders"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No orders yet"));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final orderId = doc.id;
              final customerName = data['customerName'] ?? 'Unknown';
              final total = data['total'] ?? 0;
              final status = data['status'] ?? 'Pending';
              final date = data['date'] != null
                  ? DateTime.tryParse(data['date'].toString())
                  : null;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _statusColor(status),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text('Order #$orderId'),
                subtitle: Text(
                  'Customer: $customerName\n'
                  'Total: \$${total.toStringAsFixed(2)}\n'
                  'Status: $status'
                  '${date != null ? '\nDate: ${date.toLocal().toString().split(' ')[0]}' : ''}',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'menu') {
                      _showOrderMenu(context, doc, data);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'menu', child: Text('Options')),
                  ],
                ),
                onTap: () => _showOrderMenu(context, doc, data),
              );
            },
          );
        },
      ),
    );
  }
}
