import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanly_thuvien/main.dart';
import 'package:quanly_thuvien/widgets/common.dart';
import 'package:quanly_thuvien/core/api.dart';
import 'package:quanly_thuvien/screens/catalog.dart';
import 'package:quanly_thuvien/screens/circulation.dart';
import 'package:quanly_thuvien/screens/home.dart';

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
    if (path == '/requests') {
      return [
        {
          'id': 1,
          'title': 'Ái tình miếu',
          'cover': 'assets/images/book_01.png',
          'name': 'Bạn đọc MỌT',
          'email': 'reader@mot.local',
          'status': 'pending',
          'note': '',
          'created_at': '2026-10-15',
          'pickup_until': null,
        },
      ];
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
        'monthly': [],
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

class CountingApi extends FakeApi {
  int calls = 0;
  @override
  Future<dynamic> call(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? data,
  }) async => ++calls;
}

void main() {
  testWidgets(
    'DataView reload updates data without returning Future from setState',
    (t) async {
      final api = CountingApi();
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DataView(
              api: api,
              path: '/example',
              builder: (c, data, reload) =>
                  TextButton(onPressed: reload, child: Text('Tải $data')),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Tải 1'), findsOneWidget);
      await t.tap(find.text('Tải 1'));
      await t.pumpAndSettle();
      expect(find.text('Tải 2'), findsOneWidget);
      expect(api.calls, 2);
      expect(t.takeException(), isNull);
    },
  );

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
  for (final width in [320.0, 390.0]) {
    for (final role in ['reader', 'librarian', 'manager']) {
      testWidgets('$role home and all main tabs at ${width}px', (t) async {
        t.view.physicalSize = Size(width, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        await t.pumpWidget(MotApp(api: FakeApi(role), showSplash: false));
        await t.pumpAndSettle();
        expect(find.byType(HomeShell), findsOneWidget);
        expect(t.takeException(), isNull);
        if (role == 'reader' && width == 390) {
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
        if (role == 'reader' && width == 390) {
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/catalog.png'),
          );
        }
        await t.tap(find.byType(NavigationDestination).at(2));
        await t.pumpAndSettle();
        expect(find.byType(RequestsScreen), findsOneWidget);
        if (role == 'librarian' && width == 390) {
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/requests.png'),
          );
        }
        expect(t.takeException(), isNull);
        await t.tap(find.byType(NavigationDestination).at(3));
        await t.pumpAndSettle();
        expect(find.byType(LoansScreen), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.tap(find.byType(NavigationDestination).at(4));
        await t.pumpAndSettle();
        expect(find.byType(ProfileScreen), findsOneWidget);
        if (role == 'reader' && width == 390) {
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/profile.png'),
          );
        }
        expect(t.takeException(), isNull);
      });
    }
  }
}
