// Yangi versiyani chiqarish uchun fayllarni tayyorlaydi (GitHub Actions ham shuni ishlatadi):
//
//   dart run tool/make_update.dart [--notes "Nima o'zgardi" | --notes-file notes.txt] [--min-version-code 3]
//                                  [--build-number N] [--apk-base-url URL] [--manifest-url URL] [--debug]
//
// Natija: build/ota/ ichida text_reader-<versionCode>.apk va version.json.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

Future<void> main(List<String> args) async {
  var notes = '';
  var minVersionCode = 0;
  int? buildNumber;
  String? apkBaseUrl;
  String? manifestUrl;
  var debug = false;

  for (var i = 0; i < args.length; i++) {
    String value() => i + 1 < args.length ? args[++i] : _fail('${args[i]} dan keyin qiymat yozing');
    switch (args[i]) {
      case '--notes':
        notes = value();
      case '--notes-file':
        notes = File(value()).readAsStringSync();
      case '--min-version-code':
        minVersionCode = int.tryParse(value()) ?? _fail('--min-version-code butun son bo\'lishi kerak');
      case '--build-number':
        buildNumber = int.tryParse(value()) ?? _fail('--build-number butun son bo\'lishi kerak');
      case '--apk-base-url':
        apkBaseUrl = value();
      case '--manifest-url':
        manifestUrl = value();
      case '--debug':
        debug = true;
      default:
        _fail('Noma\'lum argument: ${args[i]}');
    }
  }

  final pubspec = File('pubspec.yaml').readAsStringSync();
  final match = RegExp(r'^version:\s*([^+\s]+)\+(\d+)\s*$', multiLine: true).firstMatch(pubspec);
  if (match == null) _fail('pubspec.yaml da "version: 1.2.3+4" ko\'rinishidagi qator topilmadi');
  final versionName = match.group(1)!;
  // --build-number pubspec dagi '+' dan keyingi raqam o'rniga ishlatiladi (GitHub Actions uni oshirib berishi mumkin).
  final versionCode = buildNumber ?? int.parse(match.group(2)!);

  if (!debug && !File('android/key.properties').existsSync()) {
    stderr.writeln(
      'Ogohlantirish: android/key.properties yo\'q — APK debug kalit bilan imzolanadi '
      'va boshqa kalit bilan imzolangan versiyalar ustiga o\'rnatilmaydi.',
    );
  }

  final mode = debug ? 'debug' : 'release';
  stdout.writeln('==> flutter build apk --$mode ($versionName+$versionCode)');
  final build = await Process.start(
    'flutter',
    [
      'build',
      'apk',
      '--$mode',
      '--build-number=$versionCode',
      // Yangi APK ham keyingi yangilanishlarni shu manzildan qidirishi uchun.
      if (manifestUrl != null) '--dart-define=UPDATE_MANIFEST_URL=$manifestUrl',
    ],
    mode: ProcessStartMode.inheritStdio,
    runInShell: Platform.isWindows,
  );
  if (await build.exitCode != 0) _fail('flutter build muvaffaqiyatsiz tugadi');

  final outDir = Directory('build/ota');
  if (outDir.existsSync()) outDir.deleteSync(recursive: true);
  outDir.createSync(recursive: true);

  final apkName = 'text_reader-$versionCode.apk';
  final apk = File('build/app/outputs/flutter-apk/app-$mode.apk').copySync('${outDir.path}/$apkName');
  final checksum = await sha256.bind(apk.openRead()).first;

  final manifest = {
    'versionCode': versionCode,
    'versionName': versionName,
    // Base URL berilmasa nisbiy manzil: ilova uni version.json turgan papkaga nisbatan to'liq URL qiladi.
    'apkUrl': apkBaseUrl == null ? apkName : Uri.parse(apkBaseUrl).resolve(apkName).toString(),
    'sha256': checksum.toString(),
    'minVersionCode': minVersionCode,
    'releaseNotes': notes.trim(),
  };
  File('${outDir.path}/version.json').writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(manifest)}\n');

  stdout
    ..writeln()
    ..writeln('Tayyor: ${outDir.path}/')
    ..writeln('  $apkName  (${(apk.lengthSync() / 1024 / 1024).toStringAsFixed(1)} MB)')
    ..writeln('  version.json')
    ..writeln('  sha256: $checksum');
}

Never _fail(String message) {
  stderr.writeln('Xato: $message');
  exit(1);
}
