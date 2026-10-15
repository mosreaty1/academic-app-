# Dr. Rashia Biology Academy 🧬

A Flutter mobile app for **Dr. Rashia's Biology classes** – Egyptian Secondary School, **Grades 1, 2 and 3**.
Fully bilingual (**Arabic RTL** by default / English), light + dark mode, one codebase for three roles.

## Roles & features

| | Student | Parent (monitor) | Teacher (Dr. Rashia) |
|---|---|---|---|
| Dashboard (schedule, alerts, quick access) | ✅ | ✅ (child switcher, daily alerts) | ✅ (needs-attention list) |
| **Attendance** | calendar + rate | child's calendar + warnings | roll-call per grade/day, notify parents |
| **Exams** – MCQ + written | take with timer, auto-submit, review | view results | create from bank, grade written answers |
| **Question bank** | practice with instant feedback, bookmarks, filters | – | add / browse MCQ & written questions |
| **Homework** | submit text/attachment, see marks & feedback | view status | publish, grade + feedback |
| **Study materials** | PDF / video / slides / images, offline mark, progress | – | upload |
| **Books store** | catalogue, cart, checkout (COD / wallet / card), order tracking | same | add products, manage orders |
| **Tickets / support** | chat with teacher (absence excuse, academic, technical…) | same | reply, change status |
| Progress report | exam bars + chapter mastery | ✅ | per-student reports |
| Announcements & notifications | ✅ | ✅ | publish (per grade) |

Demo login: pick a role (and a grade for students) on the sign-in screen – no real credentials needed.

## Run

```bash
flutter pub get
flutter run            # Android / iOS
flutter run -d chrome  # web preview
flutter test           # smoke + flow tests
```

Requires Flutter 3.32+ (tested on 3.47 stable). The Cairo font is fetched by `google_fonts`
on first launch; bundle it under `assets/` for fully offline use.

## Architecture

```
lib/
  core/      theme, bilingual helpers (Bi, tr()), shared widgets
  models/    plain Dart models + display helpers
  data/      AppState (ChangeNotifier, the single source of truth) + Seed demo data
  screens/
    auth/    splash, login
    shell/   bottom-navigation shells per role
    common/  screens shared by roles (attendance, exams, question bank, homework,
             materials, store, tickets, announcements, progress, more/settings)
    student/ parent/ teacher/   role dashboards and teacher tools
```

All data lives **in memory** (`AppState`, seeded by `Seed`). To go to production, swap the mutating
methods in `AppState` for API / Firebase calls (auth, Firestore, storage for materials, FCM for
push notifications, a payment gateway such as Fawry/Paymob for the store) – the UI only talks to `AppState`.
