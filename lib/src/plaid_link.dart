import 'dart:async';
import 'package:flutter/services.dart';
import 'package:plaid_flutter/plaid_flutter.dart';
import 'metadata.dart';

typedef void SuccessCallback(String publicToken, LinkSuccessMetadata metadata);

typedef void ExitCallback(String error, LinkExitMetadata metadata);

typedef void EventCallback(String event, LinkEventMetadata metadata);

/// Provides Plaid Link drop in functionality.
class PlaidLink {
  /// Create a Plaid Link.
  ///
  /// A [publicKey] or a [linkToken] is required.
  ///
  /// For more information: https://plaid.com/docs/link/ios/
  PlaidLink({
    this.configuration,
    this.onSuccess,
    this.onExit,
    this.onEvent,
  })  : _channel = MethodChannel('plugins.flutter.io/plaid_flutter'),
        assert(configuration.publicKey != null ||
            configuration.linkToken != null) {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  /// The [MethodChannel] over which this class communicates.
  final MethodChannel _channel;

  /// A configuration to support the old Plaid flow that required a static public_key.
  ///
  /// To upgrade to the new link_token flow check the following link: https://plaid.com/docs/upgrade-to-link-tokens/
  LinkConfiguration configuration;

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
  final SuccessCallback onSuccess;

  /// Called when a user exits the Plaid Link flow.
  ///
  /// Two arguments are returned.
  ///   * [error] The error code. (can be null)
  ///   * [metadata] An [ExitMetadata] object containing information about the last error encountered by the user (if any), institution selected by the user, and the most recent API request ID, and the Link session ID.
  ///
  /// For more information see https://plaid.com/docs/#onexit-callback
  final ExitCallback onExit;
  //
  /// Called when a Plaid Link event occurs.
  ///
  /// Two arguments are returned.
  ///   * [eventName] A string representing the event that has just occurred in the Link flow.
  ///   * [metadata] An [EventMetadata] object containing information about the event.
  ///
  /// For more information see https://plaid.com/docs/#onevent-callback
  final EventCallback onEvent;

  /// Handles receiving messages on the [MethodChannel]
  Future<bool> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onSuccess':
        if (this.onSuccess != null) {
          final metadata = call.arguments['metadata'];
          final accounts = metadata["accounts"];
          List<LinkAccountMetadata> accountsMetadata = [];

          for (dynamic account in accounts) {
            final accountMetadata = LinkAccountMetadata(
              id: account["id"],
              mask: account["mask"],
              name: account["name"],
              type: account["type"],
              subtype: account["subtype"],
              verificationStatus: account["verification_status"],
            );
            accountsMetadata.add(accountMetadata);
          }

          final institution = metadata["institution"];

          final successMetadata = LinkSuccessMetadata(
            linkSessionId: metadata["link_session_id"],
            institutionName: institution != null ? institution["name"] : null,
            institutionId:
                institution != null ? institution["institution_id"] : null,
            accounts: accountsMetadata,
          );

          this.onSuccess(call.arguments['publicToken'], successMetadata);
        }
        return null;

      case 'onExit':
        if (this.onExit != null) {
          final metadata = call.arguments['metadata'];
          final institution = metadata["institution"];

          final exitMetadata = LinkExitMetadata(
            status: metadata["status"],
            requestId: metadata["request_id"],
            linkSessionId: metadata["link_session_id"],
            institutionName: institution != null ? institution["name"] : null,
            institutionId:
                institution != null ? institution["institution_id"] : null,
          );

          this.onExit(call.arguments['error'], exitMetadata);
        }
        return null;

      case 'onEvent':
        if (this.onEvent != null) {
          final metadata = call.arguments['metadata'];
          final eventMetadata = LinkEventMetadata(
            viewName: metadata["view_name"],
            exitStatus: metadata["exit_status"],
            mfaType: metadata["mfa_type"],
            requestId: metadata["request_id"],
            timestamp: metadata["timestamp"],
            linkSessionId: metadata["link_session_id"],
            institutionName: metadata["institution_name"],
            institutionId: metadata["institution_id"],
            institutionSearchQuery: metadata["institution_search_query"],
            errorType: metadata["error_type"],
            errorCode: metadata["error_code"],
            errorMesssage: metadata["error_message"],
          );

          this.onEvent(call.arguments['event'], eventMetadata);
        }
        return null;
    }
    throw MissingPluginException(
        '${call.method} was invoked but has no handler');
  }

  /// Initializes the Plaid Link flow on the device.
  void open() {
    _channel.invokeMethod(
      'open',
      <String, dynamic>{
        'linkToken': configuration.linkToken,
        'publicKey': configuration.publicKey,
        'clientName': configuration.clientName,
        'webhook': configuration.webhook,
        'oauthRedirectUri': configuration.oauthRedirectUri,
        'oauthNonce': configuration.oauthNonce,
        'env': configuration.env != null
            ? configuration.env.toString().split('.').last
            : "sandbox",
        'products': configuration.products != null
            ? configuration.products
                .map((p) => p.toString().split('.').last)
                .toList()
            : [],
        'accountSubtypes': configuration.accountSubtypes,
        'linkCustomizationName': configuration.linkCustomizationName,
        'language': configuration.language,
        'countryCodes': configuration.countryCodes,
        'userLegalName': configuration.userLegalName,
        'userEmailAddress': configuration.userEmailAddress,
        'userPhoneNumber': configuration.userPhoneNumber,
        'institution': configuration.institution,
        'paymentToken': configuration.paymentToken,
        'oauthStateId': configuration.oauthStateId,
      },
    );
  }

  // Closes Plaid Link View
  void close() {
    _channel.invokeMethod('close');
  }
}
