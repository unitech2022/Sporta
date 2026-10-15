import '../../../../core/localization/tr_global.dart';
import '../../../../core/utils/server_time.dart';

/// What a top-up will actually cost, as computed by the server.
class TopUpQuote {
  const TopUpQuote({
    required this.amount,
    required this.fee,
    required this.total,
  });

  /// Credited to the wallet.
  final double amount;

  /// Payment-gateway fee incl. VAT; 0 when no fee is configured.
  final double fee;

  /// Charged to the card — [amount] + [fee].
  final double total;

  bool get hasFee => fee > 0;

  factory TopUpQuote.fromJson(Map<String, dynamic> json) => TopUpQuote(
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        fee: (json['fee'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0,
      );
}

/// One wallet transaction.
class WalletTransactionEntity {
  const WalletTransactionEntity({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
    this.status = 'completed',
    this.referenceId,
  });

  final int id;

  /// Positive for credits, negative for payments/withdrawals. Carries the
  /// attempted amount on a failed row, where no money actually moved — always
  /// check [hasFailed] before presenting it as a real movement.
  final double amount;

  /// "deposit" | "refund" | "matchPayment" | "bookingPayment" | "coachPayment"
  /// | "reward" | "withdrawal" | "coachEarning" | "venueEarning"
  /// | "creatorEarning".
  final String type;

  /// "completed" | "failed".
  final String status;

  /// Linked booking / match / session id, per [type].
  final int? referenceId;

  final String? description;
  final DateTime createdAt;

  /// A recorded payment attempt that was rejected (insufficient balance). It is
  /// kept for the payment log but moved no money.
  bool get hasFailed => status == 'failed';

  bool get isCredit => amount >= 0;

  String get typeLabel {
    switch (type) {
      case 'deposit':
        return trg('شحن');
      case 'refund':
        return trg('استرداد');
      case 'bookingPayment':
        return trg('دفع حجز');
      case 'matchPayment':
        return trg('دفع مباراة');
      case 'coachPayment':
        return trg('دفع جلسة');
      case 'reward':
        return trg('مكافأة');
      case 'withdrawal':
        return trg('سحب رصيد');
      case 'coachEarning':
        return trg('أرباح جلسة');
      case 'venueEarning':
        return trg('أرباح حجز');
      case 'creatorEarning':
        return trg('استرداد حصة مباراة');
      default:
        return type;
    }
  }

  factory WalletTransactionEntity.fromJson(Map<String, dynamic> json) =>
      WalletTransactionEntity(
        id: (json['id'] as num?)?.toInt() ?? 0,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        type: json['type']?.toString() ?? '',
        status: json['status']?.toString() ?? 'completed',
        referenceId: (json['referenceId'] as num?)?.toInt(),
        description: json['description']?.toString(),
        createdAt: parseServerUtc(json['createdAt']) ?? DateTime.now(),
      );
}

/// The user's wallet.
class WalletEntity {
  const WalletEntity({
    required this.balance,
    required this.transactions,
    required this.withdrawalThreshold,
    required this.pendingWithdrawalAmount,
  });

  final double balance;
  final List<WalletTransactionEntity> transactions;

  /// Minimum balance required to request a withdrawal.
  final double withdrawalThreshold;

  /// Amount currently held in a pending withdrawal request.
  final double pendingWithdrawalAmount;

  bool get canWithdraw =>
      balance >= withdrawalThreshold && pendingWithdrawalAmount == 0;

  factory WalletEntity.fromJson(Map<String, dynamic> json) => WalletEntity(
        balance: (json['balance'] as num?)?.toDouble() ?? 0,
        transactions: (json['transactions'] as List?)
                ?.map((e) =>
                    WalletTransactionEntity.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        withdrawalThreshold:
            (json['withdrawalThreshold'] as num?)?.toDouble() ?? 100,
        pendingWithdrawalAmount:
            (json['pendingWithdrawalAmount'] as num?)?.toDouble() ?? 0,
      );
}

/// A withdrawal request entity.
class WithdrawalRequestEntity {
  const WithdrawalRequestEntity({
    required this.id,
    required this.amount,
    required this.status,
    required this.iban,
    required this.bankName,
    required this.accountHolderName,
    required this.createdAt,
    this.adminNotes,
    this.processedAt,
  });

  final int id;
  final double amount;
  final String status; // "pending" | "approved" | "rejected"
  final String iban;
  final String bankName;
  final String accountHolderName;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime? processedAt;

  factory WithdrawalRequestEntity.fromJson(Map<String, dynamic> json) =>
      WithdrawalRequestEntity(
        id: (json['id'] as num?)?.toInt() ?? 0,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        status: json['status']?.toString() ?? 'pending',
        iban: json['iban']?.toString() ?? '',
        bankName: json['bankName']?.toString() ?? '',
        accountHolderName: json['accountHolderName']?.toString() ?? '',
        adminNotes: json['adminNotes']?.toString(),
        createdAt: parseServerUtc(json['createdAt']) ?? DateTime.now(),
        processedAt: parseServerUtc(json['processedAt']),
      );
}
