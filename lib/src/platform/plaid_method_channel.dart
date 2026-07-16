import 'dart:io';

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
        case 'onload':
          return LinkOnLoad.fromJson(event);
        default:
          return LinkEvent.fromJson(event);
      }
    });

    return _onObject!;
  }

  /// Creates a one-time native Link session.
  @override
  Future<void> create({required LinkTokenConfiguration configuration}) async {
    await _channel.invokeMethod('create', configuration.toJson());
  }

  /// Opens or starts the created Link session.
  @override
  Future<void> open() async {
    await _channel.invokeMethod('open');
  }

  /// Closes Plaid Link View
  @override
  Future<void> close() async {
    await _channel.invokeMethod('close');
  }

  /// It allows the client application to submit additional user-collected data to the Link flow (e.g. a user phone number) for the Layer product.
  @override
  Future<void> submit(SubmissionData data) async {
    await _channel.invokeMethod('submit', data.toJson());
  }

  /// It allows the client application to submit additional user-collected data to the Link flow (e.g. a user phone number) for the Layer product.
  @override
  Future<void> syncFinanceKit(String token, bool requestAuthorizationIfNeeded,
      bool simulatedBehavior) async {
    if (Platform.isIOS) {
      await _channel.invokeMethod(
        'syncFinanceKit',
        {
          "token": token,
          "requestAuthorizationIfNeeded": requestAuthorizationIfNeeded,
          "simulatedBehavior": simulatedBehavior,
        },
      );
    } else {
      throw UnimplementedError('syncFinanceKit is only implemented for iOS.');
    }
  }
}
