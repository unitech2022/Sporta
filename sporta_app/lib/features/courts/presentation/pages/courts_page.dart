import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gradient_page_header.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/courts_mock_data.dart';
import '../../domain/entities/court_entity.dart';

class CourtsPage extends StatefulWidget {
  const CourtsPage({super.key, this.onBack, this.onNavigateToCourt});
  final VoidCallback? onBack;
  final void Function(String courtId)? onNavigateToCourt;

  @override
  State<CourtsPage> createState() => _CourtsPageState();
}

class _CourtsPageState extends State<CourtsPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _showMap = false;
  bool _showFilters = false;

  String _sortBy = 'rating';
  String _selectedCity = '';
  CourtType? _selectedType;
  CourtGender? _selectedGender;
  String _priceRange = 'all';
  String _ratingFilter = 'all';
  String _selectedDuration = 'all';

  late List<CourtEntity> _courts;
  late List<CourtEntity> _filtered;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _courts = List.from(mockCourts);
    _filtered = List.from(_courts);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _filtered = filterCourts(
        courts: _courts,
        query: _searchController.text,
        sortBy: _sortBy,
        selectedCity: _selectedCity,
        selectedType: _selectedType,
        selectedGender: _selectedGender,
        priceRange: _priceRange,
        ratingFilter: _ratingFilter,
      );
      if (_selectedDuration != 'all') {
        final dur = int.tryParse(_selectedDuration);
        if (dur != null) {
          _filtered =
              _filtered.where((c) => c.availableDurations.contains(dur)).toList();
        }
      }
    });
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedCity.isNotEmpty) count++;
    if (_selectedType != null) count++;
    if (_selectedGender != null) count++;
    if (_priceRange != 'all') count++;
    if (_ratingFilter != 'all') count++;
    if (_selectedDuration != 'all') count++;
    if (_sortBy != 'rating') count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            GradientPageHeader(
              title: 'احجز ملعب',
              onBack: widget.onBack,
              bottom: _buildHeaderBottom(),
            ),
            Expanded(
              child: _showMap ? _buildMapView() : _buildListView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBottom() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppSearchField(
                hint: 'ابحث عن ملعب...',
                controller: _searchController,
                onChanged: (_) => _applyFilters(),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            _HeaderIconButton(
              icon: _showMap ? Icons.list_rounded : Icons.map_outlined,
              onTap: () => setState(() => _showMap = !_showMap),
              tooltip: _showMap ? 'عرض قائمة' : 'عرض خريطة',
            ),
            const SizedBox(width: AppSizes.xs),
            Stack(
              clipBehavior: Clip.none,
              children: [
                _HeaderIconButton(
                  icon: Icons.tune_rounded,
                  onTap: () => setState(() => _showFilters = !_showFilters),
                  tooltip: 'الفلاتر',
                  isActive: _showFilters,
                ),
                if (_activeFilterCount > 0)
                  Positioned(
                    top: -4,
                    left: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$_activeFilterCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
      ],
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
        if (_showFilters) _buildFilterPanel(),
        Expanded(
          child: _filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.pagePadding),
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) => _CourtCard(
                    court: _filtered[index],
                    onFavoriteTap: () {
                      setState(() {
                        _filtered[index].isFavorite =
                            !_filtered[index].isFavorite;
                      });
                    },
                    onBookTap: () =>
                        widget.onNavigateToCourt?.call(_filtered[index].id),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      color: AppColors.card,
      constraints: const BoxConstraints(maxHeight: 360),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FilterSection(
              title: 'ترتيب حسب',
              child: _ChipGroup(
                options: const [
                  ('rating', 'التقييم'),
                  ('price', 'السعر'),
                  ('distance', 'المسافة'),
                ],
                selected: _sortBy,
                onSelected: (v) {
                  setState(() => _sortBy = v);
                  _applyFilters();
                },
              ),
            ),
            const SizedBox(height: AppSizes.md),
            _FilterSection(
              title: 'المدينة',
              child: _ChipGroup(
                options: const [
                  ('', 'الكل'),
                  ('الدمام', 'الدمام'),
                  ('الخبر', 'الخبر'),
                  ('القطيف', 'القطيف'),
                ],
                selected: _selectedCity,
                onSelected: (v) {
                  setState(() => _selectedCity = v);
                  _applyFilters();
                },
              ),
            ),
            const SizedBox(height: AppSizes.md),
            _FilterSection(
              title: 'نوع الملعب',
              child: _ChipGroup(
                options: const [
                  ('all', 'الكل'),
                  ('indoor', 'مغطى'),
                  ('outdoor', 'مفتوح'),
                ],
                selected: _selectedType == null
                    ? 'all'
                    : _selectedType == CourtType.indoor
                        ? 'indoor'
                        : 'outdoor',
                onSelected: (v) {
                  setState(() {
                    if (v == 'all') {
                      _selectedType = null;
                    } else {
                      _selectedType =
                          v == 'indoor' ? CourtType.indoor : CourtType.outdoor;
                    }
                  });
                  _applyFilters();
                },
              ),
            ),
            const SizedBox(height: AppSizes.md),
            _FilterSection(
              title: 'الجنس',
              child: _ChipGroup(
                options: const [
                  ('all', 'الكل'),
                  ('men', 'رجال'),
                  ('women', 'نساء'),
                  ('family', 'عائلي'),
                ],
                selected: _selectedGender == null
                    ? 'all'
                    : _selectedGender == CourtGender.men
                        ? 'men'
                        : _selectedGender == CourtGender.women
                            ? 'women'
                            : 'family',
                onSelected: (v) {
                  setState(() {
                    if (v == 'all') {
                      _selectedGender = null;
                    } else if (v == 'men') {
                      _selectedGender = CourtGender.men;
                    } else if (v == 'women') {
                      _selectedGender = CourtGender.women;
                    } else {
                      _selectedGender = CourtGender.family;
                    }
                  });
                  _applyFilters();
                },
              ),
            ),
            const SizedBox(height: AppSizes.md),
            _FilterSection(
              title: 'نطاق السعر',
              child: _ChipGroup(
                options: const [
                  ('all', 'الكل'),
                  ('low', 'منخفض'),
                  ('medium', 'متوسط'),
                  ('high', 'مرتفع'),
                ],
                selected: _priceRange,
                onSelected: (v) {
                  setState(() => _priceRange = v);
                  _applyFilters();
                },
              ),
            ),
            const SizedBox(height: AppSizes.md),
            _FilterSection(
              title: 'التقييم',
              child: _ChipGroup(
                options: const [
                  ('all', 'الكل'),
                  ('4+', '4+'),
                  ('4.5+', '4.5+'),
                ],
                selected: _ratingFilter,
                onSelected: (v) {
                  setState(() => _ratingFilter = v);
                  _applyFilters();
                },
              ),
            ),
            const SizedBox(height: AppSizes.md),
            _FilterSection(
              title: 'مدة الجلسة',
              child: _ChipGroup(
                options: const [
                  ('all', 'الكل'),
                  ('60', '60 دقيقة'),
                  ('90', '90 دقيقة'),
                  ('120', '120 دقيقة'),
                ],
                selected: _selectedDuration,
                onSelected: (v) {
                  setState(() => _selectedDuration = v);
                  _applyFilters();
                },
              ),
            ),
            const SizedBox(height: AppSizes.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _sortBy = 'rating';
                    _selectedCity = '';
                    _selectedType = null;
                    _selectedGender = null;
                    _priceRange = 'all';
                    _ratingFilter = 'all';
                    _selectedDuration = 'all';
                  });
                  _applyFilters();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                ),
                child: const Text('مسح الفلاتر'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        CustomPaint(
          size: Size.infinite,
          painter: _GridPainter(),
        ),
        if (_showFilters)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildFilterPanel(),
          ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 280,
                height: 200,
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, _) => Stack(
                    clipBehavior: Clip.none,
                    children: _buildPulsingPins(),
                  ),
                ),
              ),
              SizedBox(height: AppSizes.xl),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  '${_filtered.length} ملاعب في المنطقة',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPulsingPins() {
    const positions = [
      Offset(40, 80),
      Offset(140, 30),
      Offset(220, 100),
      Offset(80, 150),
      Offset(180, 160),
    ];
    final count = math.min(_filtered.length, positions.length);
    return List.generate(count, (i) {
      final scale =
          i.isEven ? _pulseAnim.value : (1.6 - _pulseAnim.value);
      return Positioned(
        left: positions[i].dx,
        top: positions[i].dy,
        child: Transform.scale(
          scale: scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  '${_filtered[i].basePrice} ر.س',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              CustomPaint(
                size: const Size(10, 6),
                painter: _PinTailPainter(),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports_tennis_rounded,
            size: 64,
            color: AppColors.mutedForeground.withValues(alpha: 0.4),
          ),
          SizedBox(height: AppSizes.lg),
          Text(
            'لا توجد ملاعب',
            style: AppTextStyles.heading2
                .copyWith(color: AppColors.mutedForeground),
          ),
          SizedBox(height: AppSizes.sm),
          Text(
            'جرّب تغيير معايير البحث أو الفلاتر',
            style:
                AppTextStyles.body.copyWith(color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: isActive
                ? Border.all(color: AppColors.primary, width: 1.5)
                : null,
          ),
          child:
              Icon(icon, color: Colors.white, size: AppSizes.iconMd),
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        child,
      ],
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.xs,
      runSpacing: AppSizes.xs,
      children: options.map((opt) {
        final isSelected = opt.$1 == selected;
        return GestureDetector(
          onTap: () => onSelected(opt.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.xs,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              opt.$2,
              style: AppTextStyles.caption.copyWith(
                color:
                    isSelected ? Colors.white : AppColors.mutedForeground,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CourtCard extends StatelessWidget {
  const _CourtCard({
    required this.court,
    required this.onFavoriteTap,
    required this.onBookTap,
  });

  final CourtEntity court;
  final VoidCallback onFavoriteTap;
  final VoidCallback onBookTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: AppCard(
        padding: EdgeInsets.zero,
        radius: AppSizes.radiusXl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color:
                        AppColors.secondary.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppSizes.radiusXl),
                      topRight: Radius.circular(AppSizes.radiusXl),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sports_tennis_rounded,
                          size: 48,
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
                        SizedBox(height: AppSizes.xs),
                        Text(
                          court.name,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: AppSizes.sm,
                  left: AppSizes.sm,
                  child: GestureDetector(
                    onTap: onFavoriteTap,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        court.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: AppSizes.iconMd,
                        color: court.isFavorite
                            ? Colors.red
                            : AppColors.mutedForeground,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    court.name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  SizedBox(height: AppSizes.xs),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: AppSizes.iconSm,
                        color: Color(0xFFFACC15),
                      ),
                      SizedBox(width: 2),
                      Text(
                        court.rating.toStringAsFixed(1),
                        style: AppTextStyles.caption
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: AppSizes.xs),
                      Text(
                        '(${court.reviews} تقييم)',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Wrap(
                    spacing: AppSizes.xs,
                    runSpacing: AppSizes.xs,
                    children: [
                      _InfoBadge(
                        icon: Icons.location_on_outlined,
                        label:
                            '${court.distance} · ${court.city}',
                      ),
                      _InfoBadge(
                        icon: court.type == CourtType.indoor
                            ? Icons.roofing_rounded
                            : Icons.wb_sunny_outlined,
                        label: courtTypeLabel(court.type),
                      ),
                      _InfoBadge(
                        icon: Icons.people_outline_rounded,
                        label: courtGenderLabel(court.gender),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSizes.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'يبدأ من',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.mutedForeground),
                          ),
                          Text(
                            '${court.basePrice} ر.س',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: onBookTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppSizes.radiusLg),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.lg,
                            vertical: AppSizes.sm,
                          ),
                        ),
                        child: const Text('احجز الآن'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.mutedForeground),
          SizedBox(width: 3),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedForeground,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PinTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
