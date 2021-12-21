import 'dart:async';

import '../platform/plaid_platform_interface.dart';
import 'link_configuration.dart';
import 'types.dart';

/// Provides Plaid Link drop in functionality.
class PlaidLink {
  /// Platform interface
  static PlaidPlatformInterface get _platform => PlaidPlatformInterface.instance;

  /// Called on a successfull account link.
  ///
  /// Two arguments are returned.
  ///   * [publicToken] The public token for the linked item. It is a string.
  ///   * [metadata] The additional data related to the link session and account. It is an [SuccessMetadata] object.
  ///
  /// The [metadata] object provides the following information:
  ///
  /// [link_session_id] A unique identifier associated with a user's actions and events through the Link flow. Include this identifier when opening a support ticket for faster turnaround.
  /// [institution] An object with two properties:
  ///   * name: The full institution name, such as 'Bank of America'
  ///   * institution_id: The institution ID, such as ins_100000
  /// [accounts] A list of objects with the following properties:
  ///   * id: the id of the selected account
  ///   * name: the name of the selected account
  ///   * mask: the last 2-4 alphanumeric characters of an account's official account number. Note that the mask may be non-unique between an Item's accounts, it may also not match the mask that the bank displays to the user. This field is nullable.
  ///   * type: the account type
  ///   * subtype: the account subtype
  ///
  /// For more information: https://plaid.com/docs/#onsuccess-callback
  static void onSuccess(LinkSuccessHandler listener) => _platform.onSuccess = listener;

  /// Called when a user exits the Plaid Link flow.
  ///
  /// Two arguments are returned.
  ///   * [error] The error code. (can be null)
  ///   * [metadata] An [ExitMetadata] object containing information about the last error encountered by the user (if any), institution selected by the user, and the most recent API request ID, and the Link session ID.
  ///
  /// For more information see https://plaid.com/docs/#onexit-callback
  static void onExit(LinkExitHandler listener) => _platform.onExit = listener;

  /// Called when a Plaid Link event occurs.
  ///
  /// Two arguments are returned.
  ///   * [eventName] A string representing the event that has just occurred in the Link flow.
  ///   * [metadata] An [EventMetadata] object containing information about the event.
  ///
  /// For more information see https://plaid.com/docs/#onevent-callback
  static void onEvent(LinkEventHandler listener) => _platform.onEvent = listener;

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
