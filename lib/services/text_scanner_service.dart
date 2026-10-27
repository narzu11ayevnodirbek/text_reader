import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TextScannerService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  // OCR raqamlarni ko'pincha shularga o'xshash harflar deb o'qiydi.
  static const Map<String, String> _lookalikeDigits = {
    'O': '0', 'o': '0', 'D': '0', 'Q': '0',
    'I': '1', 'i': '1', 'l': '1', '|': '1',
    'Z': '2', 'z': '2',
    'S': '5', 's': '5',
    'G': '6', 'b': '6',
    'T': '7',
    'B': '8',
    'g': '9', 'q': '9',
  };

  Future<String> recognizeText(InputImage inputImage) async {
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  String? extractJSHSHIR(String text) {
    for (final token in _digitTokens(text)) {
      if (token != null && token.length == 14) {
        return token;
      }
    }
    return null;
  }

  String? extractCardNumber(String text) {
    final tokens = _digitTokens(text);
    for (var start = 0; start < tokens.length; start++) {
      final buffer = StringBuffer();
      for (var i = start; i < tokens.length && buffer.length < 16; i++) {
        final token = tokens[i];
        if (token == null || token.length % 4 != 0) {
          break;
        }
        buffer.write(token);
      }
      if (buffer.length == 16) {
        return buffer.toString();
      }
    }
    return null;
  }

  List<String?> _digitTokens(String text) {
    return text.split(RegExp(r'\s+')).map((token) {
      final digitCount = RegExp(r'\d').allMatches(token).length;
      if (digitCount * 2 < token.length) {
        return null;
      }
      final normalized = token.split('').map((c) => _lookalikeDigits[c] ?? c).join();
      return RegExp(r'^\d+$').hasMatch(normalized) ? normalized : null;
    }).toList();
  }

  void dispose() {
    _textRecognizer.close();
  }
}
