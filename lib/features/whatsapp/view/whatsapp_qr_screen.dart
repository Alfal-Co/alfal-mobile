import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/whatsapp_provider.dart';

class WhatsAppQrScreen extends ConsumerStatefulWidget {
  final String sessionName;
  const WhatsAppQrScreen({super.key, required this.sessionName});

  @override
  ConsumerState<WhatsAppQrScreen> createState() => _WhatsAppQrScreenState();
}

class _WhatsAppQrScreenState extends ConsumerState<WhatsAppQrScreen> {
  Timer? _pollTimer;
  bool _connected = false;
  bool _loading = true;
  String? _error;
  String? _qrBase64;
  String? _pairingCode;

  @override
  void initState() {
    super.initState();
    _checkAndLoad();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAndLoad() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = ref.read(whatsappServiceProvider);
      final state = await service.checkConnection(widget.sessionName);

      if (state == 'open') {
        setState(() {
          _connected = true;
          _loading = false;
        });
        return;
      }

      // Not connected — get QR code
      final qr = await service.getQrCode(widget.sessionName);
      setState(() {
        _qrBase64 = qr.base64;
        _pairingCode = qr.pairingCode;
        _loading = false;
      });

      // Start polling every 5 seconds
      _startPolling();
    } catch (e) {
      setState(() {
        _error = 'فشل الاتصال بالخادم';
        _loading = false;
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final service = ref.read(whatsappServiceProvider);
        final state = await service.checkConnection(widget.sessionName);
        if (state == 'open' && mounted) {
          _pollTimer?.cancel();
          setState(() => _connected = true);
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('واتساب - ${widget.sessionName}')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildContent(theme),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_loading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('جاري فحص الاتصال...'),
        ],
      );
    }

    if (_error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _checkAndLoad,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      );
    }

    if (_connected) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green[600]),
          const SizedBox(height: 16),
          const Text(
            'متصل بالفعل',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'جلسة ${widget.sessionName} متصلة وتعمل',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('رجوع'),
          ),
        ],
      );
    }

    // Show QR code
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'امسح رمز QR بتطبيق واتساب',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'افتح واتساب > الإعدادات > الأجهزة المرتبطة',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // QR code image
          if (_qrBase64 != null && _qrBase64!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.memory(
                base64Decode(_qrBase64!),
                width: 280,
                height: 280,
                fit: BoxFit.contain,
              ),
            )
          else
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('لم يتم الحصول على رمز QR'),
              ),
            ),

          // Pairing code alternative
          if (_pairingCode != null) ...[
            const SizedBox(height: 20),
            Text(
              'أو استخدم كود الربط:',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _pairingCode!,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'في انتظار المسح...',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),

          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _checkAndLoad,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('تحديث الرمز'),
          ),
        ],
      ),
    );
  }
}
