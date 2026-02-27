import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/auth/auth_provider.dart';
import '../model/chat_message.dart';

/// Bot Raven user name (the Raven User document name)
const _botRavenUser = 'bot-مساعد-الفال';

class AiState {
  final List<ChatMessage> messages;
  final bool isTyping;
  final String? channelId;
  final String? error;

  const AiState({
    this.messages = const [],
    this.isTyping = false,
    this.channelId,
    this.error,
  });

  AiState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    String? channelId,
    String? error,
  }) {
    return AiState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      channelId: channelId ?? this.channelId,
      error: error,
    );
  }
}

class AiNotifier extends StateNotifier<AiState> {
  final Ref _ref;
  bool _initialized = false;

  AiNotifier(this._ref) : super(const AiState());

  /// Ensure initialized (called lazily when screen opens)
  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    await _initChannel();
  }

  /// Initialize: find or create DM channel with the bot
  Future<void> _initChannel() async {
    final prefs = await SharedPreferences.getInstance();

    // Try cached channel first
    final cached = prefs.getString('raven_bot_channel');
    print('[AI] Cached channel: $cached');
    if (cached != null && cached.isNotEmpty) {
      state = state.copyWith(channelId: cached);
      await _loadHistory();
      return;
    }

    try {
      final client = _ref.read(erpnextClientProvider);

      // Get current user
      final userResult = await client.call('frappe.auth.get_logged_user');
      final currentUser = userResult.toString();
      print('[AI] Current user: $currentUser');

      // Create or find DM channel with the bot via Raven API
      // This handles finding existing channels or creating a new one
      String? channelId;
      try {
        final result = await client.call(
          'raven.api.raven_channel.create_direct_message_channel',
          data: {'user_id': _botRavenUser},
        );
        channelId = result?.toString();
        print('[AI] DM channel from API: $channelId');
      } catch (e) {
        print('[AI] create_direct_message_channel failed: $e');
        // Fallback: create channel directly
        final newChannel = await client.createDoc('Raven Channel', {
          'channel_name': '$currentUser _ $_botRavenUser',
          'is_direct_message': 1,
          'type': 'Private',
        });
        channelId = newChannel['name']?.toString();
        print('[AI] Created channel via fallback: $channelId');
      }

      print('[AI] Final channelId: $channelId');
      if (channelId != null) {
        state = state.copyWith(channelId: channelId);
        await prefs.setString('raven_bot_channel', channelId);
        await _loadHistory();
      } else {
        state = state.copyWith(error: 'لم يتم العثور على قناة البوت');
      }
    } catch (e) {
      print('[AI] Error in _initChannel: $e');
      if (e is DioException) {
        print('[AI] Status: ${e.response?.statusCode}');
        print('[AI] Response: ${e.response?.data}');
      }
      state = state.copyWith(error: _friendlyError(e));
    }
  }

  /// Load recent chat history from the DM channel + thread responses
  Future<void> _loadHistory() async {
    if (state.channelId == null) return;

    try {
      final client = _ref.read(erpnextClientProvider);

      print('[AI] Loading history for channel: ${state.channelId}');
      // Get user messages from DM channel using Raven's API
      final result = await client.call(
        'raven.api.chat_stream.get_messages',
        data: {
          'channel_id': state.channelId!,
          'limit': 20,
        },
      );

      if (result is! Map || !result.containsKey('messages')) return;

      final rawMessages = result['messages'] as List? ?? [];
      print('[AI] Found ${rawMessages.length} DM messages');

      final messages = <ChatMessage>[];

      // Messages are newest first - reverse to get oldest first
      for (final dm in rawMessages.reversed) {
        if (dm is! Map) continue;
        final text = dm['text'] as String? ?? '';
        final msgType = dm['message_type'] as String? ?? '';
        if (text.isEmpty || msgType != 'Text') continue;

        // Add user message
        messages.add(ChatMessage(
          content: text,
          role: MessageRole.user,
          timestamp: DateTime.tryParse(dm['creation']?.toString() ?? '') ??
              DateTime.now(),
        ));

        // If message has a thread, fetch bot response from it
        final isThread = dm['is_thread'];
        if (isThread == 1 || isThread == true) {
          final msgName = dm['name']?.toString();
          if (msgName != null) {
            try {
              final threadResult = await client.call(
                'raven.api.chat_stream.get_messages',
                data: {
                  'channel_id': msgName,
                  'limit': 5,
                },
              );
              if (threadResult is Map &&
                  threadResult.containsKey('messages')) {
                final threadMsgs =
                    threadResult['messages'] as List? ?? [];
                // Find first bot message (messages are newest first)
                for (final tm in threadMsgs.reversed) {
                  if (tm is Map && tm['is_bot_message'] == 1) {
                    final botText = tm['text'] as String? ?? '';
                    if (botText.isNotEmpty) {
                      messages.add(ChatMessage(
                        content: _stripHtml(botText),
                        role: MessageRole.assistant,
                        timestamp: DateTime.tryParse(
                                tm['creation']?.toString() ?? '') ??
                            DateTime.now(),
                      ));
                      break;
                    }
                  }
                }
              }
            } catch (_) {
              // Thread channel may not exist yet
            }
          }
        }
      }

      print('[AI] Loaded ${messages.length} total messages (user+bot)');
      state = state.copyWith(messages: messages);
    } catch (e) {
      print('[AI] Error loading history: $e');
    }
  }

  /// Send a message to the Raven bot
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isTyping) return;

    // Ensure channel exists
    if (state.channelId == null) {
      await _initChannel();
      if (state.channelId == null) return;
    }

    // Add user message immediately
    final userMsg = ChatMessage(
      content: text.trim(),
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
      error: null,
    );

    try {
      final client = _ref.read(erpnextClientProvider);

      // Send message via Raven API - returns the created message doc
      final result = await client.call(
        'raven.api.raven_message.send_message',
        data: {
          'channel_id': state.channelId!,
          'text': text.trim(),
        },
      );

      print('[AI] send_message result type: ${result.runtimeType}');
      print('[AI] send_message result: $result');

      // Extract message name - the thread channel will have this same name
      String? messageName;
      if (result is Map) {
        messageName = result['name']?.toString();
      }

      print('[AI] Message name: $messageName');

      if (messageName != null) {
        // Poll for bot response in the thread channel
        await _waitForBotResponse(messageName);
      } else {
        // Fallback: find latest thread from DM channel
        final threadName = await _findBotResponseFromDm();
        if (threadName != null) {
          await _waitForBotResponse(threadName);
        }
      }
    } catch (e) {
      final errorMsg = ChatMessage(
        content: _friendlyError(e),
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isTyping: false,
      );
    }
  }

  /// Poll for bot response in the thread channel using Raven's chat_stream API.
  /// Raven creates a thread channel with name = message name,
  /// and the bot responds inside that thread channel.
  Future<void> _waitForBotResponse(String messageName) async {
    final client = _ref.read(erpnextClientProvider);
    final startTime = DateTime.now();
    const maxWait = Duration(seconds: 120);
    const pollInterval = Duration(seconds: 3);

    while (DateTime.now().difference(startTime) < maxWait) {
      await Future.delayed(pollInterval);

      if (!mounted) return;

      try {
        // Use Raven's chat_stream API which has proper permission handling
        // for thread channels (checks main DM channel membership)
        final result = await client.call(
          'raven.api.chat_stream.get_messages',
          data: {
            'channel_id': messageName,
            'limit': 5,
          },
        );

        if (result is Map && result.containsKey('messages')) {
          final rawMessages = result['messages'] as List? ?? [];

          // Look for bot messages in the thread
          for (final msg in rawMessages) {
            if (msg is Map) {
              final isBot = msg['is_bot_message'] == 1;
              final text = msg['text'] as String? ?? '';

              if (isBot && text.isNotEmpty) {
                print('[AI] Poll: found bot response in thread $messageName');
                final creation = msg['creation'] as String? ?? '';

                state = state.copyWith(
                  messages: [
                    ...state.messages,
                    ChatMessage(
                      content: _stripHtml(text),
                      role: MessageRole.assistant,
                      timestamp:
                          DateTime.tryParse(creation) ?? DateTime.now(),
                    ),
                  ],
                  isTyping: false,
                );
                return;
              }
            }
          }
          print('[AI] Poll: no bot response yet in thread $messageName (${rawMessages.length} messages)');
        }
      } catch (e) {
        // Thread channel may not exist yet (404) - continue polling
        print('[AI] Poll error for $messageName: ${e is DioException ? e.response?.statusCode : e}');
      }
    }

    // Timeout
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(
          content: 'انتهت مهلة انتظار رد المساعد - حاول مرة أخرى',
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
        ),
      ],
      isTyping: false,
    );
  }

  /// Helper to get bot messages from thread using DM channel polling
  Future<String?> _findBotResponseFromDm() async {
    final client = _ref.read(erpnextClientProvider);
    try {
      final result = await client.call(
        'raven.api.chat_stream.get_messages',
        data: {
          'channel_id': state.channelId!,
          'limit': 3,
        },
      );
      if (result is Map && result.containsKey('messages')) {
        final msgs = result['messages'] as List? ?? [];
        for (final msg in msgs) {
          if (msg is Map && msg['is_thread'] == 1) {
            return msg['name']?.toString();
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Strip HTML tags from bot responses (Raven wraps in <p> tags)
  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  String _friendlyError(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      if (status == 403) {
        return 'ليس لديك صلاحية استخدام المساعد - تواصل مع المسؤول';
      }
      if (status == 404) return 'خدمة Raven غير مفعّلة على السيرفر';
      if (status == 417) {
        final data = e.response?.data;
        if (data is Map) {
          final msg = data['message'];
          if (msg != null) return msg.toString();
        }
        return 'خطأ في Raven - تواصل مع المسؤول';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'لا يمكن الاتصال بالسيرفر - تأكد من الإنترنت';
      }
      return 'خطأ في الاتصال بالمساعد الذكي';
    }
    return 'حدث خطأ غير متوقع';
  }

  void clearChat() {
    state = state.copyWith(messages: []);
  }

  /// Retry channel initialization
  Future<void> retryInit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('raven_bot_channel');
    _initialized = false;
    state = state.copyWith(error: null, channelId: null);
    await _initChannel();
  }
}

final aiProvider = StateNotifierProvider<AiNotifier, AiState>((ref) {
  return AiNotifier(ref);
});
