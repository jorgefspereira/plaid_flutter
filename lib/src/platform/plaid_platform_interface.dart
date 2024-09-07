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

  /// Creates a handler for Plaid Link. A one-time use object used to open a Link session.
  Future<void> create({required LinkTokenConfiguration configuration}) async {
    throw UnimplementedError('create() has not been implemented.');
  }

  /// Open Plaid Link by calling open on the Handler object.
  Future<void> open() async {
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

  /// It allows the client application to submit additional user-collected data to the Link flow (e.g. a user phone number) for the Layer product.
  Future<void> submit(SubmissionData data) async {
    throw UnimplementedError('submit() has not been implemented.');
  }
}
