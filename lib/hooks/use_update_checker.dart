import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/app_update.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';

/// Ilova ochilganda yangilanishni jimgina tekshiradi: faqat yangi versiya bo'lsa dialog chiqadi.
/// Qaytgan `check` — "Yangilanishlarni tekshirish" tugmasi uchun, u natijani SnackBar orqali ham aytadi.
({bool isChecking, VoidCallback check}) useUpdateChecker() {
  final context = useContext();
  final service = useMemoized(UpdateService.new);
  final isChecking = useState(false);
  // Tekshiruv ketayotganda yoki dialog ochiqligida ikkinchi marta boshlanmasin.
  final busy = useRef(false);

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> check({required bool silent}) async {
    if (busy.value) return;
    busy.value = true;
    try {
      final PackageInfo current;
      final AppUpdate? update;
      isChecking.value = true;
      try {
        current = await service.currentVersion();
        update = await service.checkForUpdate();
      } finally {
        if (context.mounted) isChecking.value = false;
      }
      if (!context.mounted) return;

      if (update == null) {
        if (!silent) showMessage("Sizda eng so'nggi versiya: ${current.version}");
        return;
      }
      await UpdateDialog.show(
        context,
        service: service,
        update: update,
        forced: update.isForcedFor(int.parse(current.buildNumber)),
      );
    } catch (e) {
      debugPrint("Yangilanishni tekshirib bo'lmadi: $e");
      if (!silent && context.mounted) showMessage("Yangilanishni tekshirib bo'lmadi. Internetni tekshiring.");
    } finally {
      busy.value = false;
    }
  }

  useEffect(() {
    if (!UpdateService.isSupported) return null;
    // Build vaqtida state o'zgartirib, dialog ochib bo'lmaydi — birinchi kadr chizilgandan keyin boshlaymiz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) check(silent: true);
    });
    return null;
  }, const []);

  return (isChecking: isChecking.value, check: () => check(silent: false));
}
