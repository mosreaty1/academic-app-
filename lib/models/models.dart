import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';

enum UserRole { student, parent, teacher }

enum AttStatus { present, absent, late, excused }

enum QType { mcq, written }

enum Difficulty { easy, medium, hard }

enum MaterialKind { pdf, video, slides, image }

enum TicketStatus { open, inProgress, resolved }

enum OrderStatus { processing, shipped, delivered }

enum BookCategory { book, notes, lab, summary }

enum PayMethod { cash, wallet, card }

enum ExamKind { quiz, monthly, midterm, finalExam }

class UserProfile {
  final String id;
  final Bi name;
  final UserRole role;
  final int grade; // 1..3 for students, 0 otherwise
  final String section;
  final Color color;
  final List<String> childIds;
  final String phone;
  const UserProfile({
    required this.id,
    required this.name,
    required this.role,
    this.grade = 0,
    this.section = '',
    this.color = AppColors.primary,
    this.childIds = const [],
    this.phone = '',
  });
}

class ClassSlot {
  final int weekday; // DateTime.weekday
  final String time; // HH:mm
  final int minutes;
  final int grade;
  final String room;
  final Bi topic;
  const ClassSlot(this.weekday, this.time, this.minutes, this.grade, this.room,
      this.topic);
}

class Question {
  final String id;
  final int grade;
  final Bi chapter;
  final QType type;
  final Bi text;
  final List<Bi> options;
  final int answer;
  final Bi explanation;
  final Bi modelAnswer;
  final Difficulty difficulty;
  final int marks;
  const Question({
    required this.id,
    required this.grade,
    required this.chapter,
    required this.type,
    required this.text,
    this.options = const [],
    this.answer = 0,
    this.explanation = const Bi('', ''),
    this.modelAnswer = const Bi('', ''),
    this.difficulty = Difficulty.medium,
    this.marks = 1,
  });
}

class Exam {
  final String id;
  final Bi title;
  final int grade;
  final ExamKind kind;
  final DateTime date;
  final int durationMin;
  final List<String> questionIds;
  Exam({
    required this.id,
    required this.title,
    required this.grade,
    required this.kind,
    required this.date,
    required this.durationMin,
    required this.questionIds,
  });
}

class ExamAttempt {
  final String examId;
  final String studentId;
  final Map<String, Object> answers; // qid -> int (mcq) | String (written)
  final int mcqScore;
  final int writtenMax;
  int writtenScore;
  bool graded;
  final int total;
  final DateTime at;
  ExamAttempt({
    required this.examId,
    required this.studentId,
    required this.answers,
    required this.mcqScore,
    required this.writtenMax,
    required this.writtenScore,
    required this.graded,
    required this.total,
    required this.at,
  });

  int get score => mcqScore + writtenScore;
  double get percent => total == 0 ? 0 : score / total;
}

class Homework {
  final String id;
  final Bi title;
  final Bi description;
  final int grade;
  final Bi chapter;
  final DateTime due;
  final int maxMarks;
  Homework({
    required this.id,
    required this.title,
    required this.description,
    required this.grade,
    required this.chapter,
    required this.due,
    this.maxMarks = 10,
  });
}

class Submission {
  final String hwId;
  final String studentId;
  String text;
  final DateTime at;
  int? mark;
  String feedback;
  Submission({
    required this.hwId,
    required this.studentId,
    required this.text,
    required this.at,
    this.mark,
    this.feedback = '',
  });
}

class StudyMaterial {
  final String id;
  final Bi title;
  final MaterialKind kind;
  final int grade;
  final Bi chapter;
  final String meta; // size or duration label
  final DateTime added;
  const StudyMaterial({
    required this.id,
    required this.title,
    required this.kind,
    required this.grade,
    required this.chapter,
    required this.meta,
    required this.added,
  });
}

class Book {
  final String id;
  final Bi title;
  final Bi subtitle;
  final BookCategory category;
  final int grade; // 0 = all
  final double price;
  final double rating;
  final Color color;
  int stock;
  Book({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.grade,
    required this.price,
    required this.rating,
    required this.color,
    required this.stock,
  });
}

class OrderLine {
  final Book book;
  final int qty;
  const OrderLine(this.book, this.qty);
}

class Order {
  final String id;
  final String buyerId;
  final List<OrderLine> lines;
  final double total;
  final DateTime at;
  final PayMethod pay;
  final String address;
  OrderStatus status;
  Order({
    required this.id,
    required this.buyerId,
    required this.lines,
    required this.total,
    required this.at,
    required this.pay,
    required this.address,
    this.status = OrderStatus.processing,
  });
}

class TicketMsg {
  final bool staff;
  final String text;
  final DateTime at;
  const TicketMsg(this.staff, this.text, this.at);
}

class Ticket {
  final String id;
  final String authorId;
  final String studentId;
  final String subject;
  final String category;
  TicketStatus status;
  final DateTime created;
  final List<TicketMsg> messages;
  Ticket({
    required this.id,
    required this.authorId,
    required this.studentId,
    required this.subject,
    required this.category,
    required this.created,
    this.status = TicketStatus.open,
    List<TicketMsg>? messages,
  }) : messages = messages ?? [];
}

class Announcement {
  final String id;
  final Bi title;
  final Bi body;
  final DateTime date;
  final int grade; // 0 = all
  final bool pinned;
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    this.grade = 0,
    this.pinned = false,
  });
}

