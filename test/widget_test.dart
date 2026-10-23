import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanly_thuvien/main.dart';
import 'package:quanly_thuvien/core/api.dart';
import 'package:quanly_thuvien/screens/catalog.dart';
import 'package:quanly_thuvien/screens/circulation.dart';
import 'package:quanly_thuvien/screens/home.dart';
import 'package:quanly_thuvien/screens/reader.dart';
import 'package:quanly_thuvien/screens/experience.dart';
import 'package:quanly_thuvien/screens/admin.dart';

class FakeApi extends Api {
  FakeApi([String? role]) {
    if (role != null) {
      user = {
        'id': 1,
        'name': 'An',
        'email': 'an@mot.local',
        'phone': '',
        'role': role,
        'active': 1,
        'card_expires': '2027-10-12',
      };
    }
  }
  @override
  Future<void> restore() async {}
  @override
  Future<dynamic> call(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? data,
  }) async {
    if (path == '/me/report') {
      return {'borrowed': 0, 'returned': 0, 'overdue': 0, 'monthly': []};
    }
    if (path == '/reports') {
      return {
        'borrowed': 0,
        'overdue': 0,
        'books': 20,
        'copies': 60,
        'readers': 1,
        'available': 60,
        'pending': 0,
        'popular': [],
        'monthly': [
          {'month': '2026-08', 'count': 3},
          {'month': '2026-09', 'count': 5},
          {'month': '2026-10', 'count': 2},
        ],
      };
    }
    if (path.endsWith('/reviews')) return [];
    if (path.endsWith('/content')) {
      return {
        'text': List.filled(
          100,
          'Trăm năm trong cõi người ta,\nChữ tài chữ mệnh khéo là ghét nhau.',
        ).join('\n'),
        'credit': 'Nguyễn Du · Wikisource',
        'page': 0,
      };
    }
    if (path == '/policies') {
      return {
        'max_books': 3,
        'loan_days': 14,
        'hold_days': 2,
        'renew_days': 7,
        'max_renewals': 1,
      };
    }
    if (path == '/books') {
      return (jsonDecode(File('server/catalog.json').readAsStringSync())
              as List)
          .take(4)
          .indexed
          .map(
            (e) => {
              'id': e.$1 + 1,
              ...Map<String, dynamic>.from(e.$2),
              'isbn': '',
              'available': 3,
              'total': 3,
              'favorite': 0,
              'active': 1,
            },
          )
          .toList();
    }
    return [];
  }
}

void main() {
  setUpAll(() async {
    final serif = FontLoader('MotSerif')
      ..addFont(rootBundle.load('assets/fonts/DejaVuSerif.ttf'));
    await serif.load();
    final sans = FontLoader('MotSans')
      ..addFont(rootBundle.load('assets/fonts/DejaVuSans.ttf'));
    await sans.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  testWidgets('Splash transitions to login after four seconds', (t) async {
    await t.pumpWidget(MotApp(api: FakeApi()));
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  for (final width in [320.0, 390.0]) {
    testWidgets('Login and signup fit phone $width', (t) async {
      t.view.physicalSize = Size(width, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(MotApp(api: FakeApi(), showSplash: false));
      await t.pumpAndSettle();
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(t.takeException(), isNull);
      if (width == 390) {
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/login.png'),
        );
      }
      await t.ensureVisible(find.text('Sign Up'));
      await t.tap(find.text('Sign Up'));
      await t.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(t.takeException(), isNull);
    });
  }
  for (final role in ['reader', 'librarian', 'manager']) {
    testWidgets('$role home and all main tabs at 390px', (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(MotApp(api: FakeApi(role), showSplash: false));
      await t.pumpAndSettle();
      expect(find.byType(HomeShell), findsOneWidget);
      expect(t.takeException(), isNull);
      if (role == 'reader') {
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/home.png'),
        );
      }
      await t.tap(find.byType(NavigationDestination).at(1));
      await t.pumpAndSettle();
      expect(find.byType(Catalog), findsOneWidget);
      final catalogContext = t.element(find.byType(Catalog));
      await t.runAsync(() async {
        for (final book
            in (jsonDecode(File('server/catalog.json').readAsStringSync())
                    as List)
                .take(4)) {
          await precacheImage(AssetImage(book['cover']), catalogContext);
        }
      });
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(
        find.byTooltip('Thêm đầu sách'),
        role == 'reader' ? findsNothing : findsOneWidget,
      );
      if (role == 'reader') {
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/catalog.png'),
        );
      }
      await t.tap(find.byType(NavigationDestination).at(2));
      await t.pumpAndSettle();
      expect(find.byType(RequestsScreen), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.tap(find.byType(NavigationDestination).at(3));
      await t.pumpAndSettle();
      expect(find.byType(LoansScreen), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.tap(find.byType(NavigationDestination).at(4));
      await t.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
  testWidgets('Dark 320px enlarged type: all tabs and profile', (t) async {
    t.view.physicalSize = const Size(320, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final api = FakeApi('reader');
    api.user!['preferences'] = jsonEncode({'dark': true, 'scale': 1.3});
    await t.pumpWidget(MotApp(api: api, showSplash: false));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    for (var i = 1; i < 5; i++) {
      await t.tap(find.byType(NavigationDestination).at(i));
      await t.pumpAndSettle();
      await t.drag(find.byType(ListView).first, const Offset(0, -350));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/profile_dark.png'),
    );
  });
  testWidgets('Reader, review, settings, notifications and charts', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final api = FakeApi('manager');
    final book = {
      'id': 1,
      'title': 'Ái tình miếu',
      'author': 'Hồ Biểu Chánh',
      'cover': 'assets/images/book_01.png',
      'category': 'Văn học',
      'description': 'Giới thiệu sách.',
      'available': 3,
      'total': 3,
      'readable': 1,
      'isbn': '',
      'publisher': '',
      'active': 1,
      'favorite': 0,
      'rating': 4.5,
      'review_count': 2,
    };
    await t.pumpWidget(MotApp(api: api, showSplash: false));
    await t.pumpAndSettle();
    final context = t.element(find.byType(HomeShell));
    Future<void> visit(Widget page, String name) async {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/$name.png'),
      );
      Navigator.of(t.element(find.byType(Scaffold).last)).pop();
      await t.pumpAndSettle();
    }

    await visit(BookDetail(api: api, book: book), 'detail');
    await visit(ReaderScreen(api: api, book: book), 'reader');
    await visit(ReviewsScreen(api: api, book: book), 'reviews');
    await visit(ExperienceScreen(api: api), 'experience');
    await visit(NotificationsScreen(api: api), 'notifications');
    await visit(ReportsScreen(api: api), 'reports');
  });
}
