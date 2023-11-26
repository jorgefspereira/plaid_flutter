/// The LinkTokenConfiguration only needs a link_token which is created by your app's
/// server and passed to your app's client to initialize Link. The Link configuration parameters that were
/// previously set within Link itself are now set via parameters passed to /link/token/create and conveyed
/// to Link via the link_token.
class LinkTokenConfiguration {
  /// Specify a link_token to authenticate your app with Link. This is a short lived, one-time use token that should be unique for each Link session
  final String token;

  /// MOBILE ONLY: A bool indicating that Link should skip displaying a loading animation and Link UI will be presented once it is fully loaded.
  final bool noLoadingState;

  /// WEB ONLY: A receivedRedirectUri is required to support OAuth authentication flows when re-launching Link on a mobile device.
  String? receivedRedirectUri;

  LinkTokenConfiguration({
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
}
