import 'dart:async';

import 'package:bobadex/brand/brand_request.dart';
import 'package:bobadex/models/city.dart';
import 'package:bobadex/ui/theme/boba_theme_builder.dart';
import 'package:bobadex/ui/theme/boba_themes.dart';
import 'package:bobadex/widgets/add_new_brand_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BrandRequestDraft _draft({
  String? address,
  String? sourceUrl,
  String name = 'Boba',
}) {
  return BrandRequestDraft(
    name: name,
    city: 'Long Beach',
    state: 'CA',
    address: address,
    sourceUrl: sourceUrl,
  );
}

BrandRequestHttp _accepted({String? resurfacedKind, String? resurfacedId}) {
  return BrandRequestHttp(
    status: 200,
    body: {
      'status': 'pending',
      'outcome': 'submitted_for_review',
      'staging_id': 'staging-1',
      'message': 'Brand pending for review',
      'resurfaced_kind': resurfacedKind,
      'resurfaced_id': resurfacedId,
    },
  );
}

void main() {
  test(
    'generic names are sent and same-name requests are not blocked',
    () async {
      final calls = <Map<String, dynamic>>[];
      final error = await submitBrandRequest(
        draft: _draft(name: 'Boba'),
        signedIn: true,
        invoke: (body) async {
          calls.add(body);
          return _accepted();
        },
      );
      expect(error, isNull);
      expect(calls.single, {
        'name': 'Boba',
        'city': 'Long Beach',
        'state': 'CA',
        'country': 'United States',
      });
      expect(calls.single.containsKey('duplicates'), isFalse);
    },
  );

  test('submits with address and one evidence url', () async {
    Map<String, dynamic>? sent;
    final error = await submitBrandRequest(
      draft: _draft(
        address: '  123 Pine Ave  ',
        sourceUrl: 'https://example.com/shop',
      ),
      signedIn: true,
      invoke: (body) async {
        sent = body;
        return _accepted(
          resurfacedKind: 'retired_location',
          resurfacedId: 'loc-1',
        );
      },
    );
    expect(error, isNull);
    expect(sent, {
      'name': 'Boba',
      'city': 'Long Beach',
      'state': 'CA',
      'country': 'United States',
      'address': '123 Pine Ave',
      'source_url': 'https://example.com/shop',
    });
  });

  test('accepted responses share one pending message', () {
    expect(brandRequestPendingMessage, 'Request submitted for review.');
    expect(
      isAcceptedBrandRequest(_accepted().body),
      isAcceptedBrandRequest(
        _accepted(
          resurfacedKind: 'rejected_submission',
          resurfacedId: 'old',
        ).body,
      ),
    );
  });

  test('auth and validation failures do not call the endpoint', () async {
    var calls = 0;
    Future<BrandRequestHttp> invoke(Map<String, dynamic> body) async {
      calls++;
      return _accepted();
    }

    expect(
      await submitBrandRequest(
        draft: _draft(),
        signedIn: false,
        invoke: invoke,
      ),
      'Please sign in to request a brand.',
    );
    expect(
      await submitBrandRequest(
        draft: _draft(sourceUrl: 'example.com'),
        signedIn: true,
        invoke: invoke,
      ),
      'Use one http or https link.',
    );
    expect(calls, 0);
  });

  test('server validation codes stay generic', () {
    expect(
      messageForBrandRequestFailure(
        const BrandRequestHttp(
          status: 400,
          body: {'error': 'invalid_source_url'},
        ),
      ),
      'Use one http or https link.',
    );
    expect(
      messageForBrandRequestFailure(
        const BrandRequestHttp(
          status: 500,
          body: {'error': 'authentication_required'},
        ),
      ),
      'Please sign in to request a brand.',
    );
    expect(
      messageForBrandRequestFailure(
        const BrandRequestHttp(
          status: 500,
          body: {'error': 'prior_manual_submission_rejected'},
        ),
      ),
      'Could not submit that request. Please try again.',
    );
  });

  testWidgets('dialog submits with and without optional evidence', (
    tester,
  ) async {
    final sent = <BrandRequestDraft>[];
    Future<void> openAndSubmit({String? address, String? url}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: BobaThemeBuilder.build(
            BobaThemes.resolve(BobaThemes.defaultSlug),
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  showDialog<String?>(
                    context: context,
                    builder: (_) => AddNewBrandDialog(
                      cities: const [City(name: 'Long Beach', state: 'CA')],
                      onSubmit: (draft) async {
                        sent.add(draft);
                        return null;
                      },
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('brand-request-name')),
        'Tea House',
      );
      await tester.enterText(
        find.byKey(const Key('brand-request-city')),
        'Long',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Long Beach, CA').last);
      await tester.pumpAndSettle();
      if (address != null) {
        await tester.enterText(
          find.byKey(const Key('brand-request-address')),
          address,
        );
      }
      if (url != null) {
        await tester.enterText(find.byKey(const Key('brand-request-url')), url);
      }
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
    }

    await openAndSubmit(
      address: '123 Pine Ave',
      url: 'https://example.com/shop',
    );
    await openAndSubmit();

    expect(sent, hasLength(2));
    expect(sent[0].address, '123 Pine Ave');
    expect(sent[0].sourceUrl, 'https://example.com/shop');
    expect(sent[0].city, 'Long Beach');
    expect(sent[0].state, 'CA');
    expect(sent[1].address, '');
    expect(sent[1].sourceUrl, '');
  });

  testWidgets('submit ignores a second tap while the request is in flight', (
    tester,
  ) async {
    final gate = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: BobaThemeBuilder.build(
          BobaThemes.resolve(BobaThemes.defaultSlug),
        ),
        home: Scaffold(
          body: AddNewBrandDialog(
            cities: const [City(name: 'Long Beach', state: 'CA')],
            onSubmit: (_) async {
              calls++;
              await gate.future;
              return null;
            },
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('brand-request-name')),
      'Tea House',
    );
    await tester.enterText(find.byKey(const Key('brand-request-city')), 'Long');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Long Beach, CA').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pump();
    expect(calls, 1);
    gate.complete();
    await tester.pumpAndSettle();
  });
}
