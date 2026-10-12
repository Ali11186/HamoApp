"""Test phone+password login against Firebase Auth.
Run from the project root:  python tools/login_test.py
"""
import getpass
import json
import urllib.request
import urllib.error

with open("android/app/google-services.json", encoding="utf-8") as f:
    cfg = json.load(f)
API_KEY = cfg["client"][0]["api_key"][0]["current_key"]

phone = input("Phone: ").strip().replace(" ", "").replace("-", "")
password = getpass.getpass("Password: ")
if phone.startswith("+20"):
    phone = "0" + phone[3:]
elif phone.startswith("20") and len(phone) > 10:
    phone = "0" + phone[2:]
if not phone.startswith("0"):
    phone = "0" + phone
email = f"{phone}@aliapp.local"
print("\nFirebase account:", email)

req = urllib.request.Request(
    f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}",
    data=json.dumps({"email": email, "password": password, "returnSecureToken": True}).encode(),
    headers={"Content-Type": "application/json"},
    method="POST",
)
try:
    with urllib.request.urlopen(req, timeout=20) as r:
        d = json.loads(r.read())
    print("\n✅ تم تسجيل الدخول | UID:", d["localId"])
except urllib.error.HTTPError as e:
    msg = json.loads(e.read()).get("error", {}).get("message", "UNKNOWN")
    print("\n❌ فشل تسجيل الدخول:", msg)
