/// The available environments to use.
enum LinkEnvironment {
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

  /// Gives clients access to details of their users' investment accounts like holdings and buy/sell transactions
  payment_initiation,

  ///
  deposit_switch,
}

/// The LinkOAuthConfiguration class defines the values used to configure the application for OAuth
class LinkOAuthConfiguration {
  /// An oauthRedirectUri is required to support OAuth authentication flows when launching
  /// Link on a mobile device and using one or more European country codes. Note that
  /// any redirect URI must also be added to the Allowed redirect URIs list in the developer dashboard.
  final String? redirectUri;

  /// An oauthNonce is required to support OAuth authentication flows when launching or
  /// re-launching Link on a mobile device and using one or more European country codes.
  /// The nonce must be at least 16 characters long.
  final String? nonce;

  LinkOAuthConfiguration({
    this.redirectUri,
    this.nonce,
  });
}

/// The LinkAccountSubtype class defines the type and the subtype of an account.
class LinkAccountSubtype {
  /// The account type.
  final String type;

  /// The account subtype.
  final String subtype;

  const LinkAccountSubtype({required this.type, required this.subtype});

  /// Returns a representation of this object as a JSON object.
  Map<String, String> toJson() {
    return <String, String>{
      'type': type,
      'subtype': subtype,
    };
  }
}

/// Credit subtypes
class LinkAccountSubtypeCredit {
  static const LinkAccountSubtype all =
      LinkAccountSubtype(type: "credit", subtype: "all");
  static const LinkAccountSubtype creditCard =
      LinkAccountSubtype(type: "credit", subtype: "credit card");
  static const LinkAccountSubtype paypal =
      LinkAccountSubtype(type: "credit", subtype: "paypal");
}

/// Depository subtypes
class LinkAccountSubtypeDepository {
  static const LinkAccountSubtype all =
      LinkAccountSubtype(type: "depository", subtype: "all");
  static const LinkAccountSubtype cashManagement =
      LinkAccountSubtype(type: "depository", subtype: "cash management");
  static const LinkAccountSubtype cd =
      LinkAccountSubtype(type: "depository", subtype: "cd");
  static const LinkAccountSubtype checking =
      LinkAccountSubtype(type: "depository", subtype: "checking");
  static const LinkAccountSubtype ebt =
      LinkAccountSubtype(type: "depository", subtype: "ebt");
  static const LinkAccountSubtype hsa =
      LinkAccountSubtype(type: "depository", subtype: "hsa");
  static const LinkAccountSubtype moneyMarket =
      LinkAccountSubtype(type: "depository", subtype: "money market");
  static const LinkAccountSubtype paypal =
      LinkAccountSubtype(type: "depository", subtype: "paypal");
  static const LinkAccountSubtype prepaid =
      LinkAccountSubtype(type: "depository", subtype: "prepaid");
  static const LinkAccountSubtype savings =
      LinkAccountSubtype(type: "depository", subtype: "savings");
}

/// Investment subtypes
class LinkAccountSubtypeInvestment {
  static const LinkAccountSubtype all =
      LinkAccountSubtype(type: "investment", subtype: "all");
  static const LinkAccountSubtype brokerage =
      LinkAccountSubtype(type: "investment", subtype: "brokerage");
  static const LinkAccountSubtype cashIsa =
      LinkAccountSubtype(type: "investment", subtype: "cash isa");
  static const LinkAccountSubtype educationSavingsAccount = LinkAccountSubtype(
      type: "investment", subtype: "education savings account");
  static const LinkAccountSubtype fixedAnnunity =
      LinkAccountSubtype(type: "investment", subtype: "fixed annuity");
  static const LinkAccountSubtype gic =
      LinkAccountSubtype(type: "investment", subtype: "gic");
  static const LinkAccountSubtype healthReimbursementArrangement =
      LinkAccountSubtype(
          type: "investment", subtype: "health reimbursement arrangement");
  static const LinkAccountSubtype hsa =
      LinkAccountSubtype(type: "investment", subtype: "hsa");
  static const LinkAccountSubtype i401a =
      LinkAccountSubtype(type: "investment", subtype: "401a");
  static const LinkAccountSubtype i401k =
      LinkAccountSubtype(type: "investment", subtype: "401k");
  static const LinkAccountSubtype i403b =
      LinkAccountSubtype(type: "investment", subtype: "403B");
  static const LinkAccountSubtype i457b =
      LinkAccountSubtype(type: "investment", subtype: "457b");
  static const LinkAccountSubtype i529 =
      LinkAccountSubtype(type: "investment", subtype: "529");
  static const LinkAccountSubtype ira =
      LinkAccountSubtype(type: "investment", subtype: "ira");
  static const LinkAccountSubtype isa =
      LinkAccountSubtype(type: "investment", subtype: "isa");
  static const LinkAccountSubtype keogh =
      LinkAccountSubtype(type: "investment", subtype: "keogh");
  static const LinkAccountSubtype lif =
      LinkAccountSubtype(type: "investment", subtype: "lif");
  static const LinkAccountSubtype lira =
      LinkAccountSubtype(type: "investment", subtype: "lira");
  static const LinkAccountSubtype lrif =
      LinkAccountSubtype(type: "investment", subtype: "lrif");
  static const LinkAccountSubtype lrsp =
      LinkAccountSubtype(type: "investment", subtype: "lrsp");
  static const LinkAccountSubtype mutualFund =
      LinkAccountSubtype(type: "investment", subtype: "mutual fund");
  static const LinkAccountSubtype nonTaxableBrokerageAccount =
      LinkAccountSubtype(
          type: "investment", subtype: "non-taxable brokerage account");
  static const LinkAccountSubtype pension =
      LinkAccountSubtype(type: "investment", subtype: "pension");
  static const LinkAccountSubtype plan =
      LinkAccountSubtype(type: "investment", subtype: "plan");
  static const LinkAccountSubtype prif =
      LinkAccountSubtype(type: "investment", subtype: "prif");
  static const LinkAccountSubtype profitSharingPlan =
      LinkAccountSubtype(type: "investment", subtype: "profit sharing plan");
  static const LinkAccountSubtype rdsp =
      LinkAccountSubtype(type: "investment", subtype: "rdsp");
  static const LinkAccountSubtype resp =
      LinkAccountSubtype(type: "investment", subtype: "resp");
  static const LinkAccountSubtype retirement =
      LinkAccountSubtype(type: "investment", subtype: "retirement");
  static const LinkAccountSubtype rlif =
      LinkAccountSubtype(type: "investment", subtype: "rlif");
  static const LinkAccountSubtype roth =
      LinkAccountSubtype(type: "investment", subtype: "roth");
  static const LinkAccountSubtype roth401k =
      LinkAccountSubtype(type: "investment", subtype: "roth 401k");
  static const LinkAccountSubtype rrif =
      LinkAccountSubtype(type: "investment", subtype: "rrif");
  static const LinkAccountSubtype rrsp =
      LinkAccountSubtype(type: "investment", subtype: "rrsp");
  static const LinkAccountSubtype sarsep =
      LinkAccountSubtype(type: "investment", subtype: "sarsep");
  static const LinkAccountSubtype sepIra =
      LinkAccountSubtype(type: "investment", subtype: "sep ira");
  static const LinkAccountSubtype simpleIra =
      LinkAccountSubtype(type: "investment", subtype: "simple ira");
  static const LinkAccountSubtype sipp =
      LinkAccountSubtype(type: "investment", subtype: "sipp");
  static const LinkAccountSubtype stockPlan =
      LinkAccountSubtype(type: "investment", subtype: "stock plan");
  static const LinkAccountSubtype tfsa =
      LinkAccountSubtype(type: "investment", subtype: "tfsa");
  static const LinkAccountSubtype thriftSavingsPlan =
      LinkAccountSubtype(type: "investment", subtype: "thrift savings plan");
  static const LinkAccountSubtype trust =
      LinkAccountSubtype(type: "investment", subtype: "trust");
  static const LinkAccountSubtype ugma =
      LinkAccountSubtype(type: "investment", subtype: "ugma");
  static const LinkAccountSubtype utma =
      LinkAccountSubtype(type: "investment", subtype: "utma");
  static const LinkAccountSubtype variableAnnuity =
      LinkAccountSubtype(type: "investment", subtype: "variable annuity");
}

/// Loan subtypes
class LinkAccountSubtypeLoan {
  static const LinkAccountSubtype all =
      LinkAccountSubtype(type: "loan", subtype: "all");
  static const LinkAccountSubtype auto =
      LinkAccountSubtype(type: "loan", subtype: "auto");
  static const LinkAccountSubtype business =
      LinkAccountSubtype(type: "loan", subtype: "business");
  static const LinkAccountSubtype commercial =
      LinkAccountSubtype(type: "loan", subtype: "commercial");
  static const LinkAccountSubtype construction =
      LinkAccountSubtype(type: "loan", subtype: "construction");
  static const LinkAccountSubtype consumer =
      LinkAccountSubtype(type: "loan", subtype: "consumer");
  static const LinkAccountSubtype homeEquity =
      LinkAccountSubtype(type: "loan", subtype: "home equity");
  static const LinkAccountSubtype lineOfCredit =
      LinkAccountSubtype(type: "loan", subtype: "line of credit");
  static const LinkAccountSubtype loan =
      LinkAccountSubtype(type: "loan", subtype: "loan");
  static const LinkAccountSubtype mortgage =
      LinkAccountSubtype(type: "loan", subtype: "mortgage");
  static const LinkAccountSubtype overdraft =
      LinkAccountSubtype(type: "loan", subtype: "overdraft");
  static const LinkAccountSubtype student =
      LinkAccountSubtype(type: "loan", subtype: "student");
}
