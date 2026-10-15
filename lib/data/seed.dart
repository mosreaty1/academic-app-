import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../models/models.dart';
import 'app_state.dart';

/// Demo data for Dr. Rashia's Biology classes (Egyptian Secondary 1 / 2 / 3).
class Seed {
  static const demoStudentByGrade = {1: 's2', 2: 's1', 3: 's11'};
  static const demoPassword = '123456';

  /// Quick-fill accounts shown on the demo login screen.
  static const demoLogins = <(String, String, String)>[
    ('RB1-1001', 'طالبة أولى ثانوي', 'Student • Grade 1'),
    ('RB2-1001', 'طالب تانية ثانوي', 'Student • Grade 2'),
    ('RB3-1001', 'طالبة تالتة ثانوي', 'Student • Grade 3'),
    ('01112223344', 'ولي أمر', 'Parent'),
    ('01001234567', 'د. راشيا', 'Teacher'),
  ];

  static void populate(AppState s, {bool cloud = false}) {
    final now = DateTime.now();
    final today = dayOnly(now);

    if (!cloud) _users(s);
    _timetable(s);
    _questions(s);
    _exams(s, today);
    _attendance(s, today);
    _homework(s, today);
    _materials(s, today);
    _store(s, today);
    _tickets(s, now);
    _announcements(s, today);
    _notifications(s, now);
    _lessons(s, today);
    if (cloud) {
      // Student-linked records come from Firebase, not the demo seed.
      s.attempts.clear();
      s.submissions.clear();
      s.attendance.clear();
      s.orders.clear();
      s.tickets.clear();
    } else {
      _practice(s);
      _subscriptions(s, now);
    }
  }

  // ---------------------------------------------------------------- users --
  static void _users(AppState s) {
    final counters = <int, int>{};
    UserProfile st(String id, String ar, String en, int g, String sec,
        Color c) {
      final n = (counters[g] = (counters[g] ?? 1000) + 1);
      return UserProfile(
          id: id,
          name: Bi(ar, en),
          role: UserRole.student,
          grade: g,
          section: '$g/$sec',
          color: c,
          code: 'RB$g-$n');
    }

    s.users.addAll([
      const UserProfile(
        id: 't1',
        name: Bi('د. راشيا', 'Dr. Rashia'),
        role: UserRole.teacher,
        color: AppColors.primary,
        phone: '01001234567',
      ),
      const UserProfile(
        id: 'p1',
        name: Bi('محمود عبد الله', 'Mahmoud Abdullah'),
        role: UserRole.parent,
        color: AppColors.sky,
        childIds: ['s1', 's2'],
        phone: '01112223344',
      ),
      st('s1', 'آدم محمود', 'Adam Mahmoud', 2, 'B', AppColors.violet),
      st('s2', 'ليلى محمود', 'Laila Mahmoud', 1, 'A', AppColors.rose),
      st('s3', 'يوسف حسن', 'Youssef Hassan', 1, 'A', AppColors.sky),
      st('s4', 'مريم علي', 'Mariam Ali', 1, 'A', AppColors.amber),
      st('s5', 'عمر خالد', 'Omar Khaled', 1, 'B', AppColors.primary),
      st('s6', 'نور أحمد', 'Nour Ahmed', 1, 'B', AppColors.coral),
      st('s7', 'هدى سامي', 'Hoda Sami', 2, 'A', AppColors.rose),
      st('s8', 'كريم طارق', 'Karim Tarek', 2, 'A', AppColors.sky),
      st('s9', 'سلمى عادل', 'Salma Adel', 2, 'B', AppColors.leaf),
      st('s10', 'زياد مصطفى', 'Ziad Mostafa', 2, 'B', AppColors.amber),
      st('s11', 'جنى إبراهيم', 'Jana Ibrahim', 3, 'A', AppColors.violet),
      st('s12', 'مازن فتحي', 'Mazen Fathy', 3, 'A', AppColors.primary),
      st('s13', 'ريم هاني', 'Reem Hany', 3, 'A', AppColors.coral),
      st('s14', 'إسلام رضا', 'Eslam Reda', 3, 'B', AppColors.sky),
      st('s15', 'دينا ماجد', 'Dina Maged', 3, 'B', AppColors.rose),
    ]);
  }

  // ------------------------------------------------------------ timetable --
  static void _timetable(AppState s) {
    const sun = DateTime.sunday,
        mon = DateTime.monday,
        tue = DateTime.tuesday,
        wed = DateTime.wednesday,
        thu = DateTime.thursday;
    s.timetable.addAll(const [
      ClassSlot(sun, '09:00', 45, 1, 'Lab 1', Bi('الخلية وتركيبها', 'Cell structure')),
      ClassSlot(tue, '11:00', 45, 1, 'Hall 3', Bi('الانقسام الخلوي', 'Cell division')),
      ClassSlot(thu, '12:00', 45, 1, 'Lab 1', Bi('الأنسجة النباتية', 'Plant tissues')),
      ClassSlot(mon, '10:00', 45, 2, 'Hall 2', Bi('الجهاز الهضمي', 'Digestive system')),
      ClassSlot(wed, '09:00', 45, 2, 'Lab 2', Bi('الدورة الدموية', 'Circulation')),
      ClassSlot(thu, '09:30', 45, 2, 'Hall 2', Bi('الجهاز الدوري', 'Circulatory system')),
      ClassSlot(sun, '12:00', 45, 3, 'Hall 1', Bi('الوراثة وDNA', 'Genetics & DNA')),
      ClassSlot(tue, '09:00', 45, 3, 'Lab 3', Bi('الهرمونات', 'Hormones')),
      ClassSlot(thu, '10:30', 45, 3, 'Hall 1', Bi('المناعة', 'Immunity')),
    ]);
  }

