import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../provider/employee_provider.dart';
import '../model/employee.dart';
import '../../whatsapp/view/whatsapp_qr_screen.dart';
import '../../whatsapp/view/conversations_screen.dart';

class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = ref.watch(myEmployeeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الموظفين')),
      body: employeeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('خطأ في تحميل البيانات',
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => ref.invalidate(myEmployeeProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (employee) {
          if (employee == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'لا يوجد ملف موظف مرتبط بحسابك',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تواصل مع الإدارة لربط حسابك',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myEmployeeProvider),
            child: _ProfileContent(employee: employee),
          );
        },
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final Employee employee;
  const _ProfileContent({required this.employee});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Iqama expiry alert
        if (employee.isExpired || employee.hasExpiringSoon)
          _IqamaAlert(employee: employee),

        // Header card: avatar + name + designation + status
        _HeaderCard(employee: employee, theme: theme),
        const SizedBox(height: 12),

        // Contact card
        _ContactCard(employee: employee),
        const SizedBox(height: 12),

        // Info card
        _InfoCard(employee: employee),
        const SizedBox(height: 12),

        // WhatsApp section
        _WhatsAppCard(employee: employee),
      ],
    );
  }
}

class _IqamaAlert extends StatelessWidget {
  final Employee employee;
  const _IqamaAlert({required this.employee});

  @override
  Widget build(BuildContext context) {
    final isExpired = employee.isExpired;
    final days = employee.daysUntilExpiry;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired ? Colors.red[300]! : Colors.orange[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: isExpired ? Colors.red[700] : Colors.orange[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isExpired
                  ? 'الإقامة منتهية!'
                  : 'الإقامة تنتهي خلال $days يوم',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isExpired ? Colors.red[800] : Colors.orange[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Employee employee;
  final ThemeData theme;
  const _HeaderCard({required this.employee, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 40,
              backgroundImage: employee.image != null
                  ? NetworkImage(employee.image!)
                  : null,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: employee.image == null
                  ? Text(
                      employee.initial,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 14),

            // Name
            Text(
              employee.employeeName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Designation
            if (employee.designation != null)
              Text(
                employee.designation!,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            const SizedBox(height: 10),

            // Status badge
            _StatusBadge(status: employee.status, label: employee.statusLabel),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final String label;
  const _StatusBadge({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case 'Active':
        bg = Colors.green[50]!;
        fg = Colors.green[700]!;
      case 'Left':
        bg = Colors.red[50]!;
        fg = Colors.red[700]!;
      case 'Suspended':
        bg = Colors.orange[50]!;
        fg = Colors.orange[700]!;
      default:
        bg = Colors.grey[100]!;
        fg = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Employee employee;
  const _ContactCard({required this.employee});

  @override
  Widget build(BuildContext context) {
    final hasAnyContact = employee.cellPhone != null ||
        employee.personalPhone != null ||
        employee.companyEmail != null;

    if (!hasAnyContact) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'التواصل',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            if (employee.cellPhone != null)
              _ContactRow(
                icon: Icons.phone,
                label: 'رقم الشركة',
                value: employee.cellPhone!,
                actions: [
                  _ActionButton(
                    icon: Icons.call,
                    color: Colors.green,
                    onTap: () => _launchUrl('tel:${employee.cellPhone}'),
                  ),
                  _ActionButton(
                    icon: Icons.message,
                    color: Colors.green[700]!,
                    onTap: () => _launchWhatsApp(employee.cellPhone!),
                  ),
                ],
              ),

            if (employee.personalPhone != null) ...[
              const Divider(height: 20),
              _ContactRow(
                icon: Icons.phone_android,
                label: 'رقم شخصي',
                value: employee.personalPhone!,
                actions: [
                  _ActionButton(
                    icon: Icons.call,
                    color: Colors.green,
                    onTap: () => _launchUrl('tel:${employee.personalPhone}'),
                  ),
                ],
              ),
            ],

            if (employee.companyEmail != null) ...[
              const Divider(height: 20),
              _ContactRow(
                icon: Icons.email,
                label: 'البريد',
                value: employee.companyEmail!,
                actions: [
                  _ActionButton(
                    icon: Icons.send,
                    color: Colors.blue,
                    onTap: () => _launchUrl('mailto:${employee.companyEmail}'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchWhatsApp(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<Widget> actions;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
        ...actions,
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: color,
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Employee employee;
  const _InfoCard({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'المعلومات',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            _InfoRow(label: 'رقم الموظف', value: employee.name),

            if (employee.department != null)
              _InfoRow(label: 'القسم', value: employee.department!),

            if (employee.branch != null)
              _InfoRow(label: 'الفرع', value: employee.branch!),

            if (employee.dateOfJoining != null)
              _InfoRow(label: 'تاريخ الالتحاق', value: employee.dateOfJoining!),

            if (employee.gender != null)
              _InfoRow(label: 'الجنس', value: employee.genderLabel),

            if (employee.validUpto != null)
              _InfoRow(label: 'انتهاء الإقامة', value: employee.validUpto!),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppCard extends StatelessWidget {
  final Employee employee;
  const _WhatsAppCard({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.chat, size: 20, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  'واتساب',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  employee.sessionName,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // QR / Connection button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WhatsAppQrScreen(
                          sessionName: employee.sessionName),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code),
                label: const Text('ربط واتساب (QR)'),
              ),
            ),
            const SizedBox(height: 8),

            // Conversations button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ConversationsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.forum),
                label: const Text('المحادثات'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