class AppNotification {
  final String id;
  final Bi title;
  final Bi body;
  final DateTime at;
  final IconData icon;
  final Color color;
  bool read;
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.at,
    required this.icon,
    required this.color,
    this.read = false,
  });
}

// ---- Display helpers -------------------------------------------------------

Color attColor(AttStatus s) {
  switch (s) {
    case AttStatus.present:
      return AppColors.leaf;
    case AttStatus.absent:
      return AppColors.coral;
    case AttStatus.late:
      return AppColors.amber;
    case AttStatus.excused:
      return AppColors.sky;
  }
}

String attLabel(BuildContext c, AttStatus s) {
  switch (s) {
    case AttStatus.present:
      return c.tr('حاضر', 'Present');
    case AttStatus.absent:
      return c.tr('غائب', 'Absent');
    case AttStatus.late:
      return c.tr('متأخر', 'Late');
    case AttStatus.excused:
      return c.tr('بعذر', 'Excused');
  }
}

String difficultyLabel(BuildContext c, Difficulty d) {
  switch (d) {
    case Difficulty.easy:
      return c.tr('سهل', 'Easy');
    case Difficulty.medium:
      return c.tr('متوسط', 'Medium');
    case Difficulty.hard:
      return c.tr('صعب', 'Hard');
  }
}

Color difficultyColor(Difficulty d) {
  switch (d) {
    case Difficulty.easy:
      return AppColors.leaf;
    case Difficulty.medium:
      return AppColors.amber;
    case Difficulty.hard:
      return AppColors.coral;
  }
}

String examKindLabel(BuildContext c, ExamKind k) {
  switch (k) {
    case ExamKind.quiz:
      return c.tr('اختبار قصير', 'Quiz');
    case ExamKind.monthly:
      return c.tr('امتحان شهري', 'Monthly exam');
    case ExamKind.midterm:
      return c.tr('منتصف الفصل', 'Midterm');
    case ExamKind.finalExam:
      return c.tr('امتحان نهائي', 'Final exam');
  }
}

IconData materialIcon(MaterialKind k) {
  switch (k) {
    case MaterialKind.pdf:
      return Icons.picture_as_pdf_rounded;
    case MaterialKind.video:
      return Icons.play_circle_rounded;
    case MaterialKind.slides:
      return Icons.slideshow_rounded;
    case MaterialKind.image:
      return Icons.image_rounded;
  }
}

Color materialColor(MaterialKind k) {
  switch (k) {
    case MaterialKind.pdf:
      return AppColors.coral;
    case MaterialKind.video:
      return AppColors.violet;
    case MaterialKind.slides:
      return AppColors.amber;
    case MaterialKind.image:
      return AppColors.sky;
  }
}

String materialKindLabel(BuildContext c, MaterialKind k) {
  switch (k) {
    case MaterialKind.pdf:
      return c.tr('ملف PDF', 'PDF');
    case MaterialKind.video:
      return c.tr('فيديو', 'Video');
    case MaterialKind.slides:
      return c.tr('شرائح', 'Slides');
    case MaterialKind.image:
      return c.tr('صور', 'Images');
  }
}

String ticketStatusLabel(BuildContext c, TicketStatus s) {
  switch (s) {
    case TicketStatus.open:
      return c.tr('مفتوحة', 'Open');
    case TicketStatus.inProgress:
      return c.tr('قيد المعالجة', 'In progress');
    case TicketStatus.resolved:
      return c.tr('تم الحل', 'Resolved');
  }
}

Color ticketStatusColor(TicketStatus s) {
  switch (s) {
    case TicketStatus.open:
      return AppColors.amber;
    case TicketStatus.inProgress:
      return AppColors.sky;
    case TicketStatus.resolved:
      return AppColors.leaf;
  }
}

String orderStatusLabel(BuildContext c, OrderStatus s) {
  switch (s) {
    case OrderStatus.processing:
      return c.tr('قيد التجهيز', 'Processing');
    case OrderStatus.shipped:
      return c.tr('تم الشحن', 'Shipped');
    case OrderStatus.delivered:
      return c.tr('تم التسليم', 'Delivered');
  }
}

Color orderStatusColor(OrderStatus s) {
  switch (s) {
    case OrderStatus.processing:
      return AppColors.amber;
    case OrderStatus.shipped:
      return AppColors.sky;
    case OrderStatus.delivered:
      return AppColors.leaf;
  }
}

String payLabel(BuildContext c, PayMethod p) {
  switch (p) {
    case PayMethod.cash:
      return c.tr('الدفع عند الاستلام', 'Cash on delivery');
    case PayMethod.wallet:
      return c.tr('محفظة إلكترونية / فوري', 'Mobile wallet / Fawry');
    case PayMethod.card:
      return c.tr('بطاقة بنكية', 'Bank card');
  }
}

String bookCategoryLabel(BuildContext c, BookCategory k) {
  switch (k) {
    case BookCategory.book:
      return c.tr('كتب', 'Books');
    case BookCategory.notes:
      return c.tr('مذكرات', 'Notes');
    case BookCategory.lab:
      return c.tr('أدوات معمل', 'Lab kits');
    case BookCategory.summary:
      return c.tr('ملخصات', 'Summaries');
  }
}

IconData bookCategoryIcon(BookCategory k) {
  switch (k) {
    case BookCategory.book:
      return Icons.menu_book_rounded;
    case BookCategory.notes:
      return Icons.edit_note_rounded;
    case BookCategory.lab:
      return Icons.biotech_rounded;
    case BookCategory.summary:
      return Icons.style_rounded;
  }
}
