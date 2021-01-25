import 'dart:async';
import 'package:flutter/services.dart';
import 'package:plaid_flutter/plaid_flutter.dart';
import 'metadata.dart';

typedef void SuccessCallback(String publicToken, LinkSuccessMetadata metadata);

typedef void ExitCallback(LinkError error, LinkExitMetadata metadata);

typedef void EventCallback(String eventName, LinkEventMetadata metadata);

/// Provides Plaid Link drop in functionality.
class PlaidLink {
  /// The Plaid Link object.
  PlaidLink({
    this.configuration,
    this.onSuccess,
    this.onExit,
    this.onEvent,
  })  : _channel = MethodChannel('plugins.flutter.io/plaid_flutter') {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  /// The [MethodChannel] over which this class communicates.
  final MethodChannel _channel;

  /// A configuration to support the legacy public_key Plaid flow and the the link_token process.
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
          final publicToken = call.arguments['publicToken'];

          this.onSuccess(publicToken, LinkSuccessMetadata.fromJson(metadata));
        }
        return null;

      case 'onExit':
        if (this.onExit != null) {
          final error = call.arguments['error'];
          final metadata = call.arguments['metadata'];
      
          this.onExit(LinkError.fromJson(error), LinkExitMetadata.fromJson(metadata));
        }
        return null;

      case 'onEvent':
        if (this.onEvent != null) {
          final eventName = call.arguments['event'];
          final metadata = call.arguments['metadata'];

          this.onEvent(eventName, LinkEventMetadata.fromJson(metadata));
        }
        return null;
    }
    throw MissingPluginException(
        '${call.method} was invoked but has no handler');
  }

  /// Initializes the Plaid Link flow on the device.
  void open() {
    _channel.invokeMethod('open', configuration.toJson());
  }

  // Closes Plaid Link View
  void close() {
    _channel.invokeMethod('close');
  }
}
