import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class GoogleTvService {
  static const MethodChannel _channel = MethodChannel('com.example.roku_ssdp/google_tv');
  
  // Map our keys to Android key codes
  int _getKeyCode(String key) {
    switch (key.toLowerCase()) {
      case 'up':
        return 19; // KEYCODE_DPAD_UP
      case 'down':
        return 20; // KEYCODE_DPAD_DOWN
      case 'left':
        return 21; // KEYCODE_DPAD_LEFT
      case 'right':
        return 22; // KEYCODE_DPAD_RIGHT
      default:
        return 19;
    }
  }

  // Try HTTP endpoint method (some Google TV devices support this)
  Future<void> _sendViaHttp(String ipAddress, int keyCode) async {
    // Try various endpoints and formats
    final endpoints = [
      {'port': 6466, 'path': '/keypress', 'body': '{"keycode": $keyCode}'},
      {'port': 6467, 'path': '/keypress', 'body': '{"keycode": $keyCode}'},
      {'port': 8008, 'path': '/apps/YouTube', 'body': '{"type":"KEY","keyCode":$keyCode}'},
      {'port': 8080, 'path': '/keypress', 'body': '{"keycode": $keyCode}'},
      {'port': 6466, 'path': '/remote/control', 'body': '{"key": $keyCode}'},
      {'port': 6467, 'path': '/remote/control', 'body': '{"key": $keyCode}'},
      {'port': 6466, 'path': '/input', 'body': '{"keycode": $keyCode}'},
      {'port': 6467, 'path': '/input', 'body': '{"keycode": $keyCode}'},
    ];
    
    for (final endpoint in endpoints) {
      try {
        final url = Uri.parse('http://$ipAddress:${endpoint['port']}${endpoint['path']}');
        print('Trying HTTP: $url with body: ${endpoint['body']}');
        
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: endpoint['body'],
        ).timeout(const Duration(seconds: 3));
        
        print('Response from $url: ${response.statusCode} - ${response.body}');
        
        if (response.statusCode == 200 || 
            response.statusCode == 204 || 
            response.statusCode == 201) {
          print('✓ Successfully sent keycode $keyCode via ${endpoint['port']}${endpoint['path']}');
          return;
        }
      } catch (e) {
        print('✗ Failed $ipAddress:${endpoint['port']}${endpoint['path']}: $e');
        continue;
      }
    }
    
    throw Exception('All HTTP endpoints failed');
  }

  // Main method to send keypress
  Future<void> sendKeypress(String ipAddress, String key) async {
    final keyCode = _getKeyCode(key);
    print('Sending keypress: $key (keycode: $keyCode) to $ipAddress');
    
    // Try Cast SDK via platform channel first
    try {
      final success = await _channel.invokeMethod<bool>('sendKeypress', {
        'ipAddress': ipAddress,
        'keyCode': keyCode,
      }).timeout(const Duration(seconds: 5));
      
      if (success == true) {
        print('✓ Successfully sent keypress via Cast SDK');
        return;
      }
    } on PlatformException catch (e) {
      print('Cast SDK method failed: ${e.message} - trying HTTP fallback');
    } catch (e) {
      print('Cast SDK error: $e - trying HTTP fallback');
    }
    
    // Fallback to HTTP methods
    print('Trying HTTP methods as fallback...');
    try {
      await _sendViaHttp(ipAddress, keyCode);
      print('✓ Successfully sent keypress via HTTP');
      return;
    } catch (e) {
      print('✗ All HTTP methods failed: $e');
    }
    
    // If all methods fail, throw exception
    throw Exception('Failed to send keypress. Cast SDK connection may be required. Try connecting to the device first.');
  }
  
  // Connect to Cast device (optional, for establishing Cast session)
  Future<bool> connectToDevice(String ipAddress) async {
    try {
      final success = await _channel.invokeMethod<bool>('connectToDevice', {
        'ipAddress': ipAddress,
      }).timeout(const Duration(seconds: 10));
      return success == true;
    } catch (e) {
      print('Error connecting to Cast device: $e');
      return false;
    }
  }

  Future<void> pressUp(String ipAddress) => sendKeypress(ipAddress, 'Up');
  Future<void> pressDown(String ipAddress) => sendKeypress(ipAddress, 'Down');
  Future<void> pressLeft(String ipAddress) => sendKeypress(ipAddress, 'Left');
  Future<void> pressRight(String ipAddress) => sendKeypress(ipAddress, 'Right');
}
