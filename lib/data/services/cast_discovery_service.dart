import 'package:flutter/services.dart';

class CastDiscoveryService {
  static const MethodChannel _channel = MethodChannel('com.example.roku_ssdp/cast');

  // Discover Google TV/Chromecast devices on the local network
  Future<List<Map<String, dynamic>>> discoverGoogleTv() async {
    try {
      print('Starting Google TV discovery...');
      final result = await _channel.invokeMethod<List>('discoverGoogleTv');
      if (result == null) {
        print('Google TV discovery returned null');
        return [];
      }
      
      print('Google TV discovery found ${result.length} devices');
      final devices = result.map((item) {
        if (item is Map) {
          final device = Map<String, dynamic>.from(item);
          print('Found device: ${device['name']} at ${device['ip']}');
          return device;
        }
        return {'ip': item.toString(), 'name': 'Google TV'};
      }).toList();
      
      return devices;
    } on PlatformException catch (e) {
      // Return empty list instead of throwing to prevent crashes
      print('Google TV discovery PlatformException: ${e.message}');
      print('Error code: ${e.code}, Details: ${e.details}');
      return [];
    } catch (e) {
      // Return empty list for any other errors
      print('Google TV discovery error: $e');
      return [];
    }
  }
}

