import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ota_update/ota_update.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/app_update.dart';
import '../services/update_service.dart';

enum _Phase { offer, downloading, installing, failed }

/// Yangi versiyani taklif qiladi, APKni yuklab olish jarayonini ko'rsatadi va o'rnatishni boshlaydi.
class UpdateDialog extends HookWidget {
  const UpdateDialog({super.key, required this.service, required this.update, required this.forced});

  final UpdateService service;
  final AppUpdate update;

  /// Majburiy yangilanishda dialogni yopib bo'lmaydi.
  final bool forced;

  static Future<void> show(
    BuildContext context, {
    required UpdateService service,
    required AppUpdate update,
    required bool forced,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(service: service, update: update, forced: forced),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phase = useState(_Phase.offer);
    // `null` — server Content-Length bermagan, foizni hisoblab bo'lmaydi.
    final progress = useState<double?>(null);
    final error = useState<String?>(null);
    final subscription = useRef<StreamSubscription<OtaEvent>?>(null);

    useEffect(() {
      return () {
        // Dialog yopilib ketsa, fonda yuklash davom etmasin.
        if (subscription.value != null) {
          subscription.value!.cancel();
          service.cancelDownload();
        }
      };
    }, const []);

    void onEvent(OtaEvent event) {
      if (!context.mounted) return;
      switch (event.status) {
        case OtaStatus.DOWNLOADING:
          final percent = int.tryParse(event.value ?? '');
          progress.value = percent == null ? null : percent / 100;
        case OtaStatus.INSTALLING:
        case OtaStatus.INSTALLATION_DONE:
          phase.value = _Phase.installing;
        case OtaStatus.CANCELED:
          phase.value = _Phase.offer;
        default:
          debugPrint('OTA xatolik: ${event.status.name} ${event.value}');
          error.value = _errorMessage(event.status, event.value);
          phase.value = _Phase.failed;
      }
    }

    Future<void> startDownload() async {
      // Android 8+ da har bir ilovaga alohida "Noma'lum ilovalarni o'rnatish" ruxsati kerak.
      final permission = await Permission.requestInstallPackages.request();
      if (!context.mounted) return;
      if (!permission.isGranted) {
        error.value = "Yangilash uchun sozlamalarda \"Noma'lum ilovalarni o'rnatish\"ga ruxsat bering.";
        phase.value = _Phase.failed;
        return;
      }

      progress.value = null;
      error.value = null;
      phase.value = _Phase.downloading;
      subscription.value = service.downloadAndInstall(update).listen(onEvent, onDone: () => subscription.value = null);
    }

    final theme = Theme.of(context);
    return PopScope(
      canPop: !forced && phase.value != _Phase.downloading,
      child: AlertDialog(
        title: Text(forced ? 'Yangilanish majburiy' : 'Yangi versiya mavjud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versiya ${update.versionName}', style: theme.textTheme.titleMedium),
            if (forced) ...[
              const SizedBox(height: 8),
              const Text("Ilovadan foydalanishni davom ettirish uchun uni yangilang."),
            ],
            if (update.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Flexible(child: SingleChildScrollView(child: Text(update.releaseNotes))),
            ],
            if (phase.value == _Phase.downloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: progress.value),
              const SizedBox(height: 8),
              Text(progress.value == null ? 'Yuklanmoqda...' : 'Yuklanmoqda: ${(progress.value! * 100).round()}%'),
            ],
            if (phase.value == _Phase.installing) ...[
              const SizedBox(height: 16),
              const Text(
                "O'rnatish oynasida \"O'rnatish\" tugmasini bosing. Oyna yopilib qolgan bo'lsa, qayta urinib ko'ring.",
              ),
            ],
            if (phase.value == _Phase.failed && error.value != null) ...[
              const SizedBox(height: 16),
              Text(error.value!, style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
        actions: [
          if (!forced && phase.value != _Phase.downloading)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(phase.value == _Phase.offer ? 'Keyinroq' : 'Yopish'),
            ),
          switch (phase.value) {
            _Phase.offer => FilledButton(onPressed: startDownload, child: const Text('Yangilash')),
            _Phase.downloading => TextButton(onPressed: service.cancelDownload, child: const Text('Bekor qilish')),
            _Phase.installing => FilledButton(onPressed: startDownload, child: const Text("Qayta o'rnatish")),
            _Phase.failed => FilledButton(onPressed: startDownload, child: const Text('Qayta urinish')),
          },
        ],
      ),
    );
  }
}

String _errorMessage(OtaStatus status, String? details) {
  return switch (status) {
    OtaStatus.DOWNLOAD_ERROR => "Faylni yuklab bo'lmadi. Internet aloqasini tekshiring.",
    OtaStatus.CHECKSUM_ERROR => "Yuklangan fayl buzilgan (SHA-256 mos kelmadi). Qayta urinib ko'ring.",
    OtaStatus.PERMISSION_NOT_GRANTED_ERROR => "Ilovani o'rnatishga ruxsat berilmadi.",
    OtaStatus.ALREADY_RUNNING_ERROR => 'Yuklab olish allaqachon boshlangan.',
    _ => 'Kutilmagan xatolik: ${details ?? status.name}',
  };
}
