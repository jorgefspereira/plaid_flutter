class LinkAccountMetadata {
  /// The id of the selected account
  final String id;

  /// The last 2-4 alphanumeric characters of an account's official account number. Note that the mask may be non-unique between an Item's accounts, it may also not match the mask that the bank displays to the user. This field is nullable.
  final String mask;

  /// The name of the selected account
  final String name;

  /// The account type
  final String type;

  /// The account subtype
  final String subtype;

  /// When all Auth features are enabled, verification_status is also present with one of the possible values:
  /// - null: the Item was added through Instant Match or Instant Auth
  /// - pending_automatic_verification: an Item is pending automated microdeposit verfication
  /// - pending_manual_verification: an Item is pending manual microdeposit verification
  /// - manually_verified: an Item was successfully manually verified
  final String verificationStatus;

  LinkAccountMetadata({
    this.id,
    this.mask,
    this.name,
    this.type,
    this.subtype,
    this.verificationStatus,
  });

  String description() {
    return "[id: $id, mask: $mask, name: $name, type: $type, subtype: $subtype, verification_status: $verificationStatus]";
  }
}

/// The metadata object for the onSuccess callback
class LinkSuccessMetadata {
  /// A unique identifier associated with a user's actions and events through the Link flow. Include this identifier when opening a support ticket for faster turnaround.
  final String linkSessionId;

  /// The institution ID, such as ins_100000
  final String institutionId;

  /// The full institution name, such as 'Bank of America'
  final String institutionName;

  /// A list of account objects
  final List<LinkAccountMetadata> accounts;

  LinkSuccessMetadata({
    this.linkSessionId,
    this.institutionId,
    this.institutionName,
    this.accounts,
  });

  String description() {
    String description =
        "linkSessionId: $linkSessionId, institutionId: $institutionId, institutionName: $institutionName, accounts: ";

    for (LinkAccountMetadata a in accounts) {
      description += a.description();
    }

    return description;
  }
}

/// The metadata object for the onExit callback
class LinkExitMetadata {
  /// The value of the status key indicates the point at which the user exited the Link flow. Can be one of the following values:
  /// - requires_questions: User prompted to answer security question(s)
  /// - requires_selections: User prompted to answer multiple choice question(s)
  /// - requires_code: User prompted to provide a one-time passcode
  /// - choose_device: User prompted to select a device on which to receive a one-time passcode
  /// - requires_credentials:	User prompted to provide credentials for the selected financial institution or has not yet selected a financial institution
  /// - institution_not_found: User exited the Link flow after unsuccessfully (no results returned) searching for a financial institution
  final String status;

  /// The request ID for the last request made by Link. This can be shared with Plaid Support to expedite investigation. Emitted by: all events.
  final String requestId;

  /// A unique identifier associated with a user's actions and events through the Link flow. Include this identifier when opening a support ticket for faster turnaround.
  final String linkSessionId;

  /// The institution ID, such as ins_100000
  final String institutionId;

  /// The full institution name, such as 'Bank of America'
  final String institutionName;

  LinkExitMetadata({
    this.status,
    this.requestId,
    this.linkSessionId,
    this.institutionId,
    this.institutionName,
  });

  String description() {
    return "status: $status, linkSessionId: $linkSessionId, institutionId: $institutionId, institutionName: $institutionName, requestId: $requestId,";
  }
}

/// The metadata object for the onEvent callback
class LinkEventMetadata {
  /// The name of the view that is being transitioned to. Emitted by: TRANSITION_VIEW.
  final String viewName;

  /// The status key indicates the point at which the user exited the Link flow. Emitted by: EXIT.
  final String exitStatus;

  /// If set, the user has encountered one of the following MFA types: code, device, questions, selections. Emitted by: SUBMIT_MFA and TRANSITION_VIEW when view_name is MFA.
  final String mfaType;

  /// The request ID for the last request made by Link. This can be shared with Plaid Support to expedite investigation. Emitted by: all events.
  final String requestId;

  /// An ISO 8601 representation of when the event occurred. For example 2017-09-14T14:42:19.350Z. Emitted by: all events.
  final String timestamp;

  /// The link_session_id is a unique identifier for a single session of Link. It's always available and will stay constant throughout the flow. Emitted by: all events.
  final String linkSessionId;

  /// The name of the selected institution. Emitted by: all events.
  final String institutionName;

  /// The ID of the selected institution. Emitted by: all events.
  final String institutionId;

  /// The query used to search for institutions. Emitted by: SEARCH_INSTITUTION.
  final String institutionSearchQuery;

  /// The error type that the user encountered. Emitted by: ERROR, EXIT.
  final String errorType;

  /// The error code that the user encountered. Emitted by: ERROR, EXIT.
  final String errorCode;

  /// The error message that the user encountered. Emitted by: ERROR, EXIT.
  final String errorMesssage;

  LinkEventMetadata({
    this.viewName,
    this.exitStatus,
    this.mfaType,
    this.requestId,
    this.timestamp,
    this.linkSessionId,
    this.institutionName,
    this.institutionId,
    this.institutionSearchQuery,
    this.errorType,
    this.errorCode,
    this.errorMesssage,
  });

  String description() {
    return "viewName: $viewName, exitStatus: $exitStatus, mfaType: $mfaType, requestId: $requestId, timestamp: $timestamp, linkSessionId: $linkSessionId, institutionId: $institutionId, institutionName: $institutionName, institutionSearchQuery: $institutionSearchQuery, errorType: $errorType, errorCode: $errorCode, errorMesssage: $errorMesssage";
  }
}
