/// The error object
class LinkError {
  /// The error code that the user encountered.
  /// Each errorCode has an associated errorType, which is a broad categorization of the error.
  final String code;

  /// The error type that the user encountered.
  final String type;

  /// A developer-friendly representation of the error code.
  final String message;

  /// A user-friendly representation of the error code or nil if the error is not related to user action.
  /// This may change over time and is not safe for programmatic use.
  final String displayMessage;

  LinkError({
    this.code,
    this.type,
    this.message,
    this.displayMessage,
  });

  factory LinkError.fromJson(dynamic json) {
    return LinkError(
      code: json["errorCode"],
      type: json["errorType"],
      message: json["errorMessage"],
      displayMessage: json["errorDisplayMessage"],
    );
  }

  String description() {
    return "[code: $code, type: $type, message: $message, displayMessage: $displayMessage]";
  }
}

/// The institution object
class LinkInstitution {
  /// The Plaid institution identifier
  final String id;

  /// The full institution name, such as 'Bank of America'
  final String name;

  LinkInstitution({
    this.id,
    this.name,
  });

  factory LinkInstitution.fromJson(dynamic json) {
    return LinkInstitution(
      id: json["id"],
      name: json["name"],
    );
  }

  String description() {
    return "id: $id, name: $name";
  }
}

/// The account object
class LinkAccount {
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

  /// When micro-deposit-based verification is being used, the accounts object includes an Item's verification_status. Possible values are:
  /// - pending_automatic_verification: The Item is pending automatic verification.
  /// - pending_manual_verification: The Item is pending manual micro-deposit verification. Items remain in this state until the user successfully verifies the two amounts.
  /// - automatically_verified: The Item has successfully been automatically verified.
  /// - manually_verified: The Item has successfully been manually verified.
  /// - verification_expired: Plaid was unable to automatically verify the deposit within 7 calendar days and will no longer attempt to validate the Item. Users may retry by submitting their information again through Link.
  /// - verification_failed: The Item failed manual micro-deposit verification because the user exhausted all 3 verification attempts. Users may retry by submitting their information again through Link.
  final String verificationStatus;

  LinkAccount({
    this.id,
    this.mask,
    this.name,
    this.type,
    this.subtype,
    this.verificationStatus,
  });

  factory LinkAccount.fromJson(dynamic json) {
    return LinkAccount(
      id: json["id"],
      name: json["name"],
      mask: json["mask"],
      type: json["type"],
      subtype: json["subtype"],
      verificationStatus: json["verificationStatus"],
    );
  }

  String description() {
    return "[id: $id, mask: $mask, name: $name, type: $type, subtype: $subtype, verification_status: $verificationStatus]";
  }
}

/// The metadata object for the onSuccess callback
class LinkSuccessMetadata {
  /// A unique identifier associated with a user's actions and events through the Link flow. Include this identifier when opening a support ticket for faster turnaround.
  final String linkSessionId;

  /// An institution object
  final LinkInstitution institution;

  /// A list of accounts attached to the connected Item
  final List<LinkAccount> accounts;

  LinkSuccessMetadata({
    this.linkSessionId,
    this.institution,
    this.accounts,
  });

  factory LinkSuccessMetadata.fromJson(dynamic json) {
    List<LinkAccount> accountsArray = [];

    for (dynamic accountInfo in json["accounts"]) {
      accountsArray.add(LinkAccount.fromJson(accountInfo));
    }

    return LinkSuccessMetadata(
      linkSessionId: json["linkSessionId"],
      institution: LinkInstitution.fromJson(json["institution"]),
      accounts: accountsArray,
    );
  }

  String description() {
    String description =
        "linkSessionId: $linkSessionId, institution.id: ${institution.id}, institution.name: ${institution.name}, accounts: ";

    for (LinkAccount a in accounts) {
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
  /// - unknown: The exit status has not been defined in the current version of the SDK. The unknown case has an associated value carrying the original exit status as sent by the Plaid API.
  final String status;

  /// The request ID for the last request made by Link. This can be shared with Plaid Support to expedite investigation.
  final String requestId;

  /// A unique identifier associated with a user's actions and events through the Link flow. Include this identifier when opening a support ticket for faster turnaround.
  final String linkSessionId;

  /// An institution object
  final LinkInstitution institution;

  LinkExitMetadata({
    this.status,
    this.requestId,
    this.linkSessionId,
    this.institution,
  });

  factory LinkExitMetadata.fromJson(dynamic json) {
    return LinkExitMetadata(
      status: json["status"],
      requestId: json["requestId"],
      linkSessionId: json["linkSessionId"],
      institution: LinkInstitution.fromJson(json["institution"]),
    );
  }

  String description() {
    return "status: $status, linkSessionId: $linkSessionId, requestId: $requestId, institution.id: ${institution.id}, institution.name: ${institution.name}";
  }
}

/// The metadata object for the onEvent callback
class LinkEventMetadata {
  /// The error code that the user encountered. Emitted by: ERROR, EXIT.
  final String errorCode;

  /// The error message that the user encountered. Emitted by: ERROR, EXIT.
  final String errorMesssage;

  /// The error type that the user encountered. Emitted by: ERROR, EXIT.
  final String errorType;

  /// The status key indicates the point at which the user exited the Link flow. Emitted by: EXIT.
  final String exitStatus;

  /// The ID of the selected institution. Emitted by: all events.
  final String institutionId;

  /// The name of the selected institution. Emitted by: all events.
  final String institutionName;

  /// The query used to search for institutions. Emitted by: SEARCH_INSTITUTION.
  final String institutionSearchQuery;

  /// The link_session_id is a unique identifier for a single session of Link. It's always available and will stay constant throughout the flow. Emitted by: all events.
  final String linkSessionId;

  /// If set, the user has encountered one of the following MFA types: code, device, questions, selections. Emitted by: SUBMIT_MFA and TRANSITION_VIEW when view_name is MFA.
  final String mfaType;

  /// The request ID for the last request made by Link. This can be shared with Plaid Support to expedite investigation. Emitted by: all events.
  final String requestId;

  /// An ISO 8601 representation of when the event occurred. For example 2017-09-14T14:42:19.350Z. Emitted by: all events.
  final String timestamp;

  /// The name of the view that is being transitioned to. Emitted by: TRANSITION_VIEW.
  final String viewName;

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

  factory LinkEventMetadata.fromJson(dynamic json) {
    return LinkEventMetadata(
      viewName: json["viewName"],
      exitStatus: json["exitStatus"],
      mfaType: json["mfaType"],
      requestId: json["requestId"],
      timestamp: json["timestamp"],
      linkSessionId: json["linkSessionId"],
      institutionName: json["institutionName"],
      institutionId: json["institutionId"],
      institutionSearchQuery: json["institutionSearchQuery"],
      errorType: json["errorType"],
      errorCode: json["errorCode"],
      errorMesssage: json["errorMessage"],
    );
  }

  String description() {
    return "viewName: $viewName, exitStatus: $exitStatus, mfaType: $mfaType, requestId: $requestId, timestamp: $timestamp, linkSessionId: $linkSessionId, institutionId: $institutionId, institutionName: $institutionName, institutionSearchQuery: $institutionSearchQuery, errorType: $errorType, errorCode: $errorCode, errorMesssage: $errorMesssage";
  }
}
