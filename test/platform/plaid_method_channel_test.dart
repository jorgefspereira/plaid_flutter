import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaid_flutter/plaid_flutter.dart';
import 'package:plaid_flutter/src/platform/plaid_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/plaid_flutter');
  late MethodCall? receivedCall;

  setUp(() {
    receivedCall = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      receivedCall = call;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('create sends the LinkKit 7 session type over the method channel',
      () async {
    const configuration = LinkTokenConfiguration(
      token: 'layer-token',
      showGradientBackground: true,
      sessionType: LinkSessionType.layer,
    );

    await PlaidMethodChannel().create(configuration: configuration);

    expect(receivedCall?.method, 'create');
    expect(receivedCall?.arguments, configuration.toJson());
    expect(
      (receivedCall?.arguments as Map<Object?, Object?>)['sessionType'],
      'layer',
    );
  });
}
