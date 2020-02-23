import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// The available environments to use.
enum EnvOption {
  /// For testing use,
  ///
  /// A stateful sandbox environment; use test credentials and build out and test your integration
  sandbox,

  /// For development use
  ///
  /// Test your integration with live credentials; you will need to request access before you can use Plaid's Development environment
  development,

  /// For production use only
  ///
  /// Production API environment; all requests are billed
  production
}

/// Options for specifying the Plaid products to use.
///
/// For more information visit the Plaid Products page (https://plaid.com/products/).
enum ProductOption {
  /// Verify accounts for payments without micro-deposits.
  auth,

  /// Validate income and verify employer info more accurately.
  income,

  /// Account and transaction data to better serve users.
  transactions,

  /// Verify user identities with bank account data to reduce fraud.
  identity,

  /// Historical snapshots, real-time summaries, and auditable copies.
  assets
}

typedef void AccountLinkedCallback(
    String publicToken, Map<dynamic, dynamic> metadata);

typedef void AccountLinkErrorCallback(
    String error, Map<dynamic, dynamic> metadata);

typedef void ExitCallback(Map<dynamic, dynamic> metadata);

typedef void EventCallback(String event, Map<dynamic, dynamic> metadata);

/// Provides Plaid Link drop in functionality.
class PlaidLink {
  /// Create a Plaid Link.
  ///
  /// The [publicKey], [clientName], [env], and [products] arguments are required.
  ///
  /// For more information: https://plaid.com/docs/link/ios/
  PlaidLink(
      {@required this.publicKey,
      @required this.clientName,
      @required this.env,
      this.webhook,
      this.oauthRedirectUri,
      this.oauthNonce,
      @required this.products,
      this.onAccountLinked,
      this.onAccountLinkError,
      this.onExit,
      this.onEvent})
      : _channel = MethodChannel('plugins.flutter.io/plaid_flutter') {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  /// The [MethodChannel] over which this class communicates.
  final MethodChannel _channel;

  /// Your Plaid public_key available from the Plaid dashboard (https://dashboard.plaid.com/team/keys).
  final String publicKey;

  /// Displayed to the user once they have successfully linked their account
  final String clientName;

  /// The API environment to use. Selects the Plaid servers with which LinkKit communicates.
  final EnvOption env;

  /// The webhook will receive notifications once a userʼs transactions have been processed and are ready for use.
  final String webhook;

  /// An oauthRedirectUri is required to support OAuth authentication
  final String oauthRedirectUri;

  /// An oauthNonce is required to support OAuth authentication
  final String oauthNonce;

  /// The list of Plaid products you would like to use.
  final List<ProductOption> products;

  /// Called on a successfull account link.
  ///
  /// Two arguments are returned.
  ///   * [publicToken] The public token for the linked item. It is a string.
  ///   * [metadata] The additional data related to the link session and account. It is an object.
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
  final AccountLinkedCallback onAccountLinked;

  /// Called on an unrecoverable Plaid Link error.
  ///
  /// Two arguments are returned.
  ///   * [error] The error code.
  ///   * [metadata] An object containing information about the last error encountered by the user (if any), institution selected by the user, and the most recent API request ID, and the Link session ID.
  final AccountLinkErrorCallback onAccountLinkError;

  /// Called when a user exits the Plaid Link flow.
  ///
  /// Two arguments are returned.
  ///   * [error] The error code.
  ///   * [metadata] An object containing information about the last error encountered by the user (if any), institution selected by the user, and the most recent API request ID, and the Link session ID.
  ///
  /// For more information see https://plaid.com/docs/#onexit-callback
  final ExitCallback onExit;
  //
  /// Called when a Plaid Link event occurs.
  ///
  /// Two arguments are returned.
  ///   * [eventName] A string representing the event that has just occurred in the Link flow.
  ///   * [metadata] An object containing information about the event.
  ///
  /// For more information see https://plaid.com/docs/#onevent-callback
  final EventCallback onEvent;

  /// Handles receiving messages on the [MethodChannel]
  Future<bool> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onAccountLinked':
        if (this.onAccountLinked != null) {
          this.onAccountLinked(
              call.arguments['publicToken'], call.arguments['metadata']);
        }
        return null;

      case 'onAccountLinkError':
        if (this.onAccountLinkError != null) {
          this.onAccountLinkError(
              call.arguments['error'], call.arguments['metadata']);
        }
        return null;

      case 'onExit':
        if (this.onExit != null) {
          this.onExit(call.arguments['metadata']);
        }
        return null;

      case 'onEvent':
        if (this.onEvent != null) {
          this.onEvent(call.arguments['event'], call.arguments['metadata']);
        }
        return null;
    }
    throw MissingPluginException(
        '${call.method} was invoked but has no handler');
  }

  /// Initializes the Plaid Link flow on the device.
  void open() {
    _channel.invokeMethod('open', <String, dynamic>{
      'publicKey': publicKey,
      'clientName': clientName,
      'webhook': webhook,
      'oauthRedirectUri': oauthRedirectUri,
      'oauthNonce': oauthNonce,
      'env': env.toString().split('.').last,
      'products': products.map((p) => p.toString().split('.').last).toList(),
    });
  }
}
