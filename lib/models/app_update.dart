/// Serverdagi `version.json` ichidagi yangilanish haqidagi ma'lumot.
class AppUpdate {
  const AppUpdate({
    required this.versionCode,
    required this.versionName,
    required this.apkUrl,
    this.sha256,
    this.minVersionCode = 0,
    this.releaseNotes = '',
  });

  /// [manifestUri] — `version.json` manzili. `apkUrl` nisbiy bo'lsa, shu manzilga nisbatan to'liq URL qilinadi.
  factory AppUpdate.fromJson(Map<String, dynamic> json, Uri manifestUri) {
    final sha256 = (json['sha256'] as String?)?.trim().toLowerCase();
    return AppUpdate(
      versionCode: json['versionCode'] as int,
      versionName: json['versionName'] as String,
      apkUrl: manifestUri.resolve(json['apkUrl'] as String).toString(),
      sha256: sha256 == null || sha256.isEmpty ? null : sha256,
      minVersionCode: json['minVersionCode'] as int? ?? 0,
      releaseNotes: json['releaseNotes'] as String? ?? '',
    );
  }

  /// Android `versionCode` (pubspec'dagi `+` dan keyingi raqam). Faqat shu raqam solishtiriladi.
  final int versionCode;

  /// Foydalanuvchiga ko'rsatiladigan versiya, masalan `0.2.0`.
  final String versionName;
  final String apkUrl;

  /// APK faylining SHA-256 yig'indisi. Berilsa, yuklangan fayl o'rnatishdan oldin shu bilan tekshiriladi.
  final String? sha256;

  /// Bundan eski versiyadagi foydalanuvchilar yangilanmasdan ilovadan foydalana olmaydi.
  final int minVersionCode;
  final String releaseNotes;

  bool isNewerThan(int currentVersionCode) => versionCode > currentVersionCode;

  bool isForcedFor(int currentVersionCode) => currentVersionCode < minVersionCode;
}
