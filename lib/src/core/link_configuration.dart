class LinkTokenConfiguration {
  /// Specify a link_token to authenticate your app with Link. This is a short lived, one-time use token that should be unique for each Link session
  final String token;

  /// MOBILE ONLY: A bool indicating that Link should skip displaying a loading animation and Link UI will be presented once it is fully loaded.
  final bool noLoadingState;

  /// WEB ONLY: A receivedRedirectUri is required to support OAuth authentication flows when re-launching Link on a mobile device.
  final String? receivedRedirectUri;

  /// The LinkTokenConfiguration only needs a token which is created by your app's
  /// server and passed to your app's client to initialize Link. The Link configuration parameters that were
  /// previously set within Link itself are now set via parameters passed to /link/token/create and conveyed
  /// to Link via the link_token.
  ///
  /// Note that each time you open Link, you will need to get a new link_token from your server and create a new LinkTokenConfiguration with it.
  ///
  const LinkTokenConfiguration({
    required this.token,
    this.noLoadingState = false,
    this.receivedRedirectUri,
  });

  /// Returns a representation of this object as a JSON object.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'token': token,
      'noLoadingState': noLoadingState,
      'receivedRedirectUri': receivedRedirectUri,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkTokenConfiguration &&
          runtimeType == other.runtimeType &&
          hashCode == other.hashCode;

  @override
  int get hashCode => Object.hash(
      token.hashCode, noLoadingState.hashCode, receivedRedirectUri.hashCode);
}

/// Data to submit during a Link session.
class SubmissionData {
  /// The end user's phone number.
  final String phoneNumber;

  SubmissionData({
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'phoneNumber': phoneNumber,
    };
  }
}
