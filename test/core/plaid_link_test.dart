import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plaid_flutter/plaid_flutter.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _MockPlaidPlatformInterface extends Mock
    with MockPlatformInterfaceMixin
    implements PlaidPlatformInterface {}

class _MockLinkEvent extends Mock implements LinkEvent {}

class _MockLinkExit extends Mock implements LinkExit {}

class _MockLinkSuccess extends Mock implements LinkSuccess {}

main() {
  group('PlaidLink', () {
    late PlaidPlatformInterface plaidPlatformInterface;

    setUp(() {
      plaidPlatformInterface = _MockPlaidPlatformInterface();
      PlaidPlatformInterface.instance = plaidPlatformInterface;
    });

    test('can be instantiated', () {
      var plaidLink = PlaidLink();
      expect(plaidLink, isNotNull);
    });

    group('onEvent', () {
      late LinkEvent linkEvent;

      setUp(() {
        linkEvent = _MockLinkEvent();
        when(() => plaidPlatformInterface.onObject).thenAnswer(
          (_) => Stream.fromIterable([linkEvent]),
        );
      });

      test('emits a LinkEvent', () async {
        await expectLater(PlaidLink.onEvent, emits(linkEvent));
      });

      test('calls platform.onObject', () {
        PlaidLink.onEvent;
        verify(() => plaidPlatformInterface.onObject).called(1);
      });
    });

    group('onExit', () {
      late LinkExit linkExitEvent;

      setUp(() {
        linkExitEvent = _MockLinkExit();
        when(() => plaidPlatformInterface.onObject).thenAnswer(
          (_) => Stream.fromIterable([linkExitEvent]),
        );
      });

      test('emits a LinkExit', () async {
        await expectLater(PlaidLink.onExit, emits(linkExitEvent));
      });

      test('calls platform.onObject', () {
        PlaidLink.onExit;

        verify(() => plaidPlatformInterface.onObject).called(1);
      });
    });

    group('onSuccess', () {
      late LinkSuccess linkSuccess;

      setUp(() {
        linkSuccess = _MockLinkSuccess();
        when(() => plaidPlatformInterface.onObject).thenAnswer(
          (_) => Stream.fromIterable([linkSuccess]),
        );
      });

      test('emits a LinkSuccess', () async {
        await expectLater(PlaidLink.onSuccess, emits(linkSuccess));
      });

      test('calls platform.onObject', () {
        PlaidLink.onSuccess;

        verify(() => plaidPlatformInterface.onObject).called(1);
      });
    });

    group('open', () {
      test('calls platform.open', () async {
        const token = 'token';
        const linkTokenConfiguration = LinkTokenConfiguration(token: token);

        when(
          () => plaidPlatformInterface.open(
            configuration: linkTokenConfiguration,
          ),
        ).thenAnswer(Future.value);

        await PlaidLink.open(configuration: linkTokenConfiguration);

        verify(
          () => plaidPlatformInterface.open(
            configuration: linkTokenConfiguration,
          ),
        ).called(1);
      });
    });

    group('close', () {
      test('calls platform.close', () async {
        when(
          () => plaidPlatformInterface.close(),
        ).thenAnswer(Future.value);

        await PlaidLink.close();

        verify(
          () => plaidPlatformInterface.close(),
        ).called(1);
      });
    });

    group('resumeAfterTermination', () {
      test('calls platform.resumeAfterTermination', () async {
        const redirectUri = 'redirectUri';

        when(
          () => plaidPlatformInterface.resumeAfterTermination(redirectUri),
        ).thenAnswer(Future.value);

        await PlaidLink.resumeAfterTermination(redirectUri);

        verify(
          () => plaidPlatformInterface.resumeAfterTermination(redirectUri),
        ).called(1);
      });
    });
  });
}
