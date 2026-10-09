# Diyet Programı

Kişiselleştirilmiş beslenme ve diyet uygulaması (Flutter · Android & iOS).

## Kurulum

```bash
flutter pub get
cp env/example.env env/dev.env        # değerleri doldurun (git'e eklenmez)
flutter run --dart-define-from-file=env/dev.env
```

VS Code / Cursor için `.vscode/launch.json` içinde `dev`, `staging`, `prod`
yapılandırmaları hazırdır.

Firebase Console projesi bağlanmadan da uygulama **local-first** çalışır
(`USE_FAKE_SERVICES=true`, varsayılan). Kimlik ve veriler cihazda kalır;
senkron kuyruğu Firebase hazır olunca işlenir.

Gerçek Firebase testi için `env/dev.env` içinde `USE_FAKE_SERVICES=false`
olmalı ve `flutter run --dart-define-from-file=env/dev.env` kullanılmalıdır.

## Mimari

- **Clean Architecture**: her özellik `data / domain / presentation` katmanlarına ayrılır.
- **Riverpod** (state + dependency injection), **go_router** (yönlendirme),
  **Material 3** (açık/koyu tema), **gen-l10n** (tr, en).
- Dış servisler (`lib/shared/services`) arayüzlerle soyutlanmıştır. Gerçek
  implementasyonlar `lib/bootstrap.dart` içinde provider override ile bağlanır.
- Kullanıcı verisi **local-first** okunur: `PersistentDocumentDatabase` +
  `LocalFirstDocumentDatabase`. Firestore yalnızca senkron kuyruğu üzerinden
  yazılır; UI uzak kaynağa bağlanmaz.

## Firebase

Yerel FlutterFire çıktıları (git'e eklenmez; `.gitignore`):

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

Başlatma `FirebaseOptionsLoader` (dart-define) veya native dosyalar ile
yapılır. `DefaultFirebaseOptions` koda gömülmez; loader boşsa
`Firebase.initializeApp()` native config kullanır. Yapılandırma yoksa
uygulama `firebase=offline` ile local-first devam eder.

Bağlamak / yenilemek için:

1. Firebase Console’da mevcut projeyi kullanın (sahte project ID üretmeyin).
2. Gerekirse `flutterfire configure` ile native dosyaları yenileyin **veya**
   `env/dev.env` içinde `FIREBASE_*` dart-define değerlerini doldurun.
3. `USE_FAKE_SERVICES=false` yapın.
4. Analytics / Crashlytics için `ENABLE_ANALYTICS` ve
   `ENABLE_CRASH_REPORTING` bayraklarını açın.
5. `firestore.rules` ve `firestore.indexes.json` dosyalarını projeye deploy edin.

Google Sign-In için iOS `GIDClientID` / URL scheme değerleri
`GoogleService-Info.plist` veya dart-define (`FIREBASE_IOS_CLIENT_ID`,
`GOOGLE_SERVER_CLIENT_ID`) ile gelir; koda gömülmez.

## Güvenlik

- API anahtarları kaynak koda yazılmaz; `env/*.env` dosyaları `.gitignore` içindedir.
- İstemciye gömülen her değer okunabilir. AI ve yemek veritabanı gibi gizli
  anahtarlar yalnızca backend proxy'de (ör. Cloud Functions) tutulur; uygulama
  bu proxy'ye Firebase ID token ile istek atar.
- Firestore kuralları: kullanıcı yalnızca `users/{uid}/**` yazar; katalog
  `recipes` / `foods` salt okunur.

## Yol Haritası

- **Fotoğraftan yemek tanıma** (sonraki aşama): Fotoğraf çek → AI analiz →
  tahmini yiyecekler listelenir → kullanıcı düzenler/onaylar → öğüne eklenir.
  - AI'ın verdiği kalori ve besin değerleri kesin değer gibi gösterilmez;
    arayüzde her zaman **"tahmini"** olduğu açıkça belirtilir.
  - Onaylanmadan hiçbir kayıt öğüne eklenmez.
  - Görsel analiz, anahtarları koruyan backend proxy üzerinden yapılır.

## Komutlar

```bash
flutter analyze
flutter test
flutter gen-l10n     # .arb değişince (build sırasında otomatik de çalışır)
```
