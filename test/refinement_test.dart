import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quanly_thuvien/core/theme.dart';
import 'package:quanly_thuvien/core/experience.dart';
import 'package:quanly_thuvien/screens/home.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanly_thuvien/screens/catalog.dart';
import 'package:quanly_thuvien/screens/circulation.dart';

import 'widget_test.dart' show FakeApi;

class CirculationApi extends FakeApi {
  CirculationApi() : super('librarian');
  @override
  Future<dynamic> call(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? data,
  }) async {
    if (path == '/notifications')
      return [
        {
          'id': -1,
          'title': 'Nhắc hạn trả sách',
          'body': 'Phiếu #1 đến hạn 2026-10-30',
          'is_read': 0,
          'created_at': '2026-10-16',
        },
        {
          'id': 1,
          'title': 'Sách đã sẵn sàng',
          'body':
              'Mời bạn đến quầy thư viện nhận sách trong thời gian giữ chỗ.',
          'is_read': 0,
          'created_at': '2026-10-16',
        },
      ];
    if (path == '/requests')
      return [
        {
          'id': 1,
          'title': 'Cha con nghĩa nặng',
          'cover': 'assets/images/book_01.png',
          'created_at': '2026-10-16',
          'name': 'Nguyễn Văn Ý',
          'email': 'reader@mot.local',
          'status': 'pending',
          'pickup_until': null,
          'note': '',
        },
      ];
    if (path == '/loans')
      return [
        {
          'id': 1,
          'title': 'Cha con nghĩa nặng',
          'cover': 'assets/images/book_01.png',
          'name': 'Nguyễn Văn Ý',
          'code': 'MOT-001',
          'status': 'borrowed',
          'overdue': 0,
          'issued_at': '2026-10-16',
          'due_at': '2026-10-30',
          'returned_at': null,
          'renewal_pending': 0,
        },
      ];
    return super.call(path, method: method, data: data);
  }
}

void main() {
  setUpAll(() async {
    for (final entry in {
      'MotSans': 'assets/fonts/DejaVuSans.ttf',
      'MotSerif': 'assets/fonts/DejaVuSerif.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
  });
  test('Vietnamese search accepts unaccented terms', () {
    expect(searchKey('  Hồ Biểu Chánh '), 'ho bieu chanh');
    expect(searchKey('ĐỌC SÁCH'), 'doc sach');
  });
  testWidgets('Home search filters in place and clears', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HomeBookSearch(api: FakeApi('reader')),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'ban khoan');
    await t.pumpAndSettle();
    expect(find.text('1 kết quả'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is ListTile &&
            w.title is Text &&
            (w.title as Text).data == 'Băn khoăn',
      ),
      findsOneWidget,
    );
    expect(find.byType(BookDetail), findsNothing);
    await t.enterText(find.byType(TextField), 'zzzz');
    await t.pump();
    expect(find.text('0 kết quả'), findsOneWidget);
    await t.tap(find.byTooltip('Xóa tìm kiếm'));
    await t.pump();
    expect(find.text('0 kết quả'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('Carousel advances and pause holds position', (t) async {
    final api = FakeApi('reader');
    final books = await api.call('/books');
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: AutoBookRail(books: books, api: api),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final list = t.widget<ListView>(find.byType(ListView));
    expect(list.controller!.offset, 0);
    await t.pump(const Duration(seconds: 4));
    await t.pump(const Duration(milliseconds: 700));
    expect(list.controller!.offset, greaterThan(0));
    await t.tap(find.text('Tạm dừng'));
    await t.pump();
    final offset = list.controller!.offset;
    await t.pump(const Duration(seconds: 5));
    expect(list.controller!.offset, offset);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('Horizontal circulation cards fit small phone', (t) async {
    t.view.physicalSize = const Size(320, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final api = CirculationApi();
    for (final page in [RequestsScreen(api: api), LoansScreen(api: api)]) {
      await t.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: motTheme(),
          builder: (c, child) =>
              OceanBackground(prefs: const {}, child: child!),
          home: Scaffold(body: page),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/refined_${page is RequestsScreen ? 'requests' : 'loans'}.png',
        ),
      );
    }
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('Notifications distinguish reminders and unread mail', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: motTheme(),
        builder: (c, child) => OceanBackground(prefs: const {}, child: child!),
        home: NotificationsScreen(api: CirculationApi()),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('1 thông báo chưa đọc'), findsOneWidget);
    expect(find.text('NHẮC HẠN TRẢ'), findsOneWidget);
    expect(t.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/refined_notifications.png'),
    );
    await t.pumpWidget(const SizedBox());
  });
}
