import 'dart:async';

/// تغيّر واحد في مفضّلة الملاعب.
class CourtFavoriteChange {
  const CourtFavoriteChange({required this.courtId, required this.isFavorite});

  final String courtId;
  final bool isFavorite;
}

/// ناقل يبقي حالة المفضّلة متسقة بين الشاشات.
///
/// قائمة الملاعب تعيش داخل `IndexedStack` في الـ shell فلا يُعاد بناؤها عند
/// تبديل التبويبات، وكانت تحتفظ بقلوب من لحظة التحميل: إزالة ملعب من صفحة
/// المفضّلة لم تكن تظهر هناك حتى إعادة تشغيل التطبيق. فمن يغيّر المفضّلة ينشر
/// هنا، ومن يعرضها يستمع.
///
/// singleton بلا `close()` عمداً — عمره من عمر التطبيق.
class CourtFavoritesHub {
  final _controller = StreamController<CourtFavoriteChange>.broadcast();

  Stream<CourtFavoriteChange> get changes => _controller.stream;

  void publish(String courtId, {required bool isFavorite}) {
    if (_controller.isClosed) return;
    _controller.add(
      CourtFavoriteChange(courtId: courtId, isFavorite: isFavorite),
    );
  }
}
