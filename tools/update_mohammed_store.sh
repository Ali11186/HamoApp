#!/data/data/com.termux/files/usr/bin/bash
set -e
cd "$(dirname "$0")/.."

echo "[1/3] نشر قواعد Firestore فقط (الصور ترفع على Cloudinary)..."
firebase deploy --only firestore:rules --project ali-offer

if command -v flutter >/dev/null 2>&1; then
  FLUTTER="flutter"
elif command -v krinry >/dev/null 2>&1; then
  FLUTTER="krinry flutter"
else
  echo "لم يتم العثور على flutter أو krinry"
  exit 1
fi

echo "[2/3] تنظيف وتثبيت الحزم..."
$FLUTTER clean
$FLUTTER pub get

echo "[3/3] بناء APK..."
$FLUTTER build apk --release

echo "تم بنجاح: قواعد الشات والصور محدثة، وAPK جاهز داخل build/app/outputs/flutter-apk/app-release.apk"
