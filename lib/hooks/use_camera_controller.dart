import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:permission_handler/permission_handler.dart';

/// Kamera ruxsatini so'raydi va birinchi kamerani ishga tushiradi.
/// Kamera tayyor bo'lgunicha `null` qaytaradi, widget yo'qolganda o'zi dispose qilinadi.
CameraController? useCameraController() {
  final controller = useState<CameraController?>(null);

  useEffect(() {
    var disposed = false;
    CameraController? created;

    Future<void> init() async {
      final status = await Permission.camera.request();
      if (!status.isGranted || disposed) return;

      final cameras = await availableCameras();
      if (cameras.isEmpty || disposed) return;

      created = CameraController(cameras.first, ResolutionPreset.veryHigh, enableAudio: false);
      await created!.initialize();
      if (disposed) return;

      try {
        // Flesh yaltiroq kartada blik hosil qilib, raqamlarni ko'rinmas qilib qo'yadi.
        await created!.setFlashMode(FlashMode.off);
      } on CameraException catch (e) {
        debugPrint("Fleshni o'chirib bo'lmadi: $e");
      }
      if (!disposed) controller.value = created;
    }

    init();
    return () {
      disposed = true;
      created?.dispose();
    };
  }, const []);

  return controller.value;
}