  // ------------------------------------------------------------ questions --
  static void _questions(AppState s) {
    const g1a = Bi('تركيب الخلية', 'Cell Structure');
    const g1b = Bi('الانقسام الخلوي', 'Cell Division');
    const g1c = Bi('الأنسجة النباتية', 'Plant Tissues');
    const g2a = Bi('الهضم والامتصاص', 'Digestion & Absorption');
    const g2b = Bi('الدورة الدموية', 'Circulation');
    const g2c = Bi('التنفس والإخراج', 'Respiration & Excretion');
    const g3a = Bi('الوراثة وDNA', 'Genetics & DNA');
    const g3b = Bi('الهرمونات', 'Hormones');
    const g3c = Bi('المناعة والأعصاب', 'Immunity & Nerves');

    Question mcq(String id, int g, Bi ch, Bi text, List<Bi> opts, int ans,
            Bi expl, Difficulty d) =>
        Question(
            id: id,
            grade: g,
            chapter: ch,
            type: QType.mcq,
            text: text,
            options: opts,
            answer: ans,
            explanation: expl,
            difficulty: d,
            marks: 1);

    Question wr(String id, int g, Bi ch, Bi text, Bi model, Difficulty d,
            [int marks = 4]) =>
        Question(
            id: id,
            grade: g,
            chapter: ch,
            type: QType.written,
            text: text,
            modelAnswer: model,
            difficulty: d,
            marks: marks);

    s.questions.addAll([
      // ----- Grade 1
      mcq('q11', 1, g1a, const Bi('أي عضية تُعرف بـ"بيت الطاقة" في الخلية؟', 'Which organelle is known as the "powerhouse" of the cell?'),
          const [Bi('النواة', 'Nucleus'), Bi('الميتوكوندريا', 'Mitochondria'), Bi('الريبوسوم', 'Ribosome'), Bi('جهاز جولجي', 'Golgi body')],
          1, const Bi('الميتوكوندريا تنتج ATP عن طريق التنفس الخلوي.', 'Mitochondria produce ATP through cellular respiration.'), Difficulty.easy),
      mcq('q12', 1, g1a, const Bi('العضية المسؤولة عن البناء الضوئي هي:', 'The organelle responsible for photosynthesis is:'),
          const [Bi('الفجوة', 'Vacuole'), Bi('البلاستيدة الخضراء', 'Chloroplast'), Bi('الليسوسوم', 'Lysosome'), Bi('الجسم المركزي', 'Centriole')],
          1, const Bi('تحتوي البلاستيدات الخضراء على الكلوروفيل.', 'Chloroplasts contain chlorophyll.'), Difficulty.easy),
      mcq('q13', 1, g1a, const Bi('نموذج الفسيفساء السائل للغشاء الخلوي اقترحه:', 'The fluid mosaic model of the cell membrane was proposed by:'),
          const [Bi('روبرت هوك', 'Robert Hooke'), Bi('سينجر ونيكلسون', 'Singer & Nicolson'), Bi('شليدن', 'Schleiden'), Bi('واطسون وكريك', 'Watson & Crick')],
          1, const Bi('اقترحه سينجر ونيكلسون عام 1972.', 'Proposed by Singer and Nicolson in 1972.'), Difficulty.hard),
      mcq('q14', 1, g1b, const Bi('عدد الكروموسومات في الخلية الجسمية للإنسان:', 'Number of chromosomes in a human somatic cell:'),
          const [Bi('23', '23'), Bi('44', '44'), Bi('46', '46'), Bi('48', '48')],
          2, const Bi('الإنسان لديه 23 زوجاً أي 46 كروموسوماً.', 'Humans have 23 pairs, i.e. 46 chromosomes.'), Difficulty.easy),
      mcq('q15', 1, g1b, const Bi('في أي طور من الانقسام المتساوي تصطف الكروموسومات عند خط الاستواء؟', 'In which mitosis phase do chromosomes line up at the equator?'),
          const [Bi('التمهيدي', 'Prophase'), Bi('الاستوائي', 'Metaphase'), Bi('الانفصالي', 'Anaphase'), Bi('النهائي', 'Telophase')],
          1, const Bi('الطور الاستوائي = Metaphase.', 'Metaphase aligns chromosomes on the equatorial plate.'), Difficulty.medium),
      mcq('q16', 1, g1c, const Bi('النسيج الناقل للماء في النبات:', 'The tissue that conducts water in plants:'),
          const [Bi('اللحاء', 'Phloem'), Bi('الخشب', 'Xylem'), Bi('البرانشيمة', 'Parenchyma'), Bi('البشرة', 'Epidermis')],
          1, const Bi('الخشب ينقل الماء والأملاح المعدنية.', 'Xylem carries water and minerals.'), Difficulty.easy),
      wr('q17', 1, g1b, const Bi('قارن بين الانقسام المتساوي والاختزالي (نقطتان على الأقل).', 'Compare mitosis and meiosis (at least two points).'),
          const Bi('المتساوي: خليتان بنفس عدد الكروموسومات (2n) للنمو والتعويض. الاختزالي: أربع خلايا نصف العدد (n) لتكوين الأمشاج.', 'Mitosis: 2 daughter cells with 2n chromosomes for growth/repair. Meiosis: 4 cells with n chromosomes to form gametes.'),
          Difficulty.medium),
      wr('q18', 1, g1a, const Bi('اشرح تركيب الغشاء الخلوي.', 'Explain the structure of the cell membrane.'),
          const Bi('طبقتان من الفوسفوليبيدات تتخللهما بروتينات وكوليسترول، وهو شبه منفذ.', 'A phospholipid bilayer with embedded proteins and cholesterol; selectively permeable.'),
          Difficulty.hard),
      // ----- Grade 2
      mcq('q21', 2, g2a, const Bi('الإنزيم الذي يهضم النشا في اللعاب:', 'The enzyme in saliva that digests starch:'),
          const [Bi('البيبسين', 'Pepsin'), Bi('الليباز', 'Lipase'), Bi('الأميليز اللعابي', 'Salivary amylase'), Bi('التربسين', 'Trypsin')],
          2, const Bi('الأميليز يحول النشا إلى مالتوز.', 'Amylase converts starch into maltose.'), Difficulty.easy),
      mcq('q22', 2, g2a, const Bi('أكبر قدر من امتصاص الغذاء يحدث في:', 'Most nutrient absorption occurs in the:'),
          const [Bi('المعدة', 'Stomach'), Bi('الأمعاء الدقيقة', 'Small intestine'), Bi('الأمعاء الغليظة', 'Large intestine'), Bi('المريء', 'Oesophagus')],
          1, const Bi('الزغابات المعوية تزيد مساحة الامتصاص.', 'Villi increase the absorption surface.'), Difficulty.easy),
      mcq('q23', 2, g2b, const Bi('الحجرة التي تضخ الدم المؤكسج إلى الجسم:', 'The chamber that pumps oxygenated blood to the body:'),
          const [Bi('الأذين الأيمن', 'Right atrium'), Bi('البطين الأيمن', 'Right ventricle'), Bi('الأذين الأيسر', 'Left atrium'), Bi('البطين الأيسر', 'Left ventricle')],
          3, const Bi('البطين الأيسر جداره الأسمك ويضخ إلى الأورطي.', 'The left ventricle has the thickest wall and pumps into the aorta.'), Difficulty.medium),
      mcq('q24', 2, g2b, const Bi('خلايا الدم التي تنقل الأكسجين:', 'The blood cells that carry oxygen:'),
          const [Bi('كرات الدم الحمراء', 'Red blood cells'), Bi('كرات الدم البيضاء', 'White blood cells'), Bi('الصفائح الدموية', 'Platelets'), Bi('البلازما', 'Plasma')],
          0, const Bi('الهيموجلوبين يرتبط بالأكسجين.', 'Haemoglobin binds oxygen.'), Difficulty.easy),
      mcq('q25', 2, g2c, const Bi('الوحدة الوظيفية للكلية:', 'The functional unit of the kidney:'),
          const [Bi('العصبون', 'Neuron'), Bi('النيفرون', 'Nephron'), Bi('الحويصلة الهوائية', 'Alveolus'), Bi('الزغابة', 'Villus')],
          1, const Bi('النيفرون يرشح الدم ويكوّن البول.', 'The nephron filters blood to form urine.'), Difficulty.medium),
      mcq('q26', 2, g2c, const Bi('يحدث تبادل الغازات في الرئتين داخل:', 'Gas exchange in the lungs occurs in the:'),
          const [Bi('القصبات', 'Bronchi'), Bi('القصبة الهوائية', 'Trachea'), Bi('الحويصلات الهوائية', 'Alveoli'), Bi('البلورا', 'Pleura')],
          2, const Bi('جدار الحويصلة رقيق ومحاط بالشعيرات الدموية.', 'Alveoli have thin walls surrounded by capillaries.'), Difficulty.easy),
      wr('q27', 2, g2b, const Bi('صف مسار الدم في القلب (الدورة الرئوية والجهازية).', 'Describe the path of blood through the heart (pulmonary and systemic circulation).'),
          const Bi('الأذين الأيمن ← البطين الأيمن ← الشريان الرئوي ← الرئتين ← الأوردة الرئوية ← الأذين الأيسر ← البطين الأيسر ← الأورطي ← الجسم.', 'Right atrium → right ventricle → pulmonary artery → lungs → pulmonary veins → left atrium → left ventricle → aorta → body.'),
          Difficulty.medium),
      wr('q28', 2, g2c, const Bi('اشرح كيف يتكون البول في النيفرون.', 'Explain how urine is formed in the nephron.'),
          const Bi('ترشيح في الكبيبة، إعادة امتصاص في الأنيبيب الملتوي، ثم إفراز، فيتكوّن البول.', 'Filtration in the glomerulus, reabsorption in the tubule, then secretion, forming urine.'),
          Difficulty.hard),
      // ----- Grade 3
      mcq('q31', 3, g3a, const Bi('القاعدة النيتروجينية التي تقترن بالأدينين في DNA:', 'The nitrogenous base that pairs with adenine in DNA:'),
          const [Bi('الجوانين', 'Guanine'), Bi('السيتوزين', 'Cytosine'), Bi('الثايمين', 'Thymine'), Bi('اليوراسيل', 'Uracil')],
          2, const Bi('A-T و G-C.', 'A pairs with T, G pairs with C.'), Difficulty.easy),
      mcq('q32', 3, g3a, const Bi('الإنزيم الذي يربط شظايا DNA:', 'The enzyme that joins DNA fragments:'),
          const [Bi('هيليكيز', 'Helicase'), Bi('DNA بوليميراز', 'DNA polymerase'), Bi('DNA ليجيز', 'DNA ligase'), Bi('بريميز', 'Primase')],
          2, const Bi('الليجيز يغلق الفجوات في السكر-الفوسفات.', 'Ligase seals gaps in the sugar-phosphate backbone.'), Difficulty.hard),
      mcq('q33', 3, g3a, const Bi('نسبة الطرز الشكلية الناتجة من التزاوج Tt × Tt:', 'The phenotypic ratio from the cross Tt × Tt:'),
          const [Bi('1:1', '1:1'), Bi('3:1', '3:1'), Bi('1:2:1', '1:2:1'), Bi('9:3:3:1', '9:3:3:1')],
          1, const Bi('سيادة تامة: 3 سائد : 1 متنحي.', 'Complete dominance: 3 dominant : 1 recessive.'), Difficulty.medium),
      mcq('q34', 3, g3b, const Bi('الهرمون الذي يخفض مستوى الجلوكوز في الدم:', 'The hormone that lowers blood glucose:'),
          const [Bi('الجلوكاجون', 'Glucagon'), Bi('الإنسولين', 'Insulin'), Bi('الأدرينالين', 'Adrenaline'), Bi('الثيروكسين', 'Thyroxine')],
          1, const Bi('الإنسولين تفرزه خلايا بيتا في البنكرياس.', 'Insulin is secreted by pancreatic beta cells.'), Difficulty.easy),
      mcq('q35', 3, g3c, const Bi('الخلايا المنتجة للأجسام المضادة:', 'The cells that produce antibodies:'),
          const [Bi('كرات الدم الحمراء', 'Red blood cells'), Bi('الخلايا المتعادلة', 'Neutrophils'), Bi('الخلايا الليمفاوية B', 'B lymphocytes'), Bi('الصفائح', 'Platelets')],
          2, const Bi('الخلايا البلازمية المشتقة من B تنتج الأجسام المضادة.', 'Plasma cells derived from B cells secrete antibodies.'), Difficulty.medium),
      mcq('q36', 3, g3c, const Bi('الجزء من المخ المسؤول عن الاتزان والتوافق الحركي:', 'The brain part that controls balance and coordination:'),
          const [Bi('المخ', 'Cerebrum'), Bi('المخيخ', 'Cerebellum'), Bi('النخاع المستطيل', 'Medulla'), Bi('تحت المهاد', 'Hypothalamus')],
          1, const Bi('المخيخ ينسق الحركة والاتزان.', 'The cerebellum coordinates movement and balance.'), Difficulty.easy),
      wr('q37', 3, g3a, const Bi('اشرح خطوات تضاعف DNA.', 'Explain the steps of DNA replication.'),
          const Bi('فك الحلزون بالهيليكيز، ارتباط البريمر، بناء الشريط الجديد بالبوليميراز، ثم الربط بالليجيز؛ التضاعف شبه محافظ.', 'Helicase unwinds, primers bind, polymerase builds new strands, ligase joins; replication is semi-conservative.'),
          Difficulty.hard, 5),
      wr('q38', 3, g3c, const Bi('فرّق بين المناعة الفطرية والمكتسبة.', 'Differentiate between innate and acquired immunity.'),
          const Bi('الفطرية: موجودة منذ الولادة وغير نوعية. المكتسبة: تتكون بعد التعرض للمستضد، نوعية ولها ذاكرة.', 'Innate: present from birth, non-specific. Acquired: develops after antigen exposure, specific with memory.'),
          Difficulty.medium, 3),
    ]);
  }

