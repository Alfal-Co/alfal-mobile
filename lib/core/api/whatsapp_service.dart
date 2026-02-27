import 'package:dio/dio.dart';
import '../config/app_config.dart';

/// QR code result from Evolution API
class QrResult {
  final String base64;
  final String? pairingCode;

  const QrResult({required this.base64, this.pairingCode});
}

/// WhatsApp message from ERPNext
class WaMessage {
  final String name;
  final String from;
  final String to;
  final String message;
  final String type; // Incoming / Outgoing
  final DateTime creation;

  const WaMessage({
    required this.name,
    required this.from,
    required this.to,
    required this.message,
    required this.type,
    required this.creation,
  });

  factory WaMessage.fromJson(Map<String, dynamic> json) {
    return WaMessage(
      name: json['name'] as String? ?? '',
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'Incoming',
      creation: DateTime.tryParse(json['creation'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  bool get isIncoming => type == 'Incoming';
}

/// Abstract WhatsApp service interface
abstract class WhatsAppService {
  Future<QrResult> getQrCode(String session);
  Future<String> checkConnection(String session);
  Future<void> sendText(String session, String to, String text);
}

/// Evolution API implementation
class EvolutionWhatsAppService implements WhatsAppService {
  late final Dio _dio;

  EvolutionWhatsAppService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.evolutionApiUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'apikey': AppConfig.evolutionApiKey,
        },
      ),
    );
  }

  @override
  Future<String> checkConnection(String session) async {
    try {
      final response =
          await _dio.get('/instance/connectionState/$session');
      final data = response.data;
      if (data is Map && data.containsKey('state')) {
        return data['state'] as String;
      }
      // Some versions nest it under 'instance'
      if (data is Map && data['instance'] is Map) {
        return data['instance']['state'] as String? ?? 'unknown';
      }
      return 'unknown';
    } catch (e) {
      return 'error';
    }
  }

  @override
  Future<QrResult> getQrCode(String session) async {
    final response = await _dio.get('/instance/connect/$session');
    final data = response.data;

    String base64Qr = '';
    String? pairingCode;

    if (data is Map) {
      // base64 QR may be under different keys
      base64Qr = data['base64'] as String? ??
          data['qrcode']?['base64'] as String? ??
          '';
      pairingCode = data['pairingCode'] as String?;

      // Strip data URI prefix if present
      if (base64Qr.contains(',')) {
        base64Qr = base64Qr.split(',').last;
      }
    }

    return QrResult(base64: base64Qr, pairingCode: pairingCode);
  }

  @override
  Future<void> sendText(String session, String to, String text) async {
    await _dio.post(
      '/message/sendText/$session',
      data: {
        'number': to,
        'text': text,
      },
    );
  }
}
