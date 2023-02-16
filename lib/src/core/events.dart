import 'metadata.dart';

/// Base for link events
abstract class LinkObject {
  Map<String, dynamic> toJson();
}

/// Success event object
class LinkSuccess extends LinkObject {
  /// The public token for the linked item. It is a string.
  final String publicToken;

  /// The additional data related to the link session and account. It is an [LinkSuccessMetadata] object.
  final LinkSuccessMetadata metadata;

  LinkSuccess({
    required this.publicToken,
    required this.metadata,
  });

  factory LinkSuccess.fromJson(dynamic json) {
    return LinkSuccess(
      publicToken: json["publicToken"],
      metadata: LinkSuccessMetadata.fromJson(json["metadata"]),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'publicToken': publicToken,
      'metadata': metadata.description(),
    };
  }
}

/// Exit event object
class LinkExit extends LinkObject {
  /// The error code. (can be null)
  final LinkError? error;

  ///  An [LinkExitMetadata] object containing information about the last error encountered by the user (if any), institution selected by the user, and the most recent API request ID, and the Link session ID.
  final LinkExitMetadata metadata;

  LinkExit({
    this.error,
    required this.metadata,
  });

  factory LinkExit.fromJson(dynamic json) {
    return LinkExit(
      error: json["error"] != null ? LinkError.fromJson(json["error"]) : null,
      metadata: LinkExitMetadata.fromJson(json["metadata"]),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'error': error,
      'metadata': metadata.description(),
    };
  }
}

// Contains the eventName and metadata for the Link event.
class LinkEvent extends LinkObject {
  /// A string representing the event that has just occurred in the Link flow.
  /// - bankIncomeInsightsCompleted: The user has completed the Assets and Bank Income Insights flow.
  /// - closeOAuth: The user closed the third-party website or mobile app without completing the OAuth flow.
  /// - error: A recoverable error occurred in the Link flow, see the errorCode in the `metadata.
  /// - exit: The user has exited without completing the Link flow and the onExit callback is fired.
  /// - failOAuth: The user encountered an error while completing the third-party's OAuth login flow.
  /// - handoff: The user has exited Link after successfully linking an Item.
  /// - identityVerificationStartStep: The user has started a step of the Identity Verification flow. The step is indicated by view_name.
  /// - identityVerificationPassStep: The user has passed a step of the Identity Verification flow. The step is indicated by view_name.
  /// - identityVerificationFailStep: The user has failed a step of the Identity Verification flow. The step is indicated by view_name.
  /// - identityVerificationReviewStep: The user has reached the pending review state.
  /// - identityVerificationCreateSession: The user has started a new Identity Verification session.
  /// - identityVerificationResumeSession: The user has resumed an existing Identity Verification session.
  /// - identityVerificationPassSession: The user has successfully completed their Identity Verification session.
  /// - identityVerificationFailSession: The user has failed their Identity Verification session.
  /// - identityVerificationOpenUI: The user has opened the UI of their Identity Verification session.
  /// - identityVerificationResumeUI: The user has resumed the UI of their Identity Verification session.
  /// - identityVerificationCloseUI: The user has closed the UI of their Identity Verification session.
  /// - matchedSelectInstitution: The user selected an institution that was presented as a matched institution. This event can be emitted either during the Returning User Experience flow or if the institution's routing_number was provided when calling /link/token/create. To distinguish between the two scenarios, see metadata.matchReason.
  /// - matchedSelectVerifyMethod: The user selected a verification method for a matched institution. This event is emitted only during the Returning User Experience flow.
  /// - open: The user has opened Link.
  /// - openMyPlaid: The user has opened my.plaid.com. This event is only sent when Link is initialized with Assets as a product.
  /// - openOAuth: The user has navigated to a third-party website or mobile app in order to complete the OAuth login flow.
  /// - searchInstitution: The user has searched for an institution.
  /// - selectBrand: The user selected a brand, e.g. Bank of America. The brand selection interface occurs before the institution select pane and is only provided for large financial institutions with multiple online banking portals.
  /// - selectInstitution: The user selected an institution.
  /// - submitCredentials: The user has submitted credentials.
  /// - submitMFA: The user has submitted MFA.
  /// - transitionView: The transitionView event indicates that the user has moved from one view to the next.
  /// - viewDataTypes: The user has viewed data types on the data transparency consent pane.
  /// - unknown: The event has not been defined in the current version of the SDK. The unknown case has an associated value carrying the original event name as sent by the Plaid API.
  final String name;

  /// An [LinkEventMetadata] object containing information about the event.
  final LinkEventMetadata metadata;

  LinkEvent({
    required this.name,
    required this.metadata,
  });

  factory LinkEvent.fromJson(dynamic json) {
    return LinkEvent(
      name: json["name"],
      metadata: LinkEventMetadata.fromJson(json["metadata"]),
    );
  }
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'metadata': metadata.description(),
    };
  }
}
