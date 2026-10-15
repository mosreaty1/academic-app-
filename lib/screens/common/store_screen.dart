import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  BookCategory? _cat;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final teacher = s.me!.role == UserRole.teacher;
    final grade = s.me!.role == UserRole.student
        ? s.me!.grade
        : s.me!.role == UserRole.parent
            ? null
            : null;
    final list = s.books.where((b) {
      if (_cat != null && b.category != _cat) return false;
      if (_q.isNotEmpty &&
          !(b.title.ar.contains(_q) ||
              b.title.en.toLowerCase().contains(_q.toLowerCase()))) {
        return false;
      }
      return true;
    }).toList();
    if (grade != null) {
      // Show the student's grade first.
      list.sort((a, b) {
        final ra = (a.grade == grade) ? 0 : (a.grade == 0 ? 1 : 2);
        final rb = (b.grade == grade) ? 0 : (b.grade == 0 ? 1 : 2);
        return ra.compareTo(rb);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('المتجر', 'Store')),
        actions: [
          IconButton(
            tooltip: context.tr('طلباتي', 'My orders'),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const OrdersScreen())),
            icon: const Icon(Icons.receipt_long_rounded),
          ),
          if (!teacher)
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CartScreen())),
                  icon: const Icon(Icons.shopping_bag_rounded),
                ),
                if (s.cartCount > 0)
                  PositionedDirectional(
                    end: 4,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                          color: AppColors.coral, shape: BoxShape.circle),
                      child: Text('${s.cartCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
        ],
      ),
      floatingActionButton: teacher
          ? FloatingActionButton.extended(
              onPressed: () => showSheet(context, (_) => const _AddBookForm()),
              icon: const Icon(Icons.add_rounded),
              label: Text(context.tr('منتج جديد', 'New product')),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        children: [
          TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: context.tr('ابحث عن كتاب أو مذكرة...', 'Search books & notes...'),
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          ChipSelector<BookCategory?>(
            values: [null, ...BookCategory.values],
            selected: _cat,
            label: (c) => c == null ? context.tr('الكل', 'All') : bookCategoryLabel(context, c),
            onChanged: (c) => setState(() => _cat = c),
          ),
          const SizedBox(height: 14),
          if (list.isEmpty)
            EmptyState(Icons.search_off_rounded,
                context.tr('لا توجد منتجات', 'No products found')),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.62,
            ),
            itemBuilder: (_, i) => _BookCard(book: list[i], teacher: teacher),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;
  final bool teacher;
  const _BookCard({required this.book, required this.teacher});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final inCart = context.select<AppState, int>((s) => s.cart[book.id] ?? 0);
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => showSheet(context, (_) => _BookSheet(book: book)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [book.color, book.color.withValues(alpha: 0.65)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: BioPatternPainter(Colors.white)),
                  ),
                  Center(
                    child: Icon(bookCategoryIcon(book.category),
                        color: Colors.white, size: 46),
                  ),
                  if (book.grade != 0)
                    PositionedDirectional(
                      top: 8,
                      start: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(gradeShort(context, book.grade),
                            style: TextStyle(
                                color: book.color,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title.of(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13.5, height: 1.3)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.star_rounded, color: AppColors.amber, size: 15),
                  const SizedBox(width: 2),
                  Text('${book.rating}',
                      style: TextStyle(color: context.muted, fontSize: 12)),
                  const Spacer(),
                  if (book.stock <= 10)
                    Text(context.tr('آخر ${book.stock}', 'Only ${book.stock}'),
                        style: const TextStyle(
                            color: AppColors.coral,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(
                    child: Text(money(context, book.price),
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: context.brand,
                            fontSize: 15)),
                  ),
                  if (!teacher)
                    InkWell(
                      onTap: () {
                        s.addToCart(book.id);
                        toast(context, context.tr('تمت الإضافة إلى السلة', 'Added to cart'));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                            color: inCart > 0 ? AppColors.leaf : context.cs.primary,
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(
                            inCart > 0 ? Icons.check_rounded : Icons.add_shopping_cart_rounded,
                            color: Colors.white,
                            size: 18),
                      ),
                    ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookSheet extends StatelessWidget {
  final Book book;
  const _BookSheet({required this.book});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final teacher = s.me!.role == UserRole.teacher;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 84,
            height: 108,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                  colors: [book.color, book.color.withValues(alpha: 0.6)]),
            ),
            child: Icon(bookCategoryIcon(book.category), color: Colors.white, size: 38),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title.of(context),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(book.subtitle.of(context), style: TextStyle(color: context.muted)),
                const SizedBox(height: 8),
                Text(money(context, book.price),
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700, color: context.brand)),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Wrap(spacing: 8, children: [
          Pill(bookCategoryLabel(context, book.category), book.color),
          Pill(gradeName(context, book.grade), AppColors.primary),
          Pill(context.tr('المتاح ${book.stock}', '${book.stock} in stock'),
              book.stock > 10 ? AppColors.leaf : AppColors.coral),
        ]),
        const SizedBox(height: 18),
        if (!teacher)
          FilledButton.icon(
            onPressed: book.stock == 0
                ? null
                : () {
                    s.addToCart(book.id);
                    Navigator.pop(context);
                    toast(context, context.tr('تمت الإضافة إلى السلة', 'Added to cart'));
                  },
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: Text(context.tr('أضف إلى السلة', 'Add to cart')),
          ),
      ],
    );
  }
}

