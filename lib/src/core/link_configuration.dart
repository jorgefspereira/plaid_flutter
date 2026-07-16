/// The native LinkKit session created for a link token.
///
/// LinkKit 7 requires a token to be used with the session type it was created
/// for. Tokens for different session types are not interchangeable.
enum LinkSessionType {
  /// A standard, user-presented Plaid Link session on iOS.
  standard,

  /// A Plaid Layer session on iOS.
  layer,

  /// A headless Link session on iOS that runs without presenting Link UI.
  headless,
}

class LinkTokenConfiguration {
  /// Specify a link_token to authenticate your app with Link. This is a short lived, one-time use token that should be unique for each Link session
  final String token;

  /// ANDROID ONLY: A bool indicating that Link should skip displaying a
  /// loading animation and present Link UI once it is fully loaded.
  ///
  /// LinkKit 7 no longer supports this option on iOS. Use [sessionType] to
  /// create a [LinkSessionType.headless] session when using a headless token.
  final bool noLoadingState;

  /// WEB ONLY: A receivedRedirectUri is required to support OAuth authentication flows when re-launching Link on a mobile device.
  final String? receivedRedirectUri;

  /// IOS STANDARD LINK ONLY: Whether Link displays a transparent gradient
  /// background.
  final bool showGradientBackground;

  /// The type of native Link session to create.
  ///
  /// Android and web continue to use their platform-native handler APIs. iOS
  /// uses this value to select the matching LinkKit 7 session API.
  final LinkSessionType sessionType;

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
    this.showGradientBackground = false,
    this.receivedRedirectUri,
    this.sessionType = LinkSessionType.standard,
  });

  /// Returns a representation of this object as a JSON object.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'token': token,
      'noLoadingState': noLoadingState,
      'receivedRedirectUri': receivedRedirectUri,
      'showGradientBackground': showGradientBackground,
      'sessionType': sessionType.name,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkTokenConfiguration &&
          token == other.token &&
          noLoadingState == other.noLoadingState &&
          receivedRedirectUri == other.receivedRedirectUri &&
          showGradientBackground == other.showGradientBackground &&
          sessionType == other.sessionType;

  @override
  int get hashCode => Object.hash(
        token.hashCode,
        noLoadingState.hashCode,
        receivedRedirectUri.hashCode,
        showGradientBackground.hashCode,
        sessionType.hashCode,
      );
}

/// Data to submit during a Link session.
class SubmissionData {
  /// The end user's phone number.
  String? phoneNumber;

  /// The end user's date of birth. To be provided in the format "yyyy-mm-dd".
  String? dateOfBirth;

  /// Additional optional values to submit during a Link session.
  Map<String, String>? params;

  SubmissionData({
    this.phoneNumber,
    this.dateOfBirth,
    this.params,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth,
      'params': params,
    };
  }
}
