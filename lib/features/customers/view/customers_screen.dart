import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('العملاء'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Search customers
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('قائمة العملاء - قريباً'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add new customer
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
