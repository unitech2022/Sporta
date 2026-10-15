/// Payment configuration fetched from the backend (`GET /wallet/payment-config`).
///
/// There is no payment key here any more. The card form is hosted by FINY, so
/// the app only opens a URL the server hands it and watches for [callbackUrl]
/// to appear — the card number never passes through Sporta, on either side.
class PaymentConfig {
  const PaymentConfig({
    required this.configured,
    required this.callbackUrl,
    this.currency = 'SAR',
    this.applePay,
  });

  /// False while the server still lacks its FINY credentials — the top-up flow
  /// says so plainly instead of opening a checkout page that cannot work.
  final bool configured;

  /// The URL whose appearance means the customer is done with the hosted page.
  /// It is never actually loaded: the WebView intercepts it and closes.
  final String callbackUrl;

  final String currency;

  /// Apple Pay merchant settings — null/disabled hides the button entirely.
  /// Served by the backend so it can be switched off without an app release
  /// and stays in step with the certificate uploaded at the gateway.
  final ApplePayConfig? applePay;

  bool get applePayEnabled => configured && (applePay?.enabled ?? false);

  factory PaymentConfig.fromJson(Map<String, dynamic> json) => PaymentConfig(
        configured: json['configured'] == true,
        callbackUrl: json['callbackUrl']?.toString() ?? '',
        currency: json['currency']?.toString() ?? 'SAR',
        applePay: json['applePay'] is Map<String, dynamic>
            ? ApplePayConfig.fromJson(json['applePay'] as Map<String, dynamic>)
            : null,
      );
}

/// What PassKit needs to show the Apple Pay sheet. The merchant id must match
/// `ios/Runner/RunnerRelease.entitlements` and the processing certificate the
/// gateway holds — the token is useless to anyone else.
class ApplePayConfig {
  const ApplePayConfig({
    required this.enabled,
    required this.merchantId,
    this.displayName = 'Sporta',
    this.countryCode = 'SA',
    this.supportedNetworks = const ['mada', 'visa', 'masterCard'],
  });

  final bool enabled;
  final String merchantId;
  final String displayName;
  final String countryCode;

  /// PassKit network names (`mada`, `visa`, `masterCard`…).
  final List<String> supportedNetworks;

  factory ApplePayConfig.fromJson(Map<String, dynamic> json) => ApplePayConfig(
        enabled: json['enabled'] == true &&
            (json['merchantId']?.toString().isNotEmpty ?? false),
        merchantId: json['merchantId']?.toString() ?? '',
        displayName: json['displayName']?.toString() ?? 'Sporta',
        countryCode: json['countryCode']?.toString() ?? 'SA',
        supportedNetworks: (json['supportedNetworks'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const ['mada', 'visa', 'masterCard'],
      );
}

/// A checkout session opened at FINY: where to send the customer, and what the
/// payment will cost them.
class TopUpSession {
  const TopUpSession({
    required this.paymentId,
    required this.redirectUrl,
    required this.callbackUrl,
    required this.amount,
    required this.total,
  });

  /// FINY's payment id — sent back to our server to confirm the top-up.
  final int paymentId;

  /// The hosted checkout page to open.
  final String redirectUrl;

  /// Appearance of this URL means the hosted page is finished.
  final String callbackUrl;

  /// What lands in the wallet.
  final double amount;

  /// What the card is charged (amount + gateway fee).
  final double total;

  factory TopUpSession.fromJson(Map<String, dynamic> json) => TopUpSession(
        paymentId: (json['paymentId'] as num?)?.toInt() ?? 0,
        redirectUrl: json['redirectUrl']?.toString() ?? '',
        callbackUrl: json['callbackUrl']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0,
      );
}
