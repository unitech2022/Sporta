import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/filter_sheet.dart';
import '../../cubit/courts_list/courts_cubit.dart';
import 'courts_filter_panel.dart';

/// Opens the courts filters in the shared bottom sheet and applies the result.
/// Nothing reaches the cubit until "تطبيق" is pressed.
Future<void> showCourtsFilterSheet(
  BuildContext context,
  CourtsCubit cubit,
) async {
  final applied = await showFilterSheet<CourtsFilters>(
    context: context,
    initialValue: cubit.state.filters,
    builder: (sheetContext, draft, onChanged) {
      return BlocProvider<CourtsCubit>.value(
        value: cubit,
        // Cities/districts keep loading while the sheet is open, so the lists
        // are read from the live state rather than a snapshot.
        child: BlocBuilder<CourtsCubit, CourtsState>(
          builder: (context, state) => CourtsFilterPanel(
            filters: draft,
            cities: state.cities,
            districts: state.districts,
            onChanged: (next) {
              if (next.city != draft.city) {
                // The district list belongs to the old city: drop the choice
                // and fetch the new city's districts for the picker.
                onChanged(next.copyWith(district: ''));
                cubit.loadDistricts(next.city);
              } else {
                onChanged(next);
              }
            },
          ),
        ),
      );
    },
  );
  if (applied == null) return;
  // The search box is not part of the sheet; keep whatever is typed there.
  cubit.updateFilters(applied.copyWith(query: cubit.state.filters.query));
}
