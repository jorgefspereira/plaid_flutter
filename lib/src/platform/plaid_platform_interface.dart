import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../core/events.dart';
import '../core/link_configuration.dart';
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

  /// Creates a one-time native Link session.
  Future<void> create({required LinkTokenConfiguration configuration}) async {
    throw UnimplementedError('create() has not been implemented.');
  }

  /// Opens or starts the created Link session.
  Future<void> open() async {
    throw UnimplementedError('open() has not been implemented.');
  }

  /// Closes Plaid Link View
  Future<void> close() async {
    throw UnimplementedError('close() has not been implemented.');
  }

  /// It allows the client application to submit additional user-collected data to the Link flow (e.g. a user phone number) for the Layer product.
  Future<void> submit(SubmissionData data) async {
    throw UnimplementedError('submit() has not been implemented.');
  }

  /// Sync the user's transactions from their Apple card.
  Future<void> syncFinanceKit(String token, bool requestAuthorizationIfNeeded,
      bool simulatedBehavior) async {
    throw UnimplementedError('syncFinanceKit() has not been implemented.');
  }
}
