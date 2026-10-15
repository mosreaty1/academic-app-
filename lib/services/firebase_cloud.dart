import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../data/app_state.dart';
import '../firebase_options.dart';
import '../models/models.dart';
import 'cloud_sync.dart';

/// Firebase (Auth + Cloud Firestore) implementation of [CloudSync].
///
/// Data model (see FIREBASE_SETUP.md and firestore.rules):
///   users/{uid}            profile; uid is also the app-level user id
///   lessons/{id}           video lessons
///   subscriptions/{id}     one document per purchase / activation
///   codes/{CODE}           prepaid activation codes
///   progress/{sid_lesson}  watched fraction per student and lesson
class FirebaseCloud implements CloudSync {
  FirebaseCloud._();

  /// Returns null when Firebase is not configured (offline demo mode).
  static Future<CloudSync?> tryInit() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      return FirebaseCloud._();
    } catch (_) {
      return null;
    }
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Student IDs and phone numbers are mapped to a synthetic e-mail so that
  /// plain Email/Password auth can be used.
  static String emailFor(String id) => '${id.trim().toLowerCase()}@rashia.app';

  // ---- profile mapping ------------------------------------------------------

  UserProfile _profile(String uid, Map<String, dynamic> d) {
    final role = UserRole.values.firstWhere(
        (r) => r.name == d['role'],
        orElse: () => UserRole.student);
    return UserProfile(
      id: uid,
      name: Bi((d['nameAr'] ?? d['nameEn'] ?? '') as String,
          (d['nameEn'] ?? d['nameAr'] ?? '') as String),
      role: role,
      grade: (d['grade'] as num?)?.toInt() ?? 0,
      section: (d['section'] ?? '') as String,
      color: Color((d['color'] as num?)?.toInt() ?? 0xFF0E7C66),
      childIds: List<String>.from(d['childIds'] ?? const []),
      phone: (d['phone'] ?? '') as String,
      code: (d['code'] ?? '') as String,
    );
  }

  Map<String, dynamic> _profileMap(UserProfile u) => {
        'nameAr': u.name.ar,
        'nameEn': u.name.en,
        'role': u.role.name,
        'grade': u.grade,
        'section': u.section,
        'color': u.color.toARGB32(),
        'childIds': u.childIds,
        'phone': u.phone,
        'code': u.code,
        'createdAt': FieldValue.serverTimestamp(),
      };

  // ---- auth -----------------------------------------------------------------

  @override
  Future<UserProfile?> currentUser() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    try {
      final snap = await _db.collection('users').doc(u.uid).get();
      if (!snap.exists) return null;
      return _profile(u.uid, snap.data()!);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<SignInResult> signIn(String id, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: emailFor(id), password: password);
      final snap = await _db.collection('users').doc(cred.user!.uid).get();
      if (!snap.exists) {
        await _auth.signOut();
        return const SignInResult.fail('other');
      }
      return SignInResult.ok(_profile(cred.user!.uid, snap.data()!));
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-credential':
        case 'invalid-email':
        case 'user-not-found':
        case 'wrong-password':
          return const SignInResult.fail('invalid');
        case 'network-request-failed':
          return const SignInResult.fail('network');
        default:
          return const SignInResult.fail('other');
      }
    } catch (_) {
      return const SignInResult.fail('other');
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  // ---- loading --------------------------------------------------------------

  DateTime _ts(Object? v) =>
      v is Timestamp ? v.toDate() : DateTime.fromMillisecondsSinceEpoch(0);

  Subscription _sub(Map<String, dynamic> d) => Subscription(
        studentId: d['studentId'] as String,
        planId: d['planId'] as String,
        start: _ts(d['start']),
        end: _ts(d['end']),
        source: SubSource.values.firstWhere((x) => x.name == d['source'],
            orElse: () => SubSource.manual),
      );

  Lesson _lesson(String id, Map<String, dynamic> d) => Lesson(
        id: id,
        title: Bi((d['titleAr'] ?? '') as String, (d['titleEn'] ?? d['titleAr'] ?? '') as String),
        description: Bi((d['descAr'] ?? '') as String, (d['descEn'] ?? d['descAr'] ?? '') as String),
        grade: (d['grade'] as num?)?.toInt() ?? 1,
        chapter: Bi((d['chapterAr'] ?? '') as String, (d['chapterEn'] ?? d['chapterAr'] ?? '') as String),
        videoUrl: (d['videoUrl'] ?? '') as String,
        minutes: (d['minutes'] as num?)?.toInt() ?? 0,
        premium: (d['premium'] ?? true) as bool,
        order: (d['order'] as num?)?.toInt() ?? 0,
        added: _ts(d['added']),
      );

  @override
  Future<void> load(AppState s) async {
    final me = s.me ?? await currentUser();
    final uid = _auth.currentUser?.uid;
    if (me == null || uid == null) return;
    final teacher = me.role == UserRole.teacher;

    // Lessons (everyone). A brand-new project gets the sample lessons once,
    // uploaded by the teacher.
    final seeded = List<Lesson>.of(s.lessons);
    s.lessons.clear();
    final ls = await _db.collection('lessons').get();
    for (final d in ls.docs) {
      s.lessons.add(_lesson(d.id, d.data()));
    }
    if (s.lessons.isEmpty && teacher) {
      for (final l in seeded) {
        await saveLesson(l);
        s.lessons.add(l);
      }
    }

    // Students the user may see.
    List<String> studentIds;
    if (teacher) {
      final us = await _db.collection('users').get();
      for (final d in us.docs) {
        final p = _profile(d.id, d.data());
        final i = s.users.indexWhere((x) => x.id == p.id);
        if (i >= 0) {
          s.users[i] = p;
        } else {
          s.users.add(p);
        }
      }
      studentIds = [];
    } else if (me.role == UserRole.parent) {
      studentIds = me.childIds;
      for (final id in studentIds) {
        final d = await _db.collection('users').doc(id).get();
        if (d.exists && !s.users.any((u) => u.id == id)) {
          s.users.add(_profile(id, d.data()!));
        }
      }
    } else {
      studentIds = [uid];
    }

    // Subscriptions + watch progress.
    s.subscriptions.clear();
    s.lessonProgress.clear();
    if (teacher) {
      for (final d in (await _db.collection('subscriptions').get()).docs) {
        s.subscriptions.add(_sub(d.data()));
      }
      for (final d in (await _db.collection('progress').get()).docs) {
        final m = d.data();
        s.lessonProgress.putIfAbsent(m['studentId'] as String, () => {})[m['lessonId'] as String] =
            (m['value'] as num).toDouble();
      }
      s.codes.clear();
      for (final d in (await _db.collection('codes').orderBy('created', descending: true).get()).docs) {
        final m = d.data();
        s.codes.add(ActivationCode(
          code: d.id,
          planId: m['planId'] as String,
          grade: (m['grade'] as num?)?.toInt() ?? 0,
          created: _ts(m['created']),
          usedBy: m['usedBy'] as String?,
          usedAt: m['usedAt'] == null ? null : _ts(m['usedAt']),
        ));
      }
    } else {
      for (final id in studentIds) {
        final subs = await _db.collection('subscriptions').where('studentId', isEqualTo: id).get();
        for (final d in subs.docs) {
          s.subscriptions.add(_sub(d.data()));
        }
        final pr = await _db.collection('progress').where('studentId', isEqualTo: id).get();
        for (final d in pr.docs) {
          final m = d.data();
          s.lessonProgress.putIfAbsent(id, () => {})[m['lessonId'] as String] =
              (m['value'] as num).toDouble();
        }
      }
    }
  }

  // ---- writes ----------------------------------------------------------------

  Future<void> _safe(Future<void> Function() f) async {
    try {
      await f();
    } catch (e) {
      debugPrint('Firestore write failed: $e');
    }
  }

  @override
  Future<void> saveSubscription(Subscription x) => _safe(() => _db.collection('subscriptions').add({
        'studentId': x.studentId,
        'planId': x.planId,
        'start': Timestamp.fromDate(x.start),
        'end': Timestamp.fromDate(x.end),
        'source': x.source.name,
      }));

  @override
  Future<void> saveCode(ActivationCode c) => _safe(() => _db.collection('codes').doc(c.code).set({
        'planId': c.planId,
        'grade': c.grade,
        'created': Timestamp.fromDate(c.created),
        'usedBy': c.usedBy,
      }));

  @override
  Future<void> saveLesson(Lesson l) => _safe(() => _db.collection('lessons').doc(l.id).set({
        'titleAr': l.title.ar,
        'titleEn': l.title.en,
        'descAr': l.description.ar,
        'descEn': l.description.en,
        'grade': l.grade,
        'chapterAr': l.chapter.ar,
        'chapterEn': l.chapter.en,
        'videoUrl': l.videoUrl,
        'minutes': l.minutes,
        'premium': l.premium,
        'order': l.order,
        'added': Timestamp.fromDate(l.added),
      }));

  @override
  Future<void> deleteLesson(String id) => _safe(() => _db.collection('lessons').doc(id).delete());

  @override
  Future<void> saveProgress(String studentId, String lessonId, double value) =>
      _safe(() => _db.collection('progress').doc('${studentId}_$lessonId').set({
            'studentId': studentId,
            'lessonId': lessonId,
            'value': value,
            'updated': FieldValue.serverTimestamp(),
          }));

  @override
  Future<String> claimCode(String code, String studentId) async {
    try {
      final ref = _db.collection('codes').doc(code);
      final stuSnap = await _db.collection('users').doc(studentId).get();
      final grade = (stuSnap.data()?['grade'] as num?)?.toInt() ?? 0;
      String result = 'ok';
      String planId = 'monthly';
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) {
          result = 'invalid';
          return;
        }
        final d = snap.data()!;
        if (d['usedBy'] != null) {
          result = 'used';
          return;
        }
        final g = (d['grade'] as num?)?.toInt() ?? 0;
        if (g != 0 && g != grade) {
          result = 'wrong_grade';
          return;
        }
        planId = d['planId'] as String;
        tx.update(ref, {'usedBy': studentId, 'usedAt': FieldValue.serverTimestamp()});
      });
      if (result != 'ok') return result;

      // Extend from the end of a still-running subscription, else from now.
      final now = DateTime.now();
      final all = await _db
          .collection('subscriptions')
          .where('studentId', isEqualTo: studentId)
          .get();
      var from = now;
      for (final d in all.docs) {
        final e = _ts(d.data()['end']);
        if (e.isAfter(from)) from = e;
      }
      final plan = AppState.plan(planId);
      final end = DateTime(from.year, from.month + plan.months, from.day);
      await _db.collection('subscriptions').add({
        'studentId': studentId,
        'planId': planId,
        'start': Timestamp.fromDate(now),
        'end': Timestamp.fromDate(end),
        'source': SubSource.code.name,
        'codeId': code,
      });
      return 'ok';
    } on FirebaseException catch (e) {
      debugPrint('claimCode failed: ${e.code}');
      return e.code == 'unavailable' ? 'network' : 'invalid';
    }
  }

  @override
  Future<String> createStudent(UserProfile draft, String password) async {
    // A secondary app instance creates the Auth user without signing the
    // teacher out of the primary session.
    FirebaseApp? secondary;
    try {
      secondary = await Firebase.initializeApp(
          name: 'account-creator', options: Firebase.app().options);
    } catch (_) {
      secondary = Firebase.app('account-creator');
    }
    final auth = FirebaseAuth.instanceFor(app: secondary);
    final cred = await auth.createUserWithEmailAndPassword(
        email: emailFor(draft.code), password: password);
    final uid = cred.user!.uid;
    await auth.signOut();
    await _db.collection('users').doc(uid).set(_profileMap(draft));

    // Link to an existing parent account with the same phone number.
    if (draft.phone.isNotEmpty) {
      final parents = await _db
          .collection('users')
          .where('role', isEqualTo: 'parent')
          .where('phone', isEqualTo: draft.phone)
          .get();
      for (final p in parents.docs) {
        await p.reference.update({'childIds': FieldValue.arrayUnion([uid])});
      }
    }
    return uid;
  }
}
