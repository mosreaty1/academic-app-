# Connecting the app to Firebase

Until you do this the app runs in **offline demo mode** (sample data, demo accounts).
Once `lib/firebase_options.dart` contains your real project options, the app switches to
Firebase automatically - no other code change is needed.

## What is stored in Firebase

| Feature | Backend |
|---|---|
| Sign-in (Student ID / phone + password) | Firebase Authentication (Email/Password) |
| Student, parent, teacher profiles | Firestore `users/{uid}` |
| Video lessons | Firestore `lessons` |
| Subscriptions + activation codes | Firestore `subscriptions`, `codes` |
| Lesson watch progress | Firestore `progress` |

Student IDs and phone numbers are mapped to a synthetic e-mail (`rb2-1001@rashia.app`) so plain
Email/Password auth can be used. Nobody receives e-mail at those addresses.

> Not on Firebase yet: attendance, exams, homework, question bank, store orders, tickets,
> announcements. They still use the built-in sample data (per device). They follow the same
> pattern (`CloudSync` in `lib/services/`), see "Next steps" below.

## 1. Create the project

1. <https://console.firebase.google.com> -> **Add project**.
2. **Build -> Authentication -> Get started -> Email/Password -> Enable**.
3. **Build -> Firestore Database -> Create database** (production mode, a nearby region).
4. **Firestore -> Rules**: paste the contents of `firestore.rules` and **Publish**.

## 2. Link the Flutter app

```bash
dart pub global activate flutterfire_cli
firebase login
flutterfire configure        # pick the project, platforms: android (+ ios/web if needed)
```

This overwrites `lib/firebase_options.dart`. Then `flutter run`.

## 3. Create Dr. Rashia's teacher account (once, by hand)

The teacher cannot be created from inside the app (nobody is allowed to write yet).

1. **Authentication -> Users -> Add user**
   - Email: `<teacher phone>@rashia.app`, e.g. `01001234567@rashia.app`
   - Password: choose one. Copy the generated **User UID**.
2. **Firestore -> Start collection `users` -> Document ID = that UID**, fields:

   | field | type | value |
   |---|---|---|
   | role | string | `teacher` |
   | nameAr | string | `د. راشيا` |
   | nameEn | string | `Dr. Rashia` |
   | phone | string | `01001234567` |
   | grade | number | `0` |
   | section | string | |
   | code | string | |
   | color | number | `4278611046` |
   | childIds | array | (empty) |

3. Sign in to the app with the phone number + password. On first sign-in the teacher
   uploads the sample lessons automatically so the lessons section is not empty.

## 4. Day-to-day use

- **Add students**: Teacher -> More -> Students -> *Add student*. The app creates the Firebase
  account and shows the generated **Student ID + password** to give to the student.
  If a parent account with the same phone exists the child is linked automatically.
- **Parents**: create the same way as the teacher (Auth user `<phone>@rashia.app` plus a
  `users/{uid}` document with `role: parent` and `childIds: [<student uids>]`).
- **Lessons**: Teacher -> Video lessons -> *New lesson*. Use a direct **mp4 / HLS (m3u8)** URL
  (Firebase Storage download URL, Bunny/Cloudflare Stream, Vimeo direct link, ...).
  YouTube links are not playable by the built-in player.
- **Subscriptions**: Teacher -> Subscriptions & codes. Activate a student manually, or generate
  prepaid codes (copied to the clipboard, ready for WhatsApp). Students/parents redeem a code on
  the Subscription screen.

## Known limits (read before launch)

- **Online payment is not connected.** In Firebase mode the "Pay" button is disabled on purpose
  (it would otherwise grant access without a real payment). Integrate Fawry / Paymob / Stripe and
  grant the subscription from a **Cloud Function** webhook, then enable the button.
- Premium videos are hidden by the app, not encrypted. A technical student who knows a URL can
  still open it. For strict protection serve videos through signed, expiring URLs.
- Code redemption is checked by the client plus `firestore.rules`. A Cloud Function (Blaze plan)
  is the stricter option.
- Passwords are chosen by the app at account creation. Add a "reset password" flow
  (the teacher can reset it from the Firebase console) before wide rollout.

## Next steps (same pattern)

Add collections for attendance, exams/attempts, homework/submissions, tickets and orders by
implementing more methods in `CloudSync` / `FirebaseCloud` and calling them from the matching
`AppState` methods.