class _AddBookForm extends StatefulWidget {
  const _AddBookForm();

  @override
  State<_AddBookForm> createState() => _AddBookFormState();
}

class _AddBookFormState extends State<_AddBookForm> {
  final _title = TextEditingController();
  final _sub = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController(text: '20');
  BookCategory _cat = BookCategory.notes;
  int _grade = 0;

  @override
  void dispose() {
    _title.dispose();
    _sub.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('إضافة منتج للمتجر', 'Add store product'),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        LabeledField(context.tr('الاسم', 'Name'), _title),
        LabeledField(context.tr('وصف مختصر', 'Short description'), _sub),
        Row(children: [
          Expanded(child: LabeledField(context.tr('السعر (ج.م)', 'Price (EGP)'), _price, keyboard: TextInputType.number)),
          const SizedBox(width: 12),
          Expanded(child: LabeledField(context.tr('الكمية', 'Stock'), _stock, keyboard: TextInputType.number)),
        ]),
        ChipSelector<BookCategory>(
          values: BookCategory.values,
          selected: _cat,
          label: (c) => bookCategoryLabel(context, c),
          onChanged: (c) => setState(() => _cat = c),
        ),
        const SizedBox(height: 10),
        ChipSelector<int>(
          values: const [0, 1, 2, 3],
          selected: _grade,
          label: (g) => gradeShort(context, g),
          onChanged: (g) => setState(() => _grade = g),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            final price = double.tryParse(_price.text);
            if (_title.text.trim().isEmpty || price == null) {
              toast(context, context.tr('أدخل الاسم والسعر', 'Enter name and price'));
              return;
            }
            final t = _title.text.trim();
            final d = _sub.text.trim();
            context.read<AppState>().addBook(Book(
                  id: 'b${DateTime.now().microsecondsSinceEpoch}',
                  title: Bi(t, t),
                  subtitle: Bi(d, d),
                  category: _cat,
                  grade: _grade,
                  price: price,
                  rating: 5,
                  color: AppColors.primary,
                  stock: int.tryParse(_stock.text) ?? 20,
                ));
            Navigator.pop(context);
            toast(context, context.tr('تمت إضافة المنتج', 'Product added'));
          },
          child: Text(context.tr('إضافة', 'Add')),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- cart ----

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _address = TextEditingController(text: '12 El-Tahrir St, Dokki, Giza');
  PayMethod _pay = PayMethod.cash;

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final lines = s.cart.entries
        .map((e) => (s.books.firstWhere((b) => b.id == e.key), e.value))
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('سلة المشتريات', 'Cart'))),
      body: lines.isEmpty
          ? EmptyState(Icons.shopping_bag_outlined,
              context.tr('السلة فارغة', 'Your cart is empty'),
              subtitle: context.tr('أضف كتباً ومذكرات من المتجر', 'Add books and notes from the store'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              children: [
                for (final l in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                              color: l.$1.color,
                              borderRadius: BorderRadius.circular(14)),
                          child: Icon(bookCategoryIcon(l.$1.category),
                              color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.$1.title.of(context),
                                  maxLines: 2,
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(money(context, l.$1.price * l.$2),
                                  style: TextStyle(
                                      color: context.brand, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        _Stepper(
                          qty: l.$2,
                          onMinus: () => s.decFromCart(l.$1.id),
                          onPlus: () => s.addToCart(l.$1.id),
                        ),
                      ]),
                    ),
                  ),
                SectionHeader(context.tr('عنوان التوصيل', 'Delivery address')),
                TextField(
                  controller: _address,
                  maxLines: 2,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.location_on_outlined)),
                ),
                SectionHeader(context.tr('طريقة الدفع', 'Payment method')),
                RadioGroup<PayMethod>(
                  groupValue: _pay,
                  onChanged: (v) => setState(() => _pay = v ?? PayMethod.cash),
                  child: Column(
                    children: [
                      for (final p in PayMethod.values)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AppCard(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            onTap: () => setState(() => _pay = p),
                            child: Row(children: [
                              Radio<PayMethod>(value: p),
                              Expanded(
                                  child: Text(payLabel(context, p),
                                      style: const TextStyle(fontWeight: FontWeight.w700))),
                              Icon(
                                  p == PayMethod.cash
                                      ? Icons.payments_rounded
                                      : p == PayMethod.wallet
                                          ? Icons.account_balance_wallet_rounded
                                          : Icons.credit_card_rounded,
                                  color: context.muted),
                              const SizedBox(width: 10),
                            ]),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                AppCard(
                  child: Column(children: [
                    _sumRow(context, context.tr('المجموع', 'Subtotal'), money(context, s.cartTotal)),
                    const SizedBox(height: 6),
                    _sumRow(context, context.tr('التوصيل', 'Delivery'), context.tr('مجاني', 'Free')),
                    const Divider(height: 24),
                    _sumRow(context, context.tr('الإجمالي', 'Total'), money(context, s.cartTotal), bold: true),
                  ]),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (_address.text.trim().isEmpty) {
                      toast(context, context.tr('أدخل عنوان التوصيل', 'Enter a delivery address'));
                      return;
                    }
                    final o = s.placeOrder(_pay, _address.text.trim());
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => _OrderDone(order: o)));
                  },
                  child: Text(context.tr('تأكيد الطلب', 'Place order')),
                ),
              ],
            ),
    );
  }

  Widget _sumRow(BuildContext context, String a, String b, {bool bold = false}) {
    final st = TextStyle(
        fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
        fontSize: bold ? 17 : 14);
    return Row(children: [
      Expanded(child: Text(a, style: st)),
      Text(b, style: st),
    ]);
  }
}

