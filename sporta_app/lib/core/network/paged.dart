/// A page of results plus paging metadata (mirrors the backend `PagedResult`).
class Paged<T> {
  const Paged({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasMore,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int total;
  final bool hasMore;

  factory Paged.fromJson(
    dynamic json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final map = json is Map<String, dynamic> ? json : <String, dynamic>{};
    final list = (map['items'] as List? ?? [])
        .map((e) => fromItem(e as Map<String, dynamic>))
        .toList();
    return Paged<T>(
      items: list,
      page: (map['page'] as num?)?.toInt() ?? 1,
      pageSize: (map['pageSize'] as num?)?.toInt() ?? list.length,
      total: (map['total'] as num?)?.toInt() ?? list.length,
      hasMore: map['hasMore'] == true,
    );
  }
}