  // ---------------------------------------------------------------- exams --
  static void _exams(AppState s, DateTime today) {
    s.exams.addAll([
      Exam(
          id: 'e11',
          title: const Bi('اختبار الخلية', 'Cell Quiz'),
          grade: 1,
          kind: ExamKind.quiz,
          date: today,
          durationMin: 20,
          questionIds: ['q11', 'q12', 'q14', 'q15', 'q16', 'q17']),
      Exam(
          id: 'e12',
          title: const Bi('امتحان شهري: الخلية والانقسام', 'Monthly: Cell & Division'),
          grade: 1,
          kind: ExamKind.monthly,
          date: today.add(const Duration(days: 9)),
          durationMin: 40,
          questionIds: ['q11', 'q12', 'q13', 'q14', 'q15', 'q16', 'q17', 'q18']),
      Exam(
          id: 'e21',
          title: const Bi('اختبار الجهاز الهضمي', 'Digestion Quiz'),
          grade: 2,
          kind: ExamKind.quiz,
          date: today.subtract(const Duration(days: 12)),
          durationMin: 15,
          questionIds: ['q21', 'q22', 'q25']),
      Exam(
          id: 'e22',
          title: const Bi('امتحان شهري: الدورة الدموية والتنفس', 'Monthly: Circulation & Respiration'),
          grade: 2,
          kind: ExamKind.monthly,
          date: today,
          durationMin: 30,
          questionIds: ['q23', 'q24', 'q26', 'q25', 'q27', 'q28']),
      Exam(
          id: 'e23',
          title: const Bi('اختبار منتصف الفصل', 'Midterm Exam'),
          grade: 2,
          kind: ExamKind.midterm,
          date: today.add(const Duration(days: 14)),
          durationMin: 60,
          questionIds: ['q21', 'q22', 'q23', 'q24', 'q25', 'q26', 'q27', 'q28']),
      Exam(
          id: 'e31',
          title: const Bi('امتحان الوراثة الشهري', 'Genetics Monthly'),
          grade: 3,
          kind: ExamKind.monthly,
          date: today,
          durationMin: 35,
          questionIds: ['q31', 'q32', 'q33', 'q34', 'q37', 'q38']),
      Exam(
          id: 'e32',
          title: const Bi('اختبار الهرمونات', 'Hormones Quiz'),
          grade: 3,
          kind: ExamKind.quiz,
          date: today.subtract(const Duration(days: 8)),
          durationMin: 15,
          questionIds: ['q34', 'q35', 'q36']),
    ]);

    ExamAttempt att(String ex, String sid, Map<String, Object> ans, int mcq,
        int wmax, int w, int total, DateTime at) {
      return ExamAttempt(
          examId: ex,
          studentId: sid,
          answers: ans,
          mcqScore: mcq,
          writtenMax: wmax,
          writtenScore: w,
          graded: true,
          total: total,
          at: at);
    }

    final d12 = today.subtract(const Duration(days: 12));
    final d8 = today.subtract(const Duration(days: 8));
    s.attempts.addAll([
      att('e21', 's1', {'q21': 2, 'q22': 1, 'q25': 0}, 2, 0, 0, 3, d12),
      att('e21', 's7', {'q21': 2, 'q22': 1, 'q25': 1}, 3, 0, 0, 3, d12),
      att('e21', 's8', {'q21': 0, 'q22': 1, 'q25': 1}, 2, 0, 0, 3, d12),
      att('e21', 's9', {'q21': 2, 'q22': 2, 'q25': 1}, 2, 0, 0, 3, d12),
      att('e21', 's10', {'q21': 0, 'q22': 0, 'q25': 1}, 1, 0, 0, 3, d12),
      att('e32', 's11', {'q34': 1, 'q35': 2, 'q36': 1}, 3, 0, 0, 3, d8),
      att('e32', 's12', {'q34': 1, 'q35': 0, 'q36': 1}, 2, 0, 0, 3, d8),
      att('e32', 's13', {'q34': 0, 'q35': 2, 'q36': 1}, 2, 0, 0, 3, d8),
    ]);
  }

