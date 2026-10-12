#!/data/data/com.termux/files/usr/bin/bash
set -e
cd "$(dirname "$0")/.."

echo "[1/2] نشر قواعد Realtime Database للشات..."
firebase deploy --only database --project ali-offer

echo "[2/2] تم نشر قواعد الشات. ابنِ التطبيق بالأوامر التالية:"
echo "flutter clean"
echo "flutter pub get"
echo "flutter build apk --release"
