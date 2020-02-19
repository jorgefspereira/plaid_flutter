import 'dart:async';
import 'package:flutter/services.dart';

//
// The available environments to use.
enum EnvOption {
  //
  // For testing use,
  sandbox,
  //
  // For development use
  development,
  //
  // For production use only
  production
}
//
// Options for specifying the Plaid products to use.
enum ProductOption {
  //
  // Verify accounts for payments without micro-deposits.
  auth,
  //
  // Validate income and verify employer info more accurately.
  income,
  //
  // Account and transaction data to better serve users.
  transactions,
  //
  // Verify user identities with bank account data to reduce fraud.
  identity,
  //
  // Historical snapshots, real-time summaries, and auditable copies.
  assets
}

typedef void AccountLinkedCallback(String publicToken, Map<dynamic, dynamic> metadata);

typedef void AccountLinkErrorCallback(String error, Map<dynamic, dynamic> metadata);

typedef void ExitCallback(Map<dynamic, dynamic> metadata);

typedef void EventCallback(String event, Map<dynamic, dynamic> metadata);

class PlaidLink {
  PlaidLink(
      {this.publicKey,
      this.clientName,
      this.env,
      this.webhook,
      this.oauthRedirectUri,
      this.oauthNonce,
      this.products,
      this.onAccountLinked,
      this.onAccountLinkError,
      this.onExit,
      this.onEvent})
      : _channel = MethodChannel('plugins.flutter.io/plaid_flutter') {
    _channel.setMethodCallHandler(_onMethodCall);
  }
  //
  // The [MethodChannel] over which this class communicates.
  final MethodChannel _channel;
  //
  // Your Plaid public_key available from the Plaid dashboard
  final String publicKey;
  //
  // Displayed to the user once they have successfully linked their account
  final String clientName;
  //
  // The API environment selects the Plaid servers with which LinkKit communicates.
  final EnvOption env;
  //
  // The webhook will receive notifications once a userʼs transactions have been processed and are ready for use.
  final String webhook;
  //
  // An oauthRedirectUri is required to support OAuth authentication
  final String oauthRedirectUri;
  //
  // An oauthNonce is required to support OAuth authentication 
  final String oauthNonce;
  //
  // List of Plaid products you would like to use.
  final List<ProductOption> products;
  //
  //
  final AccountLinkedCallback onAccountLinked;
  //
  //
  final AccountLinkErrorCallback onAccountLinkError;
  //
  //
  final ExitCallback onExit;
  //
  //
  final EventCallback onEvent;
  //
  //
  Future<bool> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onAccountLinked':
        if (this.onAccountLinked != null) {
          this.onAccountLinked(call.arguments['publicToken'], call.arguments['metadata']);
        }
        return null;

      case 'onAccountLinkError':
        if (this.onAccountLinkError != null) {
          this.onAccountLinkError(call.arguments['error'], call.arguments['metadata']);
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
    throw MissingPluginException('${call.method} was invoked but has no handler');
  }

  //
  //
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
