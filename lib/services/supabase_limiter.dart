import 'package:flutter/material.dart';

class SupabaseRequestLimitException implements Exception {
  final String message;
  final String amharicMessage;

  SupabaseRequestLimitException({
    required this.message,
    required this.amharicMessage,
  });

  @override
  String toString() => message;
}

class SupabaseRequestLimiter {
  static int _requestCount = 0;
  static const int maxRequests = 5;

  static int get requestCount => _requestCount;

  static void increment() {
    if (_requestCount >= maxRequests) {
      throw SupabaseRequestLimitException(
        message: 'Session network request limit reached (Max 5). To prevent high API costs, you are capped at 5 requests per session.',
        amharicMessage: 'የክፍለ-ጊዜ አውታረ መረብ ጥያቄ ገደብ ላይ ደርሰዋል (ከፍተኛ 5)። ከፍተኛ የኤፒአይ ወጪን ለመከላከል በአንድ ክፍለ-ጊዜ በ5 ጥያቄዎች የተገደቡ ናቸው።',
      );
    }
    _requestCount++;
    debugPrint("SupabaseRequestLimiter: request $_requestCount of $maxRequests registered.");
  }

  static bool get isLimitReached => _requestCount >= maxRequests;

  static void reset() {
    _requestCount = 0;
  }
}
