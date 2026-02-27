import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/material_request.dart';
import '../provider/procurement_provider.dart';
import 'whatsapp_pull_screen.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  /// Pre-filled data from WhatsApp pull
  final String? whatsappMessageId;
  final String? prefilledCustomer;
  final List<Map<String, dynamic>>? prefilledItems;

  const CreateRequestScreen({
    super.key,
    this.whatsappMessageId,
    this.prefilledCustomer,
    this.prefilledItems,
  });

  @override
  ConsumerState<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _notesController = TextEditingController();
  final _warehouseController =
      TextEditingController(text: 'المستودع الرئيسي - AFGT');
  late DateTime _scheduleDate;
  final List<_ItemEntry> _items = [];
  bool _isSubmitting = false;
  String? _whatsappSource;

  @override
  void initState() {
    super.initState();
    _scheduleDate = DateTime.now().add(const Duration(days: 3));

    if (widget.prefilledCustomer != null) {
      _customerController.text = widget.prefilledCustomer!;
    }
    _whatsappSource = widget.whatsappMessageId;

    if (widget.prefilledItems != null) {
      for (final item in widget.prefilledItems!) {
        _items.add(_ItemEntry(
          itemCodeController:
              TextEditingController(text: item['item_code'] ?? ''),
          qtyController:
              TextEditingController(text: '${item['qty'] ?? 1}'),
        ));
      }
    }

    if (_items.isEmpty) {
      _items.add(_ItemEntry());
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _notesController.dispose();
    _warehouseController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If no pre-filled data and no WhatsApp source, show choice screen
    if (widget.whatsappMessageId == null &&
        widget.prefilledCustomer == null &&
        _whatsappSource == null &&
        !_hasUserInput()) {
      return _ChoiceScreen(
        onManual: () => setState(() {
          // Just rebuild to show the form
        }),
        onWhatsApp: () => _openWhatsAppPull(),
      );
    }

    return _buildForm();
  }

  bool _hasUserInput() {
    return _customerController.text.isNotEmpty ||
        _items.any((i) => i.itemCodeController.text.isNotEmpty);
  }

  Widget _buildForm() {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلب شراء جديد'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // WhatsApp source indicator
            if (_whatsappSource != null)
              Card(
                color: Colors.green[50],
                child: ListTile(
                  leading: Icon(Icons.chat, color: Colors.green[700]),
                  title: const Text('مستورد من واتساب'),
                  subtitle: Text(_whatsappSource!),
                  dense: true,
                ),
              ),
            if (_whatsappSource != null) const SizedBox(height: 12),

            // Customer
            TextFormField(
              controller: _customerController,
              decoration: const InputDecoration(
                labelText: 'العميل',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            // Warehouse
            TextFormField(
              controller: _warehouseController,
              decoration: const InputDecoration(
                labelText: 'المستودع',
                prefixIcon: Icon(Icons.warehouse),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'حدد المستودع';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Schedule date
            InkWell(
              onTap: _pickScheduleDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ التسليم المطلوب',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _scheduleDate.toIso8601String().split('T').first,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Items section
            Row(
              children: [
                Text('الأصناف',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة صنف'),
                ),
              ],
            ),
            const Divider(),

            // Item entries
            ...List.generate(_items.length, (index) {
              return _ItemEntryWidget(
                entry: _items[index],
                index: index,
                onRemove: _items.length > 1
                    ? () => setState(() => _items.removeAt(index))
                    : null,
              );
            }),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => _save(asDraft: true),
                    child: const Text('حفظ مسودة'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : () => _save(asDraft: false),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('إرسال'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    setState(() {
      _items.add(_ItemEntry());
    });
  }

  Future<void> _pickScheduleDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduleDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
    );
    if (date != null) {
      setState(() => _scheduleDate = date);
    }
  }

  Future<void> _save({required bool asDraft}) async {
    if (!_formKey.currentState!.validate()) return;

    // Validate at least one item has item_code
    final validItems = _items
        .where((i) => i.itemCodeController.text.trim().isNotEmpty)
        .toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف صنف واحد على الأقل')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final items = validItems
          .map((i) => MaterialRequestItem(
                itemCode: i.itemCodeController.text.trim(),
                itemName: i.itemCodeController.text.trim(),
                qty: double.tryParse(i.qtyController.text) ?? 1,
                warehouse: _warehouseController.text.trim(),
                scheduleDate:
                    _scheduleDate.toIso8601String().split('T').first,
              ))
          .toList();

      // Determine creator role (default to Sales User)
      const creatorRole = 'Sales User';

      final name = await ref.read(procurementProvider.notifier).createRequest(
            customer: _customerController.text.trim(),
            scheduleDate:
                _scheduleDate.toIso8601String().split('T').first,
            warehouse: _warehouseController.text.trim(),
            items: items,
            creatorRole: creatorRole,
            notes: _notesController.text.trim(),
            whatsappSource: _whatsappSource,
          );

      if (!asDraft) {
        // Submit the request (apply workflow)
        await ref.read(procurementProvider.notifier).applyWorkflowAction(
              requestName: name,
              action: 'Submit to Supervisor',
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(asDraft ? 'تم حفظ المسودة' : 'تم إرسال الطلب'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الحفظ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _openWhatsAppPull() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WhatsAppPullScreen(
          onSelect: (messageId, customer, items) {
            setState(() {
              _whatsappSource = messageId;
              if (customer != null) _customerController.text = customer;
              _items.clear();
              if (items != null && items.isNotEmpty) {
                for (final item in items) {
                  _items.add(_ItemEntry(
                    itemCodeController:
                        TextEditingController(text: item['item_code'] ?? ''),
                    qtyController:
                        TextEditingController(text: '${item['qty'] ?? 1}'),
                  ));
                }
              } else {
                _items.add(_ItemEntry());
              }
            });
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

/// Choice screen: Manual entry or WhatsApp pull
class _ChoiceScreen extends StatelessWidget {
  final VoidCallback onManual;
  final VoidCallback onWhatsApp;

  const _ChoiceScreen({required this.onManual, required this.onWhatsApp});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلب شراء جديد'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Manual entry card
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onManual,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.edit_note,
                            color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('إدخال يدوي',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('أنشئ الطلب بنفسك',
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_left, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // WhatsApp pull card
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onWhatsApp,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.green[50],
                        child:
                            Icon(Icons.chat, color: Colors.green[700]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('سحب من واتساب',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('مؤقت',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.orange[800])),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('استيراد طلب من قروب واتساب',
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_left, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal item entry state
class _ItemEntry {
  final TextEditingController itemCodeController;
  final TextEditingController qtyController;

  _ItemEntry({
    TextEditingController? itemCodeController,
    TextEditingController? qtyController,
  })  : itemCodeController = itemCodeController ?? TextEditingController(),
        qtyController = qtyController ?? TextEditingController(text: '1');

  void dispose() {
    itemCodeController.dispose();
    qtyController.dispose();
  }
}

class _ItemEntryWidget extends StatelessWidget {
  final _ItemEntry entry;
  final int index;
  final VoidCallback? onRemove;

  const _ItemEntryWidget({
    required this.entry,
    required this.index,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text('صنف ${index + 1}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13)),
                const Spacer(),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onRemove,
                    color: Colors.red[400],
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: entry.itemCodeController,
              decoration: const InputDecoration(
                labelText: 'كود الصنف',
                prefixIcon: Icon(Icons.qr_code, size: 20),
                isDense: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'أدخل كود الصنف';
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: entry.qtyController,
              decoration: const InputDecoration(
                labelText: 'الكمية',
                prefixIcon: Icon(Icons.numbers, size: 20),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'أدخل الكمية';
                final qty = double.tryParse(v);
                if (qty == null || qty <= 0) return 'كمية غير صحيحة';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
