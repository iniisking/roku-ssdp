import 'package:flutter/services.dart';

class SsdpService {
  static const MethodChannel _channel = MethodChannel('com.example.roku_ssdp/ssdp');

  // Discover Roku devices on the local network
  Future<List<String>> discoverRoku() async {
    try {
      final result = await _channel.invokeMethod<List>('discoverRoku');
      return result?.map((e) => e.toString()).toList() ?? [];
    } on PlatformException catch (e) {
      throw Exception('SSDP discovery failed: ${e.message}');
    }
  }
}