  // ----------------------------------------------------------- attendance --
  static void _attendance(AppState s, DateTime today) {
    var idx = 0;
    for (final st in s.students) {
      idx++;
      final map = s.attendanceOf(st.id);
      var back = 1;
      var counted = 0;
      while (counted < 34) {
        final d = today.subtract(Duration(days: back));
        back++;
        // Egyptian school week: Sunday - Thursday
        if (d.weekday == DateTime.friday || d.weekday == DateTime.saturday) continue;
        counted++;
        final r = (counted * 7 + idx * 13) % 19;
        AttStatus status = AttStatus.present;
        if (r == 0) status = AttStatus.absent;
        if (r == 6 && idx % 2 == 0) status = AttStatus.late;
        if (r == 11 && idx % 3 == 0) status = AttStatus.excused;
        if (r == 3 && idx % 5 == 0) status = AttStatus.absent;
        map[dateKey(d)] = status;
      }
    }
  }

  // ------------------------------------------------------------- homework --
  static void _homework(AppState s, DateTime today) {
    s.homeworks.addAll([
      Homework(
          id: 'h11',
          title: const Bi('رسم الخلية النباتية والحيوانية', 'Draw plant & animal cells'),
          description: const Bi('ارسم الخلية النباتية والحيوانية مع كتابة البيانات وحدد ثلاثة فروق بينهما.', 'Draw plant and animal cells with labels and list three differences.'),
          grade: 1,
          chapter: const Bi('تركيب الخلية', 'Cell Structure'),
          due: today.add(const Duration(days: 2)),
          maxMarks: 10),
      Homework(
          id: 'h12',
          title: const Bi('مراحل الانقسام المتساوي', 'Phases of mitosis'),
          description: const Bi('لخص مراحل الانقسام المتساوي في جدول.', 'Summarise the phases of mitosis in a table.'),
          grade: 1,
          chapter: const Bi('الانقسام الخلوي', 'Cell Division'),
          due: today.add(const Duration(days: 5))),
      Homework(
          id: 'h21',
          title: const Bi('أسئلة على الجهاز الهضمي', 'Digestive system questions'),
          description: const Bi('أجب عن أسئلة الدرس صفحة 42 من كتاب الوزارة.', 'Answer the lesson questions on page 42 of the textbook.'),
          grade: 2,
          chapter: const Bi('الهضم والامتصاص', 'Digestion & Absorption'),
          due: today.subtract(const Duration(days: 6))),
      Homework(
          id: 'h22',
          title: const Bi('مسار الدم في القلب', 'Path of blood in the heart'),
          description: const Bi('ارسم مخطط انسياب الدم داخل القلب مع تحديد الأوعية الرئيسية.', 'Draw a flow chart of blood through the heart and label the main vessels.'),
          grade: 2,
          chapter: const Bi('الدورة الدموية', 'Circulation'),
          due: today.add(const Duration(days: 1)),
          maxMarks: 15),
      Homework(
          id: 'h23',
          title: const Bi('بحث: أمراض القلب', 'Research: Heart diseases'),
          description: const Bi('اكتب فقرة عن مرض واحد من أمراض القلب وأسبابه وطرق الوقاية.', 'Write a paragraph about one heart disease, its causes and prevention.'),
          grade: 2,
          chapter: const Bi('الدورة الدموية', 'Circulation'),
          due: today.add(const Duration(days: 7))),
      Homework(
          id: 'h31',
          title: const Bi('مسائل الوراثة', 'Genetics problems'),
          description: const Bi('حل المسائل من 1 إلى 6 على تزاوج مندل.', 'Solve problems 1-6 on Mendelian crosses.'),
          grade: 3,
          chapter: const Bi('الوراثة وDNA', 'Genetics & DNA'),
          due: today.add(const Duration(days: 3)),
          maxMarks: 20),
    ]);
    final now = DateTime.now();
    s.submissions.addAll([
      Submission(
          hwId: 'h21',
          studentId: 's1',
          text: 'تم الحل في ملف PDF مرفق.',
          at: now.subtract(const Duration(days: 7)),
          mark: 9,
          feedback: 'ممتاز يا آدم! انتبه لترتيب إنزيمات الهضم.'),
      Submission(
          hwId: 'h21',
          studentId: 's7',
          text: 'Solved.',
          at: now.subtract(const Duration(days: 6, hours: 3)),
          mark: 8,
          feedback: 'Good work.'),
      Submission(
          hwId: 'h22',
          studentId: 's8',
          text: 'Flow chart attached.',
          at: now.subtract(const Duration(hours: 5))),
      Submission(
          hwId: 'h22',
          studentId: 's9',
          text: 'Done, see picture.',
          at: now.subtract(const Duration(hours: 2))),
    ]);
  }