class _Stepper extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  const _Stepper({required this.qty, required this.onMinus, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: context.brandSoft, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onMinus,
            icon: const Icon(Icons.remove_rounded, size: 18)),
        Text('$qty', style: const TextStyle(fontWeight: FontWeight.w700)),
        IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onPlus,
            icon: const Icon(Icons.add_rounded, size: 18)),
      ]),
    );
  }
}

class _OrderDone extends StatelessWidget {
  final Order order;
  const _OrderDone({required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                    color: AppColors.leaf.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: AppColors.leaf, size: 64),
              ),
              const SizedBox(height: 24),
              Text(context.tr('تم استلام طلبك!', 'Order placed!'),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                  context.tr('رقم الطلب ${order.id} • الإجمالي ${money(context, order.total)}',
                      'Order ${order.id} • Total ${money(context, order.total)}'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.muted, height: 1.5)),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const OrdersScreen()));
                },
                child: Text(context.tr('تتبع الطلب', 'Track order')),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('العودة للمتجر', 'Back to store')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- orders ----

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final teacher = s.me!.role == UserRole.teacher;
    final orders = s.myOrders;
    return Scaffold(
      appBar: AppBar(
          title: Text(teacher
              ? context.tr('طلبات المتجر', 'Store orders')
              : context.tr('طلباتي', 'My orders'))),
      body: orders.isEmpty
          ? EmptyState(Icons.receipt_long_rounded,
              context.tr('لا توجد طلبات بعد', 'No orders yet'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              children: [
                for (final o in orders)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(o.id,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                            const Spacer(),
                            Pill(orderStatusLabel(context, o.status),
                                orderStatusColor(o.status)),
                          ]),
                          const SizedBox(height: 4),
                          Text(
                              '${fmtDateYear(context, o.at)} • ${payLabel(context, o.pay)}',
                              style: TextStyle(color: context.muted, fontSize: 12)),
                          if (teacher)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                  '${s.user(o.buyerId).name.of(context)} • ${o.address}',
                                  style: TextStyle(color: context.muted, fontSize: 12)),
                            ),
                          const Divider(height: 22),
                          for (final l in o.lines)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(children: [
                                Expanded(child: Text('${l.qty} × ${l.book.title.of(context)}')),
                                Text(money(context, l.book.price * l.qty),
                                    style: const TextStyle(fontWeight: FontWeight.w700)),
                              ]),
                            ),
                          const SizedBox(height: 8),
                          Row(children: [
                            Text(context.tr('الإجمالي', 'Total'),
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            const Spacer(),
                            Text(money(context, o.total),
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: context.brand,
                                    fontSize: 16)),
                          ]),
                          const SizedBox(height: 12),
                          _OrderTimeline(status: o.status),
                          if (teacher && o.status != OrderStatus.delivered) ...[
                            const SizedBox(height: 12),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44)),
                              onPressed: () => s.setOrderStatus(
                                  o,
                                  o.status == OrderStatus.processing
                                      ? OrderStatus.shipped
                                      : OrderStatus.delivered),
                              child: Text(o.status == OrderStatus.processing
                                  ? context.tr('تحديث إلى: تم الشحن', 'Mark as shipped')
                                  : context.tr('تحديث إلى: تم التسليم', 'Mark as delivered')),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _OrderTimeline extends StatelessWidget {
  final OrderStatus status;
  const _OrderTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    final idx = status.index;
    final labels = [
      context.tr('قيد التجهيز', 'Processing'),
      context.tr('تم الشحن', 'Shipped'),
      context.tr('تم التسليم', 'Delivered'),
    ];
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          SizedBox(
            width: 64,
            child: Column(children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: i <= idx ? AppColors.leaf : context.line,
                  shape: BoxShape.circle,
                ),
                child: i <= idx
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(labels[i],
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: context.muted)),
            ]),
          ),
          if (i < 2)
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.only(bottom: 18),
                color: i < idx ? AppColors.leaf : context.line,
              ),
            ),
        ],
      ],
    );
  }
}
