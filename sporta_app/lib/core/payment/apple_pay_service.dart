import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pay/pay.dart';

import 'payment_config.dart';

/// Thin wrapper over the `pay` plugin for Apple Pay.
///
/// It only shows Apple's sheet and hands back the raw PassKit token
/// (`paymentData` JSON). Nothing is charged here: the token is encrypted for
/// the gateway's processing certificate, and the server forwards it to FINY
/// → Moyasar, which is where the money moves. No key ever lives in the app.
class ApplePayService {
  ApplePayService(this.config);

  final ApplePayConfig config;

  /// Apple Pay is iOS-only; on Android the button never renders.
  static bool get isSupportedPlatform => Platform.isIOS;

  Pay get _client => Pay({
        PayProvider.apple_pay:
            PaymentConfiguration.fromJsonString(jsonEncode(_configJson())),
      });

  Map<String, dynamic> _configJson() => {
        'provider': 'apple_pay',
        'data': {
          'merchantIdentifier': config.merchantId,
          'displayName': config.displayName,
          'merchantCapabilities': ['3DS', 'debit', 'credit'],
          'supportedNetworks': config.supportedNetworks,
          'countryCode': config.countryCode,
          'currencyCode': 'SAR',
          'requiredBillingContactFields': <String>[],
          'requiredShippingContactFields': <String>[],
        },
      };

  /// True when the device has Apple Pay set up with a card on one of the
  /// supported networks. Any plugin error counts as "no" — the card flow is
  /// always there as the fallback.
  Future<bool> canPay() async {
    if (!isSupportedPlatform || !config.enabled) return false;
    try {
      return await _client.userCanPay(PayProvider.apple_pay);
    } catch (_) {
      return false;
    }
  }

  /// Shows the Apple Pay sheet for [total] SAR and returns the PassKit token
  /// as the JSON string the gateway expects. Null when the user dismissed the
  /// sheet. Throws [ApplePayException] on a plugin/PassKit failure.
  Future<String?> requestToken({
    required double total,
    required String label,
  }) async {
    try {
      final result = await _client.showPaymentSelector(
        PayProvider.apple_pay,
        [
          PaymentItem(
            label: label,
            amount: total.toStringAsFixed(2),
            status: PaymentItemStatus.final_price,
          ),
        ],
      );
      final token = result['token']?.toString();
      return (token == null || token.isEmpty) ? null : token;
    } on PlatformException catch (e) {
      // The plugin reports a dismissed sheet as a cancellation, not a result.
      if (e.code == 'paymentCanceled' ||
          e.code == 'userCanceled' ||
          (e.message?.toLowerCase().contains('cancel') ?? false)) {
        return null;
      }
      throw ApplePayException(e.message ?? e.code);
    }
  }
}

class ApplePayException implements Exception {
  ApplePayException(this.message);
  final String message;

  @override
  String toString() => 'ApplePayException: $message';
}
