using SportaApis.Enums;
using SportaApis.Models;
using SportaApis.Services;

namespace SportaApis.Helpers;

/// <summary>
/// استرداد حجز ملعب ملغى: يردّ للاعب ما دفعه، وإن كان الحجز مؤكداً يعكس
/// ما قُيِّد لمالك الملعب عند التأكيد (<see cref="Booking.OwnerAmount"/>)،
/// حتى لا يبقى المالك محتفظاً بأرباح حجز رُدّ مبلغه وتدفعها سبورتا من حصتها.
/// </summary>
public static class BookingRefunds
{
    /// <param name="wasConfirmed">حالة الحجز قبل الإلغاء: المالك يُقيَّد له عند
    /// انتقال الحجز من Pending إلى Confirmed فقط، فلا عكس لحجز معلّق.</param>
    /// <param name="ownerUserId">مالك الملعب الذي قُيِّدت له الأرباح.</param>
    public static async Task RefundAsync(
        IWalletService wallet, Booking booking, bool wasConfirmed,
        int ownerUserId, string playerDescription)
    {
        if (!booking.PaidFullAmount || booking.TotalPrice <= 0) return;

        await wallet.RefundAsync(
            booking.UserId, booking.TotalPrice, playerDescription, booking.Id);

        if (wasConfirmed && booking.OwnerAmount > 0)
            await wallet.ReverseEarningAsync(
                ownerUserId, booking.OwnerAmount, WalletTransactionType.VenueEarning,
                $"عكس أرباح حجز ملغى #{booking.Id}", booking.Id);
    }
}
