#!/data/data/com.termux/files/usr/bin/bash
set -e
cd "$(dirname "$0")/.."
ADMIN_UID="QHMQtobX65V64nIyxNUkGSybvEB3"

echo "[1/2] تأكد أن مستند users/$ADMIN_UID موجود وأن role = admin من Firebase Console."
echo "[2/2] نشر قواعد الشات..."
firebase deploy --only firestore:rules --project ali-offer

echo "تم نشر قواعد الشات. أغلق التطبيق بالكامل وثبّت APK الجديد ثم سجّل الدخول بحساب الإدارة."
