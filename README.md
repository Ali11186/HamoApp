# Ali Offers

Fork/customized from EthioShop. This version turns the marketplace into an **admin-published offers app**:

- Admins publish offers/products.
- Offers are grouped under Etisalat, Vodafone, and Bills, with provider-specific subcategories; the admin's publish and edit forms can select any of them.
- Users browse offers and open details.
- Users can contact the offer publisher (the administration) through the existing Firebase chat.
- Seller-style public marketplace flows are no longer the primary UX.
- Firebase remains the backend.
- Android cloud builds are prepared for Flutter 3.41.0, AGP 8.9.1, Gradle 8.11.1, Kotlin 2.1.0, SDK 36 and Java 17.

## Build from Termux

```bash
krinry flutter init
git add .
git commit -m "convert EthioShop to admin offers app"
git push
krinry flutter build apk --release
```

## Recent changes: phone-based login + Python admin tooling

- **Sign up / sign in now use name + phone number + password** instead of
  email. Under the hood, Firebase Auth is still used (for session
  management and security), but the app maps each phone number to an
  internal placeholder email (`<phone>@aliapp.local`) transparently —
  users never see or need an email address. New accounts always register
  as `buyer`; only `setup_admin.py` (outside the app) can grant the
  `admin` role, and `firestore.rules` blocks self-promotion.
- **Google Sign-In was removed** from the login screen to keep the auth
  flow focused on phone + password.
- **The existing per-product "Chat" button** (already present before
  these changes) now doubles as the "contact the admin" channel: since
  offers are published with `sellerId` set to the admin's UID (see
  below), tapping "Chat" on any product opens a conversation with the
  admin account automatically — no new chat system was needed.
- **`admin-scripts/`** (outside `lib/`) contains standalone Python CLI
  tools that talk to Firestore/Storage directly via `firebase-admin`,
  bypassing the app entirely:
  - `setup_admin.py` — creates/promotes the one admin account and prints
    its UID.
  - `manage_products.py` — add / edit / delete / list products, including
    image uploads to Firebase Storage. See `admin-scripts/README.md` for
    full setup and usage instructions.
- **Admin Dashboard** (Profile → Admin Dashboard, visible only to the
  `admin` role) gained a "Manage Offers" entry pointing at the existing
  seller products screen, so offers added by the Python script can also
  be edited or removed from inside the app.


> Before production use, create/use your own Firebase project and replace the Firebase configuration files.

## Firestore rules (REQUIRED once)

The app will show `permission-denied` until `firestore.rules` is published:

```bash
firebase deploy --only firestore:rules --project ali-offer
```
or paste the file into Firebase Console -> Firestore Database -> Rules -> Publish.

## Firestore indexes (REQUIRED once)

Compound queries (filter + sort on different fields) need a composite index,
or the app shows "The query requires an index" with a Retry button.
`firestore.indexes.json` already lists every index the app needs. Publish
them all at once instead of clicking each individual link as it appears:

```bash
firebase deploy --only firestore:indexes --project ali-offer
```
or do both rules and indexes together:
```bash
firebase deploy --only firestore --project ali-offer
```
Building can take a few minutes; status shows in Console -> Firestore
Database -> Indexes until it flips from "Building" to "Enabled".

## Latest fixes: chat reliability, sort indexes, real notifications, admin controls

- **Chat "Failed to load messages"**: `getOrCreateChat` used to scan every
  chat the buyer was part of client-side to find a match, which was slow
  and occasionally failed. It now derives a deterministic chat document ID
  from the two participant IDs (+ product ID), so lookup is a single
  direct read instead of a collection scan.
- **"Query requires an index" on Sort / category filters**: the Home sort
  menu (Newest, Price low/high, Top Rated, Most Popular) combined with the
  category filter produces many different compound queries. All of them
  are now listed in `firestore.indexes.json` (17 indexes total). Run
  `firebase deploy --only firestore` again after pulling this update.
- **Notifications were fake**: the Notifications tab was a static "No
  notifications" placeholder not wired to anything. It's now backed by a
  real `notifications/{userId}/items` Firestore stream
  (`lib/presentation/providers/notification_provider.dart`), with
  mark-as-read, mark-all-as-read, swipe-to-delete, and tapping a
  notification opens the related chat/order. Sending a chat message now
  also writes a notification for the recipient.
- **Admin Dashboard got more real controls**:
  - *All Users*: change any user's role (buyer/seller/admin) or delete
    their profile, in addition to the existing active/inactive toggle.
    An admin can't demote or delete their own account by mistake.
  - *All Orders*: tap the status chip (or long-press a row) to change an
    order's status directly from the list.
  - *Seller Verifications*: approve/reject now actually refreshes the
    list and shows a confirmation instead of leaving stale data on screen.

## Testing auth from the terminal

```bash
python tools/create_test_user.py   # create account (name + phone + password)
python tools/login_test.py         # verify login
```
