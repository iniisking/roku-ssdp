import 'package:http/http.dart' as http;

class RokuService {
  static const int rokuPort = 8060;

  // Send keypress command to Roku device
  Future<void> sendKeypress(String ipAddress, String key) async {
    final url = Uri.parse('http://$ipAddress:$rokuPort/keypress/$key');
    
    try {
      final response = await http.post(url);
      if (response.statusCode != 200) {
        throw Exception('Failed to send keypress: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending keypress: $e');
    }
  }

  // Convenience methods for directional keys
  Future<void> pressUp(String ipAddress) => sendKeypress(ipAddress, 'Up');
  Future<void> pressDown(String ipAddress) => sendKeypress(ipAddress, 'Down');
  Future<void> pressLeft(String ipAddress) => sendKeypress(ipAddress, 'Left');
  Future<void> pressRight(String ipAddress) => sendKeypress(ipAddress, 'Right');
}

