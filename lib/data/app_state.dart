import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../models/models.dart';
import 'seed.dart';

/// Single source of truth for the demo app.
///
/// All data is held in memory and seeded from [Seed]. To connect a real
/// backend (Firebase / REST), replace the mutating methods below with API calls
/// and keep the same getters - the UI only talks to this class.
class AppState extends ChangeNotifier {
  AppState();

  factory AppState.seeded() {
    final s = AppState();
    Seed.populate(s);
    return s;
  }

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
    notifyListeners();
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
