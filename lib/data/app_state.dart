import 'dart:math';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/cloud_sync.dart';
import 'seed.dart';

/// Single source of truth for the demo app.
///
/// All data is held in memory and seeded from [Seed]. To connect a real
/// backend (Firebase / REST), replace the mutating methods below with API calls
/// and keep the same getters - the UI only talks to this class.
class AppState extends ChangeNotifier {
  AppState({this.cloud});

  /// Demo data. When [cloud] is set, students/teachers come from Firebase and
  /// only the lesson content (questions, exams, ...) is seeded locally.
  factory AppState.seeded({CloudSync? cloud}) {
    final s = AppState(cloud: cloud);
    Seed.populate(s, cloud: cloud != null);
    return s;
  }

  final CloudSync? cloud;
  bool get isCloud => cloud != null;

  // ---- Preferences ---------------------------------------------------------
  bool isAr = true;
  ThemeMode themeMode = ThemeMode.light;

  void setArabic(bool v) {
    isAr = v;
    notifyListeners();
  }

  void setDark(bool v) {
    themeMode = v ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // ---- Session -------------------------------------------------------------
  UserProfile? me;
  String? selectedChildId;

  final List<UserProfile> users = [];

  void login(UserProfile u) {
    me = u;
    selectedChildId = u.childIds.isEmpty ? null : u.childIds.first;
    notifyListeners();
  }

  void logout() {
    me = null;
    cart.clear();
    cloud?.signOut();
    notifyListeners();
  }

  /// Signs in with a student ID (e.g. `RB2-1001`) or a phone number.
  /// Returns an error code (`not_found`, `wrong_password`, `invalid`, `network`, `other`)
  /// or null on success.
  Future<String?> signIn(String id, String password) async {
    final key = id.trim().toLowerCase();
    if (key.isEmpty || password.isEmpty) return 'not_found';
    if (cloud != null) {
      final r = await cloud!.signIn(key, password);
      if (r.user == null) return r.error ?? 'other';
      if (!users.any((u) => u.id == r.user!.id)) users.add(r.user!);
      await cloud!.load(this);
      login(r.user!);
      return null;
    }
    final match = users.where(
        (u) => u.code.toLowerCase() == key || (u.code.isEmpty && u.phone == key));
    if (match.isEmpty) return 'not_found';
    if (password != Seed.demoPassword) return 'wrong_password';
    login(match.first);
    return null;
  }

  UserProfile user(String id) => users.firstWhere((u) => u.id == id);

  List<UserProfile> get students =>
      users.where((u) => u.role == UserRole.student).toList();

  List<UserProfile> studentsOfGrade(int g) =>
      students.where((u) => u.grade == g).toList();

  List<UserProfile> get children => me == null
      ? []
      : me!.childIds.map(user).toList();

  /// The student whose data is currently displayed (self, or the chosen child).
  String get activeStudentId {
    if (me!.role == UserRole.student) return me!.id;
    return selectedChildId ?? me!.childIds.first;
  }

  UserProfile get activeStudent => user(activeStudentId);

  void selectChild(String id) {
    selectedChildId = id;
    notifyListeners();
  }

  // ---- Timetable -----------------------------------------------------------
  final List<ClassSlot> timetable = [];

  List<ClassSlot> slotsFor(int weekday, {int? grade}) {
    final r = timetable
        .where((s) => s.weekday == weekday && (grade == null || s.grade == grade))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return r;
  }

  // ---- Attendance ----------------------------------------------------------
  final Map<String, Map<String, AttStatus>> attendance = {};

  Map<String, AttStatus> attendanceOf(String sid) =>
      attendance.putIfAbsent(sid, () => {});

  AttStatus? attendanceOn(String sid, DateTime d) => attendanceOf(sid)[dateKey(d)];

  void markAttendance(String sid, DateTime d, AttStatus s) {
    attendanceOf(sid)[dateKey(d)] = s;
    notifyListeners();
  }

  /// present / absent / late / excused counts and a percentage (late counts as
  /// attended).
  ({int present, int absent, int late, int excused, double pct, int total})
      attendanceStats(String sid) {
    var p = 0, a = 0, l = 0, e = 0;
    for (final s in attendanceOf(sid).values) {
      switch (s) {
        case AttStatus.present:
          p++;
        case AttStatus.absent:
          a++;
        case AttStatus.late:
          l++;
        case AttStatus.excused:
          e++;
      }
    }
    final total = p + a + l + e;
    final pct = total == 0 ? 1.0 : (p + l + e) / total;
    return (present: p, absent: a, late: l, excused: e, pct: pct, total: total);
  }

  // ---- Question bank -------------------------------------------------------
  final List<Question> questions = [];
  final Set<String> bookmarks = {};
  // studentId -> questionId -> answered correctly
  final Map<String, Map<String, bool>> practice = {};

  Question question(String id) => questions.firstWhere((q) => q.id == id);

  List<Bi> chaptersOf(int grade) {
    final seen = <String>{};
    final out = <Bi>[];
    for (final q in questions.where((q) => q.grade == grade)) {
      if (seen.add(q.chapter.en)) out.add(q.chapter);
    }
    return out;
  }

  void addQuestion(Question q) {
    questions.insert(0, q);
    notifyListeners();
  }

  void toggleBookmark(String qid) {
    if (!bookmarks.remove(qid)) bookmarks.add(qid);
    notifyListeners();
  }

  void recordPractice(String sid, String qid, bool correct) {
    practice.putIfAbsent(sid, () => {})[qid] = correct;
    notifyListeners();
  }

  /// Practice mastery (0..1) per chapter for a student.
  Map<String, double> chapterMastery(String sid) {
    final res = practice[sid] ?? {};
    final totals = <String, int>{};
    final right = <String, int>{};
    for (final e in res.entries) {
      final q = questions.where((q) => q.id == e.key);
      if (q.isEmpty) continue;
      final ch = q.first.chapter.en;
      totals[ch] = (totals[ch] ?? 0) + 1;
      if (e.value) right[ch] = (right[ch] ?? 0) + 1;
    }
    return {for (final k in totals.keys) k: right[k]! / totals[k]!};
  }

  // ---- Exams ---------------------------------------------------------------
  final List<Exam> exams = [];
  final List<ExamAttempt> attempts = [];

  List<Exam> examsOfGrade(int g) =>
      exams.where((e) => e.grade == g).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  int examTotal(Exam e) =>
      e.questionIds.fold(0, (sum, id) => sum + question(id).marks);

  ExamAttempt? attemptOf(String examId, String sid) {
    for (final a in attempts) {
      if (a.examId == examId && a.studentId == sid) return a;
    }
    return null;
  }

  List<ExamAttempt> attemptsOfStudent(String sid) =>
      attempts.where((a) => a.studentId == sid).toList()
        ..sort((a, b) => a.at.compareTo(b.at));

  List<ExamAttempt> attemptsOfExam(String examId) =>
      attempts.where((a) => a.examId == examId).toList();

  Exam exam(String id) => exams.firstWhere((e) => e.id == id);

  void addExam(Exam e) {
    exams.add(e);
    notifications.insert(
      0,
      AppNotification(
        id: 'n${notifications.length + 100}',
        title: const Bi('امتحان جديد', 'New exam'),
        body: Bi(e.title.ar, e.title.en),
        at: DateTime.now(),
        icon: Icons.quiz_rounded,
        color: AppColors.violet,
      ),
    );
    notifyListeners();
  }

  ExamAttempt submitExam(Exam e, String sid, Map<String, Object> answers) {
    var mcq = 0, writtenMax = 0, total = 0;
    for (final id in e.questionIds) {
      final q = question(id);
      total += q.marks;
      if (q.type == QType.mcq) {
        if (answers[id] == q.answer) mcq += q.marks;
      } else {
        writtenMax += q.marks;
      }
    }
    final a = ExamAttempt(
      examId: e.id,
      studentId: sid,
      answers: answers,
      mcqScore: mcq,
      writtenMax: writtenMax,
      writtenScore: 0,
      graded: writtenMax == 0,
      total: total,
      at: DateTime.now(),
    );
    attempts.add(a);
    notifyListeners();
    return a;
  }

  void gradeWritten(ExamAttempt a, int score) {
    a.writtenScore = score.clamp(0, a.writtenMax);
    a.graded = true;
    notifyListeners();
  }

  /// Average exam percentage (0..1) of graded attempts, or null.
  double? averageScore(String sid) {
    final graded = attemptsOfStudent(sid).where((a) => a.graded).toList();
    if (graded.isEmpty) return null;
    return graded.fold<double>(0, (s, a) => s + a.percent) / graded.length;
  }

  // ---- Homework ------------------------------------------------------------
  final List<Homework> homeworks = [];
  final List<Submission> submissions = [];

  List<Homework> homeworksOfGrade(int g) =>
      homeworks.where((h) => h.grade == g).toList()
        ..sort((a, b) => a.due.compareTo(b.due));

  Submission? submissionOf(String hwId, String sid) {
    for (final s in submissions) {
      if (s.hwId == hwId && s.studentId == sid) return s;
    }
    return null;
  }

  List<Submission> submissionsOf(String hwId) =>
      submissions.where((s) => s.hwId == hwId).toList();

  void addHomework(Homework h) {
    homeworks.add(h);
    notifications.insert(
      0,
      AppNotification(
        id: 'n${notifications.length + 100}',
        title: const Bi('واجب جديد', 'New homework'),
        body: h.title,
        at: DateTime.now(),
        icon: Icons.assignment_rounded,
        color: AppColors.amber,
      ),
    );
    notifyListeners();
  }

  void submitHomework(String hwId, String sid, String text) {
    submissions.removeWhere((s) => s.hwId == hwId && s.studentId == sid);
    submissions.add(Submission(
        hwId: hwId, studentId: sid, text: text, at: DateTime.now()));
    notifyListeners();
  }

  void gradeSubmission(Submission s, int mark, String feedback) {
    s.mark = mark;
    s.feedback = feedback;
    notifyListeners();
  }

  int pendingHomeworkCount(String sid) {
    final g = user(sid).grade;
    return homeworksOfGrade(g)
        .where((h) =>
            submissionOf(h.id, sid) == null && !h.due.isBefore(dayOnly(DateTime.now())))
        .length;
  }

  // ---- Materials -----------------------------------------------------------
  final List<StudyMaterial> materials = [];
  final Set<String> downloaded = {};
  final Set<String> studied = {};

  void addMaterial(StudyMaterial m) {
    materials.insert(0, m);
    notifyListeners();
  }

  void toggleDownloaded(String id) {
    if (!downloaded.remove(id)) downloaded.add(id);
    notifyListeners();
  }

  void toggleStudied(String id) {
    if (!studied.remove(id)) studied.add(id);
    notifyListeners();
  }

  // ---- Store ---------------------------------------------------------------
  final List<Book> books = [];
  final Map<String, int> cart = {};
  final List<Order> orders = [];

  int get cartCount => cart.values.fold(0, (a, b) => a + b);

  double get cartTotal => cart.entries.fold(
      0.0, (s, e) => s + books.firstWhere((b) => b.id == e.key).price * e.value);

  void addToCart(String id) {
    final b = books.firstWhere((b) => b.id == id);
    final cur = cart[id] ?? 0;
    if (cur < b.stock) cart[id] = cur + 1;
    notifyListeners();
  }

  void decFromCart(String id) {
    final cur = cart[id] ?? 0;
    if (cur <= 1) {
      cart.remove(id);
    } else {
      cart[id] = cur - 1;
    }
    notifyListeners();
  }

  void addBook(Book b) {
    books.insert(0, b);
    notifyListeners();
  }

  Order placeOrder(PayMethod pay, String address) {
    final lines = cart.entries
        .map((e) => OrderLine(books.firstWhere((b) => b.id == e.key), e.value))
        .toList();
    for (final l in lines) {
      l.book.stock -= l.qty;
    }
    final o = Order(
      id: 'ORD-${1040 + orders.length}',
      buyerId: me!.id,
      lines: lines,
      total: cartTotal,
      at: DateTime.now(),
      pay: pay,
      address: address,
    );
    orders.insert(0, o);
    cart.clear();
    notifyListeners();
    return o;
  }

  List<Order> get myOrders => me!.role == UserRole.teacher
      ? orders
      : orders.where((o) => o.buyerId == me!.id).toList();

  void setOrderStatus(Order o, OrderStatus s) {
    o.status = s;
    notifyListeners();
  }

  // ---- Tickets -------------------------------------------------------------
  final List<Ticket> tickets = [];

  List<Ticket> get myTickets => me!.role == UserRole.teacher
      ? (List.of(tickets)..sort((a, b) => b.created.compareTo(a.created)))
      : tickets.where((t) => t.authorId == me!.id).toList();

  Ticket createTicket(String subject, String category, String body) {
    final t = Ticket(
      id: 'TK-${200 + tickets.length}',
      authorId: me!.id,
      studentId: me!.role == UserRole.teacher ? '' : activeStudentId,
      subject: subject,
      category: category,
      created: DateTime.now(),
    )..messages.add(TicketMsg(false, body, DateTime.now()));
    tickets.insert(0, t);
    notifyListeners();
    return t;
  }

  void replyTicket(Ticket t, String text) {
    final staff = me!.role == UserRole.teacher;
    t.messages.add(TicketMsg(staff, text, DateTime.now()));
    if (staff && t.status == TicketStatus.open) {
      t.status = TicketStatus.inProgress;
    }
    notifyListeners();
  }

  void setTicketStatus(Ticket t, TicketStatus s) {
    t.status = s;
    notifyListeners();
  }

  int get openTicketCount =>
      tickets.where((t) => t.status != TicketStatus.resolved).length;

  // ---- Lessons (video) -----------------------------------------------------
  final List<Lesson> lessons = [];
  // studentId -> lessonId -> watched fraction 0..1
  final Map<String, Map<String, double>> lessonProgress = {};

  List<Lesson> lessonsOfGrade(int g) =>
      lessons.where((l) => l.grade == g).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  double progressOf(String sid, String lessonId) =>
      lessonProgress[sid]?[lessonId] ?? 0;

  void setLessonProgress(String sid, String lessonId, double v) {
    final cur = progressOf(sid, lessonId);
    if (v <= cur) return;
    lessonProgress.putIfAbsent(sid, () => {})[lessonId] = v.clamp(0, 1);
    cloud?.saveProgress(sid, lessonId, v.clamp(0, 1).toDouble());
    notifyListeners();
  }

  void addLesson(Lesson l) {
    lessons.add(l);
    cloud?.saveLesson(l);
    notifications.insert(
      0,
      AppNotification(
        id: 'n${notifications.length + 100}',
        title: const Bi('درس جديد', 'New lesson'),
        body: l.title,
        at: DateTime.now(),
        icon: Icons.play_circle_rounded,
        color: AppColors.violet,
      ),
    );
    notifyListeners();
  }

  void removeLesson(String id) {
    lessons.removeWhere((l) => l.id == id);
    cloud?.deleteLesson(id);
    notifyListeners();
  }

  // ---- Subscriptions ---------------------------------------------------------
  static const plans = <Plan>[
    Plan('monthly', Bi('شهري', 'Monthly'), Bi('كل الدروس لمدة شهر', 'All lessons for 1 month'), 1, 150),
    Plan('term', Bi('ترم كامل', 'Full term'), Bi('4 شهور بخصم 20%', '4 months, save 20%'), 4, 480, best: true),
    Plan('year', Bi('سنوي', 'Yearly'), Bi('سنة كاملة بأفضل سعر', 'Best value, 12 months'), 12, 1200),
  ];

  static Plan plan(String id) => plans.firstWhere((p) => p.id == id);

  final List<Subscription> subscriptions = [];
  final List<ActivationCode> codes = [];

  Subscription? subscriptionOf(String sid) {
    Subscription? best;
    for (final x in subscriptions.where((x) => x.studentId == sid)) {
      if (best == null || x.end.isAfter(best.end)) best = x;
    }
    return best;
  }

  bool hasAccess(String sid) => subscriptionOf(sid)?.active ?? false;

  bool canWatch(String sid, Lesson l) => !l.premium || hasAccess(sid);

  int get activeSubscribers =>
      students.where((u) => hasAccess(u.id)).length;

  /// Adds the plan's months on top of any still-running subscription.
  Subscription grantSubscription(String sid, Plan p, SubSource src) {
    final now = DateTime.now();
    final cur = subscriptionOf(sid);
    final from = (cur != null && cur.active) ? cur.end : now;
    final end = DateTime(from.year, from.month + p.months, from.day);
    final sub = Subscription(
        studentId: sid, planId: p.id, start: now, end: end, source: src);
    subscriptions.add(sub);
    cloud?.saveSubscription(sub);
    notifications.insert(
      0,
      AppNotification(
        id: 'n${notifications.length + 100}',
        title: const Bi('تم تفعيل الاشتراك', 'Subscription activated'),
        body: Bi('خطة ${p.name.ar} حتى ${end.day}/${end.month}/${end.year}',
            '${p.name.en} plan until ${end.day}/${end.month}/${end.year}'),
        at: now,
        icon: Icons.workspace_premium_rounded,
        color: AppColors.amber,
      ),
    );
    notifyListeners();
    return sub;
  }

  /// Mock checkout - replace with a real gateway (Fawry / Paymob) callback.
  Subscription payForPlan(String sid, Plan p, PayMethod method) =>
      grantSubscription(sid, p, SubSource.payment);

  /// Returns `ok`, `invalid`, `used` or `wrong_grade`.
  Future<String> redeemCode(String sid, String raw) async {
    final code = raw.trim().toUpperCase();
    if (code.isEmpty) return 'invalid';
    final grade = user(sid).grade;
    if (cloud != null) {
      final r = await cloud!.claimCode(code, sid);
      if (r != 'ok') return r;
      // The claimed code's plan is stored in Firestore; reload to read it.
      await cloud!.load(this);
      notifyListeners();
      return 'ok';
    }
    final c = codes.where((c) => c.code == code);
    if (c.isEmpty) return 'invalid';
    final ac = c.first;
    if (ac.used) return 'used';
    if (ac.grade != 0 && ac.grade != grade) return 'wrong_grade';
    ac.usedBy = sid;
    ac.usedAt = DateTime.now();
    grantSubscription(sid, plan(ac.planId), SubSource.code);
    return 'ok';
  }

  List<ActivationCode> generateCodes(String planId, int grade, int n) {
    final out = <ActivationCode>[];
    final rnd = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    for (var i = 0; i < n; i++) {
      String code;
      do {
        final b = StringBuffer();
        for (var k = 0; k < 8; k++) {
          b.write(chars[rnd.nextInt(chars.length)]);
          if (k == 3) b.write('-');
        }
        code = b.toString();
      } while (codes.any((c) => c.code == code));
      final c = ActivationCode(
          code: code,
          planId: planId,
          grade: grade,
          created: DateTime.now());
      codes.insert(0, c);
      cloud?.saveCode(c);
      out.add(c);
    }
    notifyListeners();
    return out;
  }

  // ---- Students (IDs) ----------------------------------------------------------
  String nextStudentCode(int grade) {
    final n = students.where((s) => s.grade == grade).length;
    var i = 1000 + n + 1;
    while (users.any((u) => u.code == 'RB$grade-$i')) {
      i++;
    }
    return 'RB$grade-$i';
  }

  /// Registers a student and returns the credentials to hand over.
  Future<UserProfile> addStudent({
    required Bi name,
    required int grade,
    required String section,
    required String parentPhone,
    required String password,
  }) async {
    var u = UserProfile(
      id: 'st${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      role: UserRole.student,
      grade: grade,
      section: '$grade/$section',
      color: [AppColors.primary, AppColors.sky, AppColors.violet, AppColors.rose, AppColors.amber][users.length % 5],
      phone: parentPhone,
      code: nextStudentCode(grade),
    );
    if (cloud != null) {
      final uid = await cloud!.createStudent(u, password);
      u = UserProfile(
          id: uid,
          name: u.name,
          role: u.role,
          grade: u.grade,
          section: u.section,
          color: u.color,
          phone: u.phone,
          code: u.code);
    }
    users.add(u);
    // Link to a parent account with the same phone number.
    for (var i = 0; i < users.length; i++) {
      final p = users[i];
      if (p.role == UserRole.parent && p.phone == parentPhone && parentPhone.isNotEmpty) {
        users[i] = UserProfile(
            id: p.id,
            name: p.name,
            role: p.role,
            color: p.color,
            phone: p.phone,
            childIds: [...p.childIds, u.id]);
        if (me?.id == p.id) me = users[i];
      }
    }
    notifyListeners();
    return u;
  }

  // ---- Announcements & notifications --------------------------------------
  final List<Announcement> announcements = [];
  final List<AppNotification> notifications = [];

  List<Announcement> announcementsFor(int grade) {
    final list = announcements
        .where((a) => grade == 0 || a.grade == 0 || a.grade == grade)
        .toList()
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.date.compareTo(a.date);
      });
    return list;
  }

  void postAnnouncement(Announcement a) {
    announcements.insert(0, a);
    notifyListeners();
  }

  int get unreadCount => notifications.where((n) => !n.read).length;

  void markAllRead() {
    for (final n in notifications) {
      n.read = true;
    }
    notifyListeners();
  }
}
