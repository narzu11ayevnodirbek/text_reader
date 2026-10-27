import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/app_update.dart';

class UpdateService {
  // GitHub `releases/latest/download/...` manzili doim eng oxirgi relizdagi faylga yo'naltiradi.
  // Boshqa manzil kerak bo'lsa: `--dart-define=UPDATE_MANIFEST_URL=https://...`.
  static const String manifestUrl = String.fromEnvironment(
    'UPDATE_MANIFEST_URL',
    defaultValue: 'https://github.com/narzu11ayevnodirbek/text_reader/releases/latest/download/version.json',
  );

  /// APKni faqat Android o'rnata oladi, boshqa platformalarda yangilash o'chiq.
  static bool get isSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<PackageInfo> currentVersion() => PackageInfo.fromPlatform();

  /// Serverda yangiroq versiya bo'lsa uni, aks holda `null` qaytaradi.
  /// Tarmoq yoki JSON xatosida exception otadi.
  Future<AppUpdate?> checkForUpdate() async {
    if (!isSupported) return null;

    final manifestUri = Uri.parse(manifestUrl);
    // CDN yoki proxy eski version.json ni keshdan berib yubormasligi uchun.
    final response = await http
        .get(manifestUri, headers: const {'Cache-Control': 'no-cache'})
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', manifestUri);
    }

    // `response.body` charset ko'rsatilmasa latin1 deb o'qiydi, o'zbekcha matn buzilmasligi uchun utf8.
    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final update = AppUpdate.fromJson(json, manifestUri);
    final current = await currentVersion();
    return update.isNewerThan(int.parse(current.buildNumber)) ? update : null;
  }

  /// APKni yuklab oladi va Android o'rnatish oynasini ochadi. Jarayon holatlari [OtaEvent] bo'lib keladi.
  Stream<OtaEvent> downloadAndInstall(AppUpdate update) {
    // OtaUpdate stream'ni o'z ichida saqlab qoladi, shuning uchun har yuklashga yangi obyekt kerak.
    return OtaUpdate().execute(
      update.apkUrl,
      // Nom doim bir xil: plagin yangi yuklashdan oldin eskisini o'chiradi, xotirada APKlar to'planib qolmaydi.
      destinationFilename: 'text_reader-update.apk',
      sha256checksum: update.sha256,
    );
  }

  Future<void> cancelDownload() => OtaUpdate().cancel();
}
