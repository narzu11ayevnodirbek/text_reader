import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../hooks/use_camera_controller.dart';
import '../hooks/use_update_checker.dart';
import '../services/text_scanner_service.dart';
import '../services/update_service.dart';

class ScannerScreen extends HookWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final camera = useCameraController();
    final updates = useUpdateChecker();
    final scannerService = useMemoized(TextScannerService.new);
    useEffect(() => scannerService.dispose, [scannerService]);

    final jshshirController = useTextEditingController();
    final cardController = useTextEditingController();
    final isProcessing = useState(false);

    Future<void> scanDocument() async {
      if (camera == null || isProcessing.value) {
        return;
      }

      isProcessing.value = true;
      try {
        final XFile image = await camera.takePicture();
        final InputImage inputImage = InputImage.fromFilePath(image.path);

        final String recognizedText = await scannerService.recognizeText(inputImage);
        debugPrint("OCR natijasi:\n$recognizedText");

        final String? jshshir = scannerService.extractJSHSHIR(recognizedText);
        final String? cardNumber = scannerService.extractCardNumber(recognizedText);
        if (!context.mounted) return;

        if (jshshir != null) {
          jshshirController.text = jshshir;
        }
        if (cardNumber != null) {
          cardController.text = cardNumber;
        }

        if (jshshir == null && cardNumber == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Hech narsa topilmadi. Qaytadan urinib ko'ring.")));
        }
      } catch (e) {
        debugPrint("Xatolik yuz berdi: $e");
      } finally {
        if (context.mounted) {
          isProcessing.value = false;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hujjat Skaneri'),
        actions: [
          if (UpdateService.isSupported)
            IconButton(
              tooltip: 'Yangilanishlarni tekshirish',
              onPressed: updates.isChecking ? null : updates.check,
              icon: updates.isChecking
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.system_update),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: camera != null ? CameraPreview(camera) : const Center(child: CircularProgressIndicator()),
          ),

          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: jshshirController,
                      decoration: const InputDecoration(labelText: 'JSHSHIR (PINFL)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cardController,
                      decoration: const InputDecoration(labelText: 'Karta raqami', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: isProcessing.value ? null : scanDocument,
                      icon: isProcessing.value
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.document_scanner),
                      label: const Text("O'qish"),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
