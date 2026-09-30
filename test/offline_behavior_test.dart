import 'package:bobadex/collection/collection_models.dart';
import 'package:bobadex/collection/collection_repository.dart';
import 'package:bobadex/pages/collection_page.dart';
import 'package:bobadex/pages/home_page.dart';
import 'package:bobadex/state/feed_state.dart';
import 'package:bobadex/state/shop_media_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/ui/theme/boba_theme_builder.dart';
import 'package:bobadex/ui/theme/boba_themes.dart';
import 'package:bobadex/widgets/social_widgets/feed_view.dart';
import 'package:bobadex/widgets/social_widgets/friends_shop_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dex shows a retry when the network is down', (tester) async {
    await tester.pumpWidget(_app(const HomePage(userId: 'offline-user')));
    await tester.pumpAndSettle();

    expect(find.text('Could not load this dex'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load this dex'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('collections show a retry when the network is down', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(CollectionPage(repository: _OfflineCounties())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load collections'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('feed shows a retry when the network is down', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => FeedState(),
        child: _app(const FeedView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load the feed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared brands show a retry when the network is down', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const FriendsShopGrid()));
    await tester.pumpAndSettle();

    expect(find.text('Could not load shared brands'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget home) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UserState()),
      ChangeNotifierProvider(create: (_) => ShopState()),
      ChangeNotifierProvider(create: (_) => ShopMediaState()),
    ],
    child: MaterialApp(
      theme: BobaThemeBuilder.build(BobaThemes.resolve(BobaThemes.defaultSlug)),
      home: home,
    ),
  );
}

class _OfflineCounties extends CollectionRepository {
  @override
  Future<List<CountySummary>> trackedCounties() async {
    throw Exception('offline');
  }

  @override
  Future<List<CountySummary>> availableCounties() async => const [];
}
