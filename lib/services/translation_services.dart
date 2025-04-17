//Xử lí diịch thuật (Libre Translation)
import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  final String _baseUrl = 'https://libretranslate.de';  // Instance công khai của LibreTranslate

  Future<String> translate(String text, String targetLang) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'q': text,
          'source': 'en-US',
          'target': targetLang,
          'format': 'text',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translatedText'] ?? 'Lỗi dịch';
      } else {
        return 'Lỗi: ${response.statusCode}';
      }
    } catch (e) {
      return 'Lỗi dịch: $e';
    }
  }
}