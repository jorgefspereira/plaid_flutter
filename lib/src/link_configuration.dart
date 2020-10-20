/// The available environments to use.
enum LinkEnv {
  /// For testing use,
  ///
  /// A stateful sandbox environment; use test credentials and build out and test your integration
  sandbox,

  /// For development use
  ///
  /// Test your integration with live credentials; you will need to request access before you can use Plaid's Development environment
  development,

  /// For production use only
  ///
  /// Production API environment; all requests are billed
  production
}

/// Options for specifying the Plaid products to use.
///
/// For more information visit the Plaid Products page (https://plaid.com/products/).
enum LinkProduct {
  /// Historical snapshots, real-time summaries, and auditable copies.
  assets,

  /// Verify accounts for payments without micro-deposits.
  auth,

  /// Verify real-time account balances
  balance,

  /// Verify user identities with bank account data to reduce fraud.
  identity,

  /// Validate income and verify employer info more accurately.
  income,

  /// Build a holistic view of a user’s investments
  investments,

  /// Access liabilities data for student loans and credit cards
  liabilities,

  /// Account and transaction data to better serve users.
  transactions,

  /// asdsad
  paymentInitiation
}

/// The LinkConfiguration class defines properties to be used by Plaid API.
/// It still supports the old Plaid flow that required a static public_key.
class LinkConfiguration {
  /// Create a LinkConfiguration.
  LinkConfiguration({
    this.linkToken,
    this.publicKey,
    this.clientName,
    this.env,
    this.products,
    this.webhook,
    this.accountSubtypes,
    this.oauthRedirectUri,
    this.oauthNonce,
    this.linkCustomizationName,
    this.language,
    this.countryCodes,
    this.userLegalName,
    this.userEmailAddress,
    this.userPhoneNumber,
    this.institution,
    this.oauthStateId,
    this.paymentToken,
  });

  /// A link_token received from /link/token/create.
  ///
  /// For more information: https://plaid.com/docs/#create-link-token
  final String linkToken;

  /// Your Plaid public_key available from the Plaid dashboard (https://dashboard.plaid.com/team/keys).
  ///
  /// The [publicKey] is deprecated. To upgrade to the new link_token flow check the following link: https://plaid.com/docs/upgrade-to-link-tokens/
  final String publicKey;

  /// Displayed to the user once they have successfully linked their account
  final String clientName;

  /// The API environment to use. Selects the Plaid servers with which LinkKit communicates.
  final LinkEnv env;

  /// The webhook will receive notifications once a userʼs transactions have been processed and are ready for use.
  final String webhook;

  /// An URL that has been registered with Plaid for OpenBanking App-to-App authentication
  /// and is set up as an Apple universal link for your application.
  final String oauthRedirectUri;

  /// The oauthNonce must be uniquely generated per login, it must not be contained within the oauthRedirectUri,
  /// and must be separate from any user identifiers you pass with the oauthRedirectUri.
  final String oauthNonce;

  /// The value of the oauth_state_id query parameter from the URL passed via the browsing web activity.
  final String oauthStateId;

  /// The list of Plaid products you would like to use.
  final List<LinkProduct> products;

  /// Map of account types and subtypes, used to show only institutions with these following account subtypes
  ///
  /// For more information: https://plaid.com/docs/#auth-filtering-institutions-in-link
  final Map<String, List<String>> accountSubtypes;

  /// Allows non default customization to be retrieved by name.
  final String linkCustomizationName;

  /// Plaid-supported language to localize Link. English will be used by default.
  final String language;

  /// A list of Plaid-supported country codes using the ISO-3166-1 alpha-2 country code standard.
  final List<String> countryCodes;

  /// The legal name of the end-user, necessary for microdeposit support.
  final String userLegalName;

  /// The email address of the end-user, necessary for microdeposit support.
  final String userEmailAddress;

  /// The phone number of the end-user, used for returning user experience.
  final String userPhoneNumber;

  /// The Plaid identifier for a financial institution.
  final String institution;

  /// An payment token to launch Link in payment initiation mode.
  /// More info: https://plaid.com/docs/#payment-initiation
  final String paymentToken;
}
