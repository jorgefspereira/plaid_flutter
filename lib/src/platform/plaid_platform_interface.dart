import 'package:plaid_flutter/plaid_flutter.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'plaid_method_channel.dart';

abstract class PlaidPlatformInterface extends PlatformInterface {
  /// Contructor
  PlaidPlatformInterface() : super(token: _token);

  /// Token
  static final Object _token = Object();

  /// Singleton instance
  static PlaidPlatformInterface _instance = PlaidMethodChannel();

  /// Default instance to use.
  static PlaidPlatformInterface get instance => _instance;

  static set instance(PlaidPlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// A broadcast stream from the native platform
  Stream<LinkObject> get onObject {
    throw UnimplementedError('onObject has not been implemented.');
  }

  /// Initializes the Plaid Link flow on the device.
  Future<void> open({required LinkTokenConfiguration configuration}) async {
    throw UnimplementedError('open() has not been implemented.');
  }

  /// Closes Plaid Link View
  Future<void> close() async {
    throw UnimplementedError('close() has not been implemented.');
  }

  /// Resume after termination
  Future<void> resumeAfterTermination(String redirectUri) async {
    throw UnimplementedError(
        'resumeAfterTermination() has not been implemented.');
  }
}