  // ------------------------------------------------------------ materials --
  static void _materials(AppState s, DateTime today) {
    StudyMaterial m(String id, String ar, String en, MaterialKind k, int g,
            Bi ch, String meta, int daysAgo) =>
        StudyMaterial(
            id: id,
            title: Bi(ar, en),
            kind: k,
            grade: g,
            chapter: ch,
            meta: meta,
            added: today.subtract(Duration(days: daysAgo)));
    const c1 = Bi('تركيب الخلية', 'Cell Structure');
    const c1b = Bi('الانقسام الخلوي', 'Cell Division');
    const c2a = Bi('الهضم والامتصاص', 'Digestion & Absorption');
    const c2b = Bi('الدورة الدموية', 'Circulation');
    const c3a = Bi('الوراثة وDNA', 'Genetics & DNA');
    const c3c = Bi('المناعة والأعصاب', 'Immunity & Nerves');
    s.materials.addAll([
      m('m1', 'ملخص تركيب الخلية', 'Cell structure summary', MaterialKind.pdf, 1, c1, '2.4 MB', 3),
      m('m2', 'شرح الانقسام المتساوي', 'Mitosis explained', MaterialKind.video, 1, c1b, '18 min', 6),
      m('m3', 'شرائح الأنسجة النباتية', 'Plant tissues slides', MaterialKind.slides, 1, c1, '24 slides', 10),
      m('m4', 'مذكرة الهضم', 'Digestion notes', MaterialKind.pdf, 2, c2a, '3.1 MB', 14),
      m('m5', 'شرح القلب ثلاثي الأبعاد', '3D heart walkthrough', MaterialKind.video, 2, c2b, '22 min', 2),
      m('m6', 'رسومات الدورة الدموية', 'Circulation diagrams', MaterialKind.image, 2, c2b, '12 images', 4),
      m('m7', 'حل نماذج الدورة الدموية', 'Circulation past papers', MaterialKind.pdf, 2, c2b, '1.8 MB', 1),
      m('m8', 'مراجعة الوراثة', 'Genetics revision', MaterialKind.video, 3, c3a, '35 min', 5),
      m('m9', 'مسائل مندل المحلولة', 'Solved Mendel problems', MaterialKind.pdf, 3, c3a, '2.0 MB', 9),
      m('m10', 'شرائح الجهاز المناعي', 'Immune system slides', MaterialKind.slides, 3, c3c, '30 slides', 12),
    ]);
    s.downloaded.add('m4');
    s.studied.addAll(['m4', 'm1']);
  }

