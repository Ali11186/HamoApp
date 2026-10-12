"""Create a test account (phone + password + name) exactly like the app does.
Run from the project root:  python tools/create_test_user.py
"""
import json
import urllib.request
import urllib.error
import getpass
from datetime import datetime, timezone

with open("android/app/google-services.json", encoding="utf-8") as f:
    cfg = json.load(f)

API_KEY = cfg["client"][0]["api_key"][0]["current_key"]
PROJECT_ID = cfg["project_info"]["project_id"]  # read automatically (ali-offer)


def normalize(phone: str) -> str:
    phone = phone.strip().replace(" ", "").replace("-", "")
    if phone.startswith("+20"):
        phone = phone[3:]
    elif phone.startswith("20") and len(phone) > 10:
        phone = phone[2:]
    if not phone.startswith("0"):
        phone = "0" + phone
    return phone


def post(url, body, headers=None):
    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json", **(headers or {})},
        method="POST",
    )
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())


phone = normalize(input("Phone: "))
name = input("Name: ").strip()
password = getpass.getpass("Password: ")
email = f"{phone}@aliapp.local"
print("\nFirebase account:", email)

try:
    auth = post(
        f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={API_KEY}",
        {"email": email, "password": password, "returnSecureToken": True},
    )
except urllib.error.HTTPError as e:
    print("\n❌ فشل إنشاء الحساب:", e.code, e.read().decode())
    raise SystemExit(1)

uid, token = auth["localId"], auth["idToken"]
print("✅ Firebase Auth created. UID:", uid)

doc = {
    "fields": {
        "fullName": {"stringValue": name},
        "email": {"stringValue": ""},
        "phoneNumber": {"stringValue": phone},
        "role": {"stringValue": "buyer"},
        "isEmailVerified": {"booleanValue": True},
        "isPhoneVerified": {"booleanValue": True},
        "sellerVerificationStatus": {"stringValue": "none"},
        "isActive": {"booleanValue": True},
        "language": {"stringValue": "ar"},
        "notificationsEnabled": {"booleanValue": True},
        "createdAt": {"timestampValue": datetime.now(timezone.utc).isoformat()},
        "wishlist": {"arrayValue": {"values": []}},
        "sellerRating": {"doubleValue": 0.0},
        "totalSales": {"integerValue": "0"},
    }
}
try:
    post(
        f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}"
        f"/databases/(default)/documents/users?documentId={uid}",
        doc,
        {"Authorization": "Bearer " + token},
    )
    print("✅ users/{uid} created in Firestore")
except urllib.error.HTTPError as e:
    print("❌ Auth تم لكن users/{uid} فشل:", e.code, e.read().decode())
