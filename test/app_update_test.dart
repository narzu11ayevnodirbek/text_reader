import 'package:flutter_test/flutter_test.dart';
import 'package:text_reader/models/app_update.dart';

void main() {
  final manifestUri = Uri.parse('https://example.com/text_reader/version.json');

  test("barcha maydonlarni o'qiydi", () {
    final update = AppUpdate.fromJson({
      'versionCode': 5,
      'versionName': '0.3.0',
      'apkUrl': 'https://cdn.example.com/app.apk',
      'sha256': ' ABCDEF ',
      'minVersionCode': 3,
      'releaseNotes': "Karta raqamini o'qish yaxshilandi",
    }, manifestUri);

    expect(update.versionCode, 5);
    expect(update.versionName, '0.3.0');
    expect(update.apkUrl, 'https://cdn.example.com/app.apk');
    expect(update.sha256, 'abcdef');
    expect(update.minVersionCode, 3);
    expect(update.releaseNotes, "Karta raqamini o'qish yaxshilandi");
  });

  test("nisbiy apkUrl version.json turgan papkaga nisbatan to'liq bo'ladi", () {
    final update = AppUpdate.fromJson({
      'versionCode': 2,
      'versionName': '0.1.1',
      'apkUrl': 'text_reader-2.apk',
    }, manifestUri);

    expect(update.apkUrl, 'https://example.com/text_reader/text_reader-2.apk');
  });

  test("ixtiyoriy maydonlar bo'lmasa standart qiymatlar olinadi", () {
    final update = AppUpdate.fromJson({
      'versionCode': 2,
      'versionName': '0.1.1',
      'apkUrl': 'a.apk',
      'sha256': '',
    }, manifestUri);

    expect(update.sha256, isNull);
    expect(update.minVersionCode, 0);
    expect(update.releaseNotes, isEmpty);
    expect(update.isForcedFor(1), isFalse);
  });

  test('versiyalarni versionCode bo\'yicha solishtiradi', () {
    const update = AppUpdate(versionCode: 5, versionName: '0.3.0', apkUrl: 'a.apk', minVersionCode: 3);

    expect(update.isNewerThan(4), isTrue);
    expect(update.isNewerThan(5), isFalse);
    expect(update.isNewerThan(6), isFalse);
    expect(update.isForcedFor(2), isTrue);
    expect(update.isForcedFor(3), isFalse);
  });
}
