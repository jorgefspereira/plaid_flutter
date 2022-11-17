import 'dart:async';

import '../platform/plaid_platform_interface.dart';
import 'events.dart';
import 'link_configuration.dart';

/// Provides Plaid Link drop in functionality.
class PlaidLink {
  /// Platform interface
  static PlaidPlatformInterface get _platform =>
      PlaidPlatformInterface.instance;

  /// A broadcast stream from the native platform
  ///
  /// Returns one of [LinkObject] subclasses:
  ///   * [LinkSuccess]
  ///     * [publicToken] The public token for the linked item. It is a string.
  ///     * [metadata] The additional data related to the link session and account. It is an [LinkSuccessMetadata] object.
  ///
  ///   * [LinkExit]
  ///     * [error] The error code. (can be null)
  ///     * [metadata] An [LinkExitMetadata] object containing information about the last error encountered by the user (if any), institution selected by the user, and the most recent API request ID, and the Link session ID.
  ///
  ///   * [LinkEvent]
  ///     * [eventName] A string representing the event that has just occurred in the Link flow.
  ///     * [metadata] An [LinkEventMetadata] object containing information about the event.
  ///
  /// For more information see https://plaid.com/docs/link
  static Stream<LinkObject> get onEvent => _platform.onEvent;

  /// Initializes the Plaid Link flow on the device.
  static Future<void> open({required LinkConfiguration configuration}) async {
    await _platform.open(configuration: configuration);
  }

  /// Closes Plaid Link View
  static Future<void> close() async {
    await _platform.close();
  }

  /// Continue with redirect uri
  static Future<void> continueWithRedirectUri(String redirectUri) async {
    await _platform.continueWithRedirectUri(redirectUri);
  }
}
