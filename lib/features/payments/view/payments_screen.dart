import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التحصيل'),
      ),
      body: const Center(
        child: Text('سجل التحصيلات - قريباً'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Record new payment
        },
        icon: const Icon(Icons.add),
        label: const Text('تسجيل دفعة'),
      ),
    );
  }
}
