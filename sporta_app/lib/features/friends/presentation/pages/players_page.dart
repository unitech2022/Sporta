import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../data/friend_repository.dart';
import '../../domain/entities/player_summary.dart';
import '../widgets/player_row_tile.dart';
import '../../../../core/utils/system_insets.dart';

export '../widgets/player_row_tile.dart';

/// اللاعبون في تبويبين — «الأصدقاء» و«اللاعبون» — وحقل بحث واحد فوقهما:
/// في تبويب اللاعبين يبحث الخادم بالاسم أو الجوال (بلا نص: الكل، الأقرب أولاً)،
/// وفي تبويب الأصدقاء يُرشَّح ما حُمّل محلياً.
class PlayersPage extends StatefulWidget {
  const PlayersPage({super.key});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage>
    with SingleTickerProviderStateMixin {
  final _repo = getIt<FriendRepository>();
  final _searchCtrl = TextEditingController();
  late final TabController _tabs;
  Timer? _debounce;

  /// طلبات الصداقة المُرسَلة في هذه الجلسة — تُبقي الزر «تم الإرسال» في كل
  /// قائمة يظهر فيها اللاعب دون إعادة تحميل.
  final Set<int> _sent = {};

  List<PlayerSummary> _players = [];
  bool _playersLoading = true;

  List<PlayerSummary> _friends = [];
  bool _friendsLoading = true;

  String _query = '';

  static const _palette = [
    Color(0xFF3B82F6), Color(0xFFF97316), Color(0xFFEAB308),
    Color(0xFF22C55E), Color(0xFFA855F7),
  ];

  @override
  void initState() {
    super.initState();
    // الدخول من قسم «اللاعبين» في الرئيسية، فنفتح على تبويبهم.
    _tabs = TabController(length: 2, vsync: this, initialIndex: 1);
    _loadPlayers();
    _loadFriends();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    final query = _query;
    try {
      final items = await _repo.searchPlayers(query);
      // ردّ متأخر لنصّ سابق لا يكتب فوق نتيجة النصّ الحالي.
      if (!mounted || query != _query) return;
      setState(() {
        _players = items;
        _playersLoading = false;
      });
    } catch (_) {
      if (!mounted || query != _query) return;
      setState(() => _playersLoading = false);
    }
  }

  Future<void> _loadFriends() async {
    try {
      final items = await _repo.fetchFriends();
      if (!mounted) return;
      setState(() {
        _friends = items;
        _friendsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _friendsLoading = false);
    }
  }

  void _onSearch(String value) {
    final q = value.trim();
    if (q == _query) return;
    setState(() {
      _query = q;
      _playersLoading = true;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _loadPlayers);
  }

  /// الأصدقاء يُرشَّحون محلياً بالاسم أو المدينة — قائمتهم صغيرة ومحمّلة كلها.
  List<PlayerSummary> get _filteredFriends {
    if (_query.isEmpty) return _friends;
    final q = _query.toLowerCase();
    return _friends
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            (p.city?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  Future<void> _add(int userId) async {
    setState(() => _sent.add(userId));
    try {
      await _repo.sendRequest(userId);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sent.remove(userId));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          title: Text(context.tr('اللاعبون')),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(112),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSizes.pagePadding, 0,
                      AppSizes.pagePadding, AppSizes.md),
                  child: AppSearchField(
                    hint: context.tr('ابحث عن لاعب بالاسم أو الجوال...'),
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                  ),
                ),
                TabBar(
                  controller: _tabs,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w600),
                  unselectedLabelStyle: AppTextStyles.body,
                  tabs: [
                    Tab(text: context.tr('الأصدقاء')),
                    Tab(text: context.tr('اللاعبون')),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            _list(
              items: _filteredFriends,
              loading: _friendsLoading,
              onRefresh: _loadFriends,
              emptyText: _query.isEmpty
                  ? context.tr('لا يوجد أصدقاء بعد — ابحث وأضف لاعبين')
                  : context.tr('لا توجد نتائج'),
            ),
            _list(
              items: _players,
              loading: _playersLoading,
              onRefresh: _loadPlayers,
              emptyText: _query.isEmpty
                  ? context.tr('لا يوجد لاعبون حالياً')
                  : context.tr('لا توجد نتائج'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list({
    required List<PlayerSummary> items,
    required bool loading,
    required Future<void> Function() onRefresh,
    required String emptyText,
  }) {
    if (loading) return const SkeletonList();
    if (items.isEmpty) {
      return Center(
        child: Text(emptyText,
            textAlign: TextAlign.center,
            style:
                AppTextStyles.body.copyWith(color: AppColors.mutedForeground)),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: context.safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSizes.md),
        itemBuilder: (_, i) => PlayerRowTile(
          player: items[i],
          avatarColor: _palette[i % _palette.length],
          sent: _sent.contains(items[i].userId),
          onAdd: () => _add(items[i].userId),
        ),
      ),
    );
  }
}