  // ---------------------------------------------------------------- store --
  static void _store(AppState s, DateTime today) {
    Book b(String id, String ar, String en, String sa, String se,
            BookCategory c, int g, double price, double rate, Color col, int stock) =>
        Book(
            id: id,
            title: Bi(ar, en),
            subtitle: Bi(sa, se),
            category: c,
            grade: g,
            price: price,
            rating: rate,
            color: col,
            stock: stock);
    s.books.addAll([
      b('b1', 'مذكرة الأحياء - أولى ثانوي', 'Biology Notes - Grade 1', 'شرح كامل + أسئلة', 'Full explanation + questions', BookCategory.notes, 1, 120, 4.8, AppColors.primary, 40),
      b('b2', 'مذكرة الأحياء - تانية ثانوي', 'Biology Notes - Grade 2', 'شرح كامل + أسئلة', 'Full explanation + questions', BookCategory.notes, 2, 135, 4.9, AppColors.violet, 32),
      b('b3', 'مذكرة الأحياء - تالتة ثانوي', 'Biology Notes - Grade 3', 'المراجعة النهائية', 'Final revision edition', BookCategory.notes, 3, 160, 4.9, AppColors.coral, 25),
      b('b4', 'بنك الأسئلة - الصف الثاني', 'Question Bank - Grade 2', '1200 سؤال بنماذج الإجابة', '1200 questions with model answers', BookCategory.book, 2, 95, 4.7, AppColors.sky, 50),
      b('b5', 'بنك الأسئلة - الصف الثالث', 'Question Bank - Grade 3', 'امتحانات سنوات سابقة', 'Past papers included', BookCategory.book, 3, 110, 4.8, AppColors.amber, 44),
      b('b6', 'كروت المراجعة السريعة', 'Quick Revision Cards', '200 كارت ملون', '200 colour flash cards', BookCategory.summary, 0, 70, 4.6, AppColors.rose, 80),
      b('b7', 'أطلس جسم الإنسان', 'Human Anatomy Atlas', 'رسومات توضيحية ملونة', 'Colour illustrated plates', BookCategory.book, 0, 210, 4.9, AppColors.primaryDark, 18),
      b('b8', 'شنطة المعمل (مجهر + شرائح)', 'Lab Kit (microscope + slides)', 'للتجارب العملية', 'For practical experiments', BookCategory.lab, 0, 540, 4.5, AppColors.leaf, 9),
    ]);
    s.orders.add(Order(
      id: 'ORD-1038',
      buyerId: 'p1',
      lines: [OrderLine(s.books[1], 1), OrderLine(s.books[5], 1)],
      total: 205,
      at: today.subtract(const Duration(days: 9)),
      pay: PayMethod.cash,
      address: '12 El-Tahrir St, Dokki, Giza',
      status: OrderStatus.delivered,
    ));
    s.orders.add(Order(
      id: 'ORD-1039',
      buyerId: 'p1',
      lines: [OrderLine(s.books[3], 1)],
      total: 95,
      at: today.subtract(const Duration(days: 1)),
      pay: PayMethod.wallet,
      address: '12 El-Tahrir St, Dokki, Giza',
      status: OrderStatus.shipped,
    ));
  }

