import 'dart:async';

import '../platform/plaid_platform_interface.dart';
import 'events.dart';
import 'link_configuration.dart';

/// The FinanceKit synchronization mode used by LinkKit on iOS.
enum FinanceKitSyncBehavior {
  /// Synchronize with the live FinanceKit store.
  live,

  /// Run FinanceKit synchronization with simulated data.
  simulated,
}

/// Provides Plaid Link drop in functionality.
class PlaidLink {
  /// Platform interface
  static PlaidPlatformInterface get _platform =>
      PlaidPlatformInterface.instance;

  /// A broadcast stream for [LinkEvent] from the native platform
  ///   * [name] A string representing the event that has just occurred in the Link flow.
  ///   * [metadata] An [LinkEventMetadata] object containing information about the event.
  /// For more information see https://plaid.com/docs/link/ios/#onevent
  static Stream<LinkEvent> get onEvent =>
      _platform.onObject.where((event) => event is LinkEvent).cast();

  /// A broadcast stream for [LinkSuccess] from the native platform
  ///   * [publicToken] The public token for the linked item. It is a string.
  ///   * [metadata] The additional data related to the link session and account. It is an [LinkSuccessMetadata] object.
  /// For more information see https://plaid.com/docs/link/ios/#onsuccess
  static Stream<LinkSuccess> get onSuccess =>
      _platform.onObject.where((event) => event is LinkSuccess).cast();

  /// A broadcast stream for [LinkExit] from the native platform
  ///   * [error] The error code. (can be null)
  ///   * [metadata] An [LinkExitMetadata] object containing information about the last error encountered by the user (if any), institution selected by the user, and the most recent API request ID, and the Link session ID.
  /// /// For more information see https://plaid.com/docs/link/ios/#onexit
  static Stream<LinkExit> get onExit =>
      _platform.onObject.where((event) => event is LinkExit).cast();

  /// A broadcast stream for [LinkOnLoad] from the native platform
  ///   * This event is triggered when the Plaid Link Configuration has finished loading
  static Stream<LinkOnLoad> get onLoad =>
      _platform.onObject.where((event) => event is LinkOnLoad).cast();

  /// Creates and preloads a one-time native Link session.
  ///
  /// On iOS this completes when a standard or headless session invokes
  /// LinkKit's `onLoad`. For Layer, it completes as soon as the native session
  /// is created so that data can be submitted before `LAYER_READY`.
  static Future<void> create(
      {required LinkTokenConfiguration configuration}) async {
    await _platform.create(configuration: configuration);
  }

  /// Opens the created Link session.
  ///
  /// On iOS, this presents a standard or Layer session. For a
  /// [LinkSessionType.headless] configuration, it starts the headless session
  /// instead. Android and web retain their platform-native open behavior.
  static Future<void> open() async {
    await _platform.open();
  }

  /// Closes Plaid Link View
  static Future<void> close() async {
    await _platform.close();
  }

  /// It allows the client application to submit additional user-collected data to the Link flow (e.g. a user phone number) for the Layer product.
  static Future<void> submit(SubmissionData data) async {
    await _platform.submit(data);
  }

  /// Synchronizes a previously linked Apple Card Item with FinanceKit.
  ///
  /// This is available on iOS 17.4 and later. [FinanceKitSyncBehavior.live]
  /// requires Apple's FinanceKit entitlement; calling the live API without
  /// that entitlement causes the native FinanceKit API to terminate the app.
  static Future<void> syncFinanceKit({
    required String token,
    bool requestAuthorizationIfNeeded = false,
    FinanceKitSyncBehavior behavior = FinanceKitSyncBehavior.live,
  }) async {
    await _platform.syncFinanceKit(
      token,
      requestAuthorizationIfNeeded,
      behavior == FinanceKitSyncBehavior.simulated,
    );
  }
}
