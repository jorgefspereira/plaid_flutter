import 'package:flutter/services.dart';

import '../core/events.dart';
import '../core/link_configuration.dart';
import 'plaid_platform_interface.dart';

class PlaidMethodChannel extends PlaidPlatformInterface {
  /// The method channel used to interact with the native platform.
  final MethodChannel _channel =
      const MethodChannel('plugins.flutter.io/plaid_flutter');

  /// The event channel used to receive changes from the native platform.
  final EventChannel _eventChannel =
      const EventChannel('plugins.flutter.io/plaid_flutter/events');

  /// A broadcast stream from the native platform
  Stream<LinkObject>? _onObject;

  @override
  Stream<LinkObject> get onObject {
    _onObject ??= _eventChannel.receiveBroadcastStream().map((dynamic event) {
      switch (event['type']) {
        case 'success':
          return LinkSuccess.fromJson(event);
        case 'exit':
          return LinkExit.fromJson(event);
        default:
          return LinkEvent.fromJson(event);
      }
    });

    return _onObject!;
  }

  /// Initializes the Plaid Link flow on the device.
  @override
  Future<void> open({required LinkConfiguration configuration}) async {
    await _channel.invokeMethod('open', configuration.toJson());
  }

  /// Closes Plaid Link View
  @override
  Future<void> close() async {
    await _channel.invokeMethod('close');
  }

  /// Continue with redirect uri
  @override
  Future<void> continueWithRedirectUri(String redirectUri) async {
    await _channel.invokeMethod(
      'continueFromRedirectUri',
      {"redirectUri": redirectUri},
    );
  }
}