  // -------------------------------------------------------------- tickets --
  static void _tickets(AppState s, DateTime now) {
    s.tickets.addAll([
      Ticket(
        id: 'TK-198',
        authorId: 'p1',
        studentId: 's1',
        subject: 'عذر غياب - آدم',
        category: 'absence',
        created: now.subtract(const Duration(days: 5)),
        status: TicketStatus.resolved,
        messages: [
          TicketMsg(false, 'آدم كان مريضاً الأسبوع الماضي، مرفق التقرير الطبي.', now.subtract(const Duration(days: 5))),
          TicketMsg(true, 'تم قبول العذر وتسجيله. تمنياتي له بالشفاء.', now.subtract(const Duration(days: 4, hours: 20))),
        ],
      ),
      Ticket(
        id: 'TK-199',
        authorId: 's1',
        studentId: 's1',
        subject: 'سؤال عن الدرس',
        category: 'academic',
        created: now.subtract(const Duration(days: 1)),
        status: TicketStatus.inProgress,
        messages: [
          TicketMsg(false, 'ما الفرق بين الشريان الرئوي والوريد الرئوي؟', now.subtract(const Duration(days: 1))),
          TicketMsg(true, 'سأشرحها في حصة الأربعاء، وسأرفع فيديو قصيرا اليوم.', now.subtract(const Duration(hours: 18))),
        ],
      ),
    ]);
  }

  // -------------------------------------------------------- announcements --
  static void _announcements(AppState s, DateTime today) {
    s.announcements.addAll([
      Announcement(
        id: 'a1',
        title: const Bi('جدول الامتحانات الشهرية', 'Monthly exam schedule'),
        body: const Bi('تبدأ الامتحانات الشهرية الأسبوع القادم. راجعوا قسم الامتحانات لمعرفة المواعيد.', 'Monthly exams start next week. Check the Exams section for dates.'),
        date: today.subtract(const Duration(days: 1)),
        pinned: true,
      ),
      Announcement(
        id: 'a2',
        title: const Bi('حصة مراجعة للصف الثالث', 'Grade 3 revision session'),
        body: const Bi('حصة مراجعة إضافية يوم الخميس بعد الحصة في القاعة 1.', 'Extra revision session on Thursday after class in Hall 1.'),
        date: today.subtract(const Duration(days: 2)),
        grade: 3,
      ),
      Announcement(
        id: 'a3',
        title: const Bi('رحلة المتحف العلمي', 'Science museum trip'),
        body: const Bi('رحلة علمية لطلاب الصف الأول والثاني الأسبوع بعد القادم. تواصلوا معنا لتأكيد الحضور.', 'A field trip for Grades 1 and 2 in two weeks. Contact us to confirm.'),
        date: today.subtract(const Duration(days: 4)),
      ),
    ]);
  }

  static void _notifications(AppState s, DateTime now) {
    s.notifications.addAll([
      AppNotification(id: 'n1', title: const Bi('امتحان اليوم', 'Exam today'), body: const Bi('لديك امتحان اليوم، بالتوفيق!', 'You have an exam today. Good luck!'), at: now.subtract(const Duration(hours: 1)), icon: Icons.quiz_rounded, color: AppColors.violet),
      AppNotification(id: 'n2', title: const Bi('تم تصحيح واجبك', 'Homework graded'), body: const Bi('حصلت على 9/10 في واجب الجهاز الهضمي.', 'You scored 9/10 on the digestive system homework.'), at: now.subtract(const Duration(hours: 6)), icon: Icons.assignment_turned_in_rounded, color: AppColors.leaf),
      AppNotification(id: 'n3', title: const Bi('مادة جديدة', 'New material'), body: const Bi('تم رفع حل نماذج الدورة الدموية.', 'Circulation past papers were uploaded.'), at: now.subtract(const Duration(days: 1)), icon: Icons.folder_rounded, color: AppColors.sky),
      AppNotification(id: 'n4', title: const Bi('رد على تذكرتك', 'Ticket reply'), body: const Bi('ردت د. راشيا على سؤالك.', 'Dr. Rashia replied to your question.'), at: now.subtract(const Duration(days: 1, hours: 4)), icon: Icons.support_agent_rounded, color: AppColors.amber, read: true),
      AppNotification(id: 'n5', title: const Bi('تم شحن طلبك', 'Order shipped'), body: const Bi('طلبك ORD-1039 في الطريق إليك.', 'Your order ORD-1039 is on its way.'), at: now.subtract(const Duration(days: 1, hours: 8)), icon: Icons.local_shipping_rounded, color: AppColors.primary, read: true),
    ]);
  }

