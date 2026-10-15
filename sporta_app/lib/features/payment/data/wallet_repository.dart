import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/paged.dart';
import '../../../core/payment/payment_config.dart';
import '../../auth/data/models/api_exception.dart';
import '../domain/entities/wallet_entity.dart';

/// Talks to the wallet REST endpoints.
class WalletRepository {
  WalletRepository(this._dio);

  final Dio _dio;

  Future<WalletEntity> fetchWallet() async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.wallet);
      return WalletEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// A page of transaction history (newest first).
  Future<Paged<WalletTransactionEntity>> fetchTransactions({
    int page = 1,
    int pageSize = 20,
  }) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.walletTransactions,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return Paged.fromJson(_unwrap(res.data), WalletTransactionEntity.fromJson);
    });
  }

  /// What a top-up of [amount] costs: the gateway fee and the total to charge
  /// the card. Only the server computes this — it re-derives the same total when
  /// verifying the payment, so the two can never disagree by a halala.
  Future<TopUpQuote> fetchTopUpQuote(double amount) async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.walletTopUpQuote,
          queryParameters: {'amount': amount});
      return TopUpQuote.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// Opens a checkout session at FINY. Nothing is charged and no balance moves
  /// here — this only returns the hosted page to send the customer to.
  Future<TopUpSession> startTopUp(double amount, {String? description}) async {
    return _guard(() async {
      final res = await _dio.post(ApiEndpoints.walletTopUpSession, data: {
        'amount': amount,
        if (description != null) 'description': description,
      });
      return TopUpSession.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// Asks the backend to settle the session. It re-reads the payment from FINY
  /// rather than trusting this call, so "I paid" from the app proves nothing.
  ///
  /// Returns null when the gateway has not confirmed the payment yet (HTTP 202)
  /// — the webhook settles it moments later.
  Future<WalletEntity?> confirmTopUp(int paymentId) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.walletTopUpConfirm,
        data: {'paymentId': paymentId},
        // 202 means "still pending", which is an answer, not a failure.
        options: Options(validateStatus: (code) => code != null && code < 400),
      );
      if (res.statusCode == 202) return null;
      return WalletEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// Tops up with an Apple Pay token in one round trip. The server hands the
  /// token to the gateway (it is encrypted for the gateway alone) and credits
  /// the wallet from the gateway's own record, so the returned balance is
  /// already settled.
  ///
  /// Returns null when the gateway has not confirmed yet (HTTP 202) — rare for
  /// Apple Pay; the webhook lands moments later.
  Future<WalletEntity?> topUpWithApplePay({
    required double amount,
    required String token,
  }) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.walletTopUpApplePay,
        data: {'amount': amount, 'token': token},
        options: Options(validateStatus: (code) => code != null && code < 400),
      );
      if (res.statusCode == 202) return null;
      return WalletEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// Whether the server can take payments at all, and the callback URL the
  /// checkout WebView watches for.
  Future<PaymentConfig> fetchPaymentConfig() async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.walletPaymentConfig);
      return PaymentConfig.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  Future<WithdrawalRequestEntity> requestWithdrawal({
    required double amount,
    required String iban,
    required String bankName,
    required String accountHolderName,
  }) async {
    return _guard(() async {
      final res = await _dio.post(ApiEndpoints.walletWithdraw, data: {
        'amount': amount,
        'iban': iban,
        'bankName': bankName,
        'accountHolderName': accountHolderName,
      });
      return WithdrawalRequestEntity.fromJson(
          _unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// Admin: list withdrawal requests (paged + optional status filter).
  Future<Paged<WithdrawalRequestEntity>> fetchWithdrawalRequests({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.walletWithdrawals, queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (status != null) 'status': status,
      });
      return Paged.fromJson(
          _unwrap(res.data), WithdrawalRequestEntity.fromJson);
    });
  }

  /// Admin: approve or reject a withdrawal request.
  Future<WithdrawalRequestEntity> processWithdrawal(
      int id, bool approved, String? adminNotes) async {
    return _guard(() async {
      final res = await _dio.patch(
        ApiEndpoints.walletWithdrawalProcess(id),
        data: {'approved': approved, 'adminNotes': adminNotes},
      );
      return WithdrawalRequestEntity.fromJson(
          _unwrap(res.data) as Map<String, dynamic>);
    });
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  dynamic _unwrap(dynamic body) =>
      body is Map<String, dynamic> ? (body['data'] ?? body) : body;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw e.response != null
          ? ApiException.fromResponse(e.response!)
          : ApiException.network;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException.unexpected;
    }
  }
}
