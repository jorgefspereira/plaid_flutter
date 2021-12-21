import 'package:flutter/services.dart';

import '../core/link_configuration.dart';
import '../core/metadata.dart';
import 'plaid_platform_interface.dart';

class PlaidMethodChannel extends PlaidPlatformInterface {
  final MethodChannel _channel = const MethodChannel('plugins.flutter.io/plaid_flutter');

  MethodChannel get channel => _channel;

  PlaidMethodChannel() {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  /// Initializes the Plaid Link flow on the device.
  Future<void> open({required LinkConfiguration configuration}) async {
    await _channel.invokeMethod('open', configuration.toJson());
  }

  /// Closes Plaid Link View
  Future<void> close() async {
    await _channel.invokeMethod('close');
  }

  /// Continue with redirect uri
  Future<void> continueWithRedirectUri(String redirectUri) async {
    await _channel.invokeMethod('continueFromRedirectUri',{"redirectUri": redirectUri});
  }
  
  /// Handles receiving messages on the [MethodChannel]
  Future<dynamic> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onSuccess':
        final metadata = call.arguments['metadata'];
        final publicToken = call.arguments['publicToken'];
        onSuccess?.call(publicToken, LinkSuccessMetadata.fromJson(metadata));
        break;

      case 'onExit':
        final error = call.arguments['error'];
        final metadata = call.arguments['metadata'];
        final linkError = error != null ? LinkError.fromJson(error) : null;
        onExit?.call(linkError, LinkExitMetadata.fromJson(metadata));
        break;

      case 'onEvent':
        final eventName = call.arguments['event'];
        final metadata = call.arguments['metadata'];
        onEvent?.call(eventName, LinkEventMetadata.fromJson(metadata));
        break;

      default:
        throw MissingPluginException(
            '${call.method} was invoked but has no handler');
    }
  }
}