  static void _practice(AppState s) {
    final r = s.practice.putIfAbsent('s1', () => {});
    r.addAll({'q21': true, 'q22': true, 'q23': false, 'q24': true, 'q25': false, 'q26': true});
    final r2 = s.practice.putIfAbsent('s2', () => {});
    r2.addAll({'q11': true, 'q12': true, 'q14': false, 'q15': true});
    final r3 = s.practice.putIfAbsent('s11', () => {});
    r3.addAll({'q31': true, 'q32': false, 'q34': true, 'q35': true});
  }

  // -------------------------------------------------------------- lessons --
  static void _lessons(AppState s, DateTime today) {
    const bee =
        'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';
    const butterfly =
        'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';
    var n = 0;
    Lesson l(String ar, String en, String dAr, String dEn, int g, Bi ch,
        int min, bool premium) {
      n++;
      return Lesson(
        id: 'l$n',
        title: Bi(ar, en),
        description: Bi(dAr, dEn),
        grade: g,
        chapter: ch,
        videoUrl: n.isEven ? bee : butterfly,
        minutes: min,
        premium: premium,
        order: n,
        added: today.subtract(Duration(days: 30 - n)),
      );
    }

    const g1a = Bi('تركيب الخلية', 'Cell Structure');
    const g1b = Bi('الانقسام الخلوي', 'Cell Division');
    const g2a = Bi('الهضم والامتصاص', 'Digestion & Absorption');
    const g2b = Bi('الدورة الدموية', 'Circulation');
    const g3a = Bi('الوراثة وDNA', 'Genetics & DNA');
    const g3b = Bi('الهرمونات', 'Hormones');
    s.lessons.addAll([
      l('مقدمة: ما هي الخلية؟', 'Intro: What is a cell?', 'نظرة عامة على الخلية ومكوناتها.', 'Overview of the cell and its parts.', 1, g1a, 12, false),
      l('العضيات الخلوية', 'Cell organelles', 'الميتوكوندريا والبلاستيدات وباقي العضيات.', 'Mitochondria, chloroplasts and the rest.', 1, g1a, 28, true),
      l('الانقسام المتساوي', 'Mitosis', 'أطوار الانقسام المتساوي خطوة بخطوة.', 'The phases of mitosis step by step.', 1, g1b, 25, true),
      l('الانقسام الاختزالي', 'Meiosis', 'الفرق بين الانقسامين وتكوين الأمشاج.', 'Meiosis and gamete formation.', 1, g1b, 30, true),
      l('مقدمة: الجهاز الهضمي', 'Intro: Digestive system', 'رحلة الطعام داخل الجسم.', 'The journey of food through the body.', 2, g2a, 15, false),
      l('الإنزيمات الهاضمة', 'Digestive enzymes', 'الأميليز والبيبسين والليباز.', 'Amylase, pepsin and lipase.', 2, g2a, 26, true),
      l('القلب والأوعية الدموية', 'Heart & blood vessels', 'تركيب القلب ومسار الدم.', 'Heart structure and blood flow.', 2, g2b, 32, true),
      l('الدورة الدموية المزدوجة', 'Double circulation', 'الدورة الرئوية والجهازية.', 'Pulmonary and systemic circulation.', 2, g2b, 24, true),
      l('مقدمة: الوراثة', 'Intro: Genetics', 'قوانين مندل الأساسية.', 'Mendel\'s basic laws.', 3, g3a, 14, false),
      l('تركيب DNA وتضاعفه', 'DNA structure & replication', 'من الحلزون المزدوج إلى التضاعف.', 'From the double helix to replication.', 3, g3a, 38, true),
      l('هرمونات البنكرياس', 'Pancreatic hormones', 'الإنسولين والجلوكاجون.', 'Insulin and glucagon.', 3, g3b, 22, true),
    ]);
  }

  static void _subscriptions(AppState s, DateTime now) {
    // Adam (s1): active for ~20 more days. Jana (s11): expired last week.
    s.subscriptions.addAll([
      Subscription(
          studentId: 's1',
          planId: 'monthly',
          start: now.subtract(const Duration(days: 10)),
          end: now.add(const Duration(days: 20)),
          source: SubSource.payment),
      Subscription(
          studentId: 's11',
          planId: 'monthly',
          start: now.subtract(const Duration(days: 37)),
          end: now.subtract(const Duration(days: 7)),
          source: SubSource.code),
    ]);
    s.codes.addAll([
      ActivationCode(code: 'BIO1-TERM', planId: 'term', grade: 1, created: now.subtract(const Duration(days: 3))),
      ActivationCode(code: 'BIO2-MNTH', planId: 'monthly', grade: 2, created: now.subtract(const Duration(days: 3))),
      ActivationCode(code: 'BIO3-YEAR', planId: 'year', grade: 3, created: now.subtract(const Duration(days: 3))),
      ActivationCode(code: 'USED-0001', planId: 'monthly', grade: 3, created: now.subtract(const Duration(days: 40)), usedBy: 's11', usedAt: now.subtract(const Duration(days: 37))),
    ]);
  }
}
