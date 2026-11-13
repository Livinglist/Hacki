import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/search/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';

import 'support/golden_harness.dart';

void main() {
  testGoldens('filter_widgets', <GoldenScenario>[
    for (final bool selected in <bool>[false, true])
      GoldenScenario(
        selected ? 'selected_filters' : 'unselected_filters',
        () => Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              PointsFilterChip(
                filter: selected
                    ? PointsFilter(
                        points: 100,
                        condition: NumericCondition.defaultValue,
                      )
                    : null,
                onChanged: (_) {},
              ),
              NumberOfCommentsFilterChip(
                filter: selected
                    ? CommentsNumberFilter(
                        commentsNumber: 25,
                        condition: NumericCondition.defaultValue,
                      )
                    : null,
                onChanged: (_) {},
              ),
              PostedByFilterChip(
                filter: selected ? const PostedByFilter(author: 'alice') : null,
                onChanged: (_) {},
              ),
              DateTimeRangeFilterChip(
                filter: selected
                    ? DateTimeRangeFilter(
                        startTime: DateTime(2024),
                        endTime: DateTime(2024, 1, 31),
                      )
                    : null,
                initialStartDate: null,
                initialEndDate: null,
                onDateTimeRangeUpdated: (_, _) {},
                onDateTimeRangeRemoved: () {},
              ),
            ],
          ),
        ),
        covers: <String>{
          'lib/screens/search/widgets/points_filter_chip.dart#PointsFilterChip',
          'lib/screens/search/widgets/number_of_comments_filter_chip.dart#NumberOfCommentsFilterChip',
          'lib/screens/search/widgets/posted_by_filter_chip.dart#PostedByFilterChip',
          'lib/screens/search/widgets/date_time_range_filter_chip.dart#DateTimeRangeFilterChip',
          'lib/screens/widgets/custom_chip.dart#CustomChip',
        },
      ),
    GoldenScenario(
      'date_shortcuts',
      () => Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          children: <Widget>[
            for (final CustomDateTimeRange range in CustomDateTimeRange.values)
              CustomRangeFilterChip(range: range, onTap: (_, _) {}),
            DateTimeShortcutChip.dayBefore(
              onDateTimeRangeUpdated: (_, _) {},
              startDate: null,
              endDate: null,
            ),
            DateTimeShortcutChip.dayAfter(
              onDateTimeRangeUpdated: (_, _) {},
              startDate: null,
              endDate: null,
            ),
            DateTimeShortcutChip.weekBefore(
              onDateTimeRangeUpdated: (_, _) {},
              startDate: null,
              endDate: null,
            ),
            DateTimeShortcutChip.weekAfter(
              onDateTimeRangeUpdated: (_, _) {},
              startDate: null,
              endDate: null,
            ),
            DateTimeShortcutChip.monthBefore(
              onDateTimeRangeUpdated: (_, _) {},
              startDate: null,
              endDate: null,
            ),
            DateTimeShortcutChip.monthAfter(
              onDateTimeRangeUpdated: (_, _) {},
              startDate: null,
              endDate: null,
            ),
            DateTimeShortcutChip.yearBefore(
              onDateTimeRangeUpdated: (_, _) {},
              startDate: null,
              endDate: null,
            ),
            DateTimeShortcutChip.yearAfter(
              onDateTimeRangeUpdated: (_, _) {},
              startDate: null,
              endDate: null,
            ),
          ],
        ),
      ),
      covers: <String>{
        'lib/screens/search/widgets/custom_range_filter_chip.dart#CustomRangeFilterChip',
        'lib/screens/search/widgets/date_time_shortcut_chip.dart#DateTimeShortcutChip',
      },
    ),
    GoldenScenario(
      'points_dialog',
      () => PointsFilterChip(
        filter: PointsFilter(
          points: 100,
          condition: NumericCondition.defaultValue,
        ),
        onChanged: (_) {},
      ),
      exercise: (WidgetTester tester) async {
        await tester.tap(find.byType(PointsFilterChip));
        await tester.pump(const Duration(milliseconds: 300));
      },
      covers: <String>{
        'lib/screens/search/widgets/points_filter_chip.dart#_PointsDialog',
      },
    ),
    GoldenScenario(
      'comments_dialog',
      () => NumberOfCommentsFilterChip(
        filter: CommentsNumberFilter(
          commentsNumber: 25,
          condition: NumericCondition.defaultValue,
        ),
        onChanged: (_) {},
      ),
      exercise: (WidgetTester tester) async {
        await tester.tap(find.byType(NumberOfCommentsFilterChip));
        await tester.pump(const Duration(milliseconds: 300));
      },
      covers: <String>{
        'lib/screens/search/widgets/number_of_comments_filter_chip.dart#_NumberOfCommentsDialog',
      },
    ),
    GoldenScenario(
      'author_dialog',
      () => PostedByFilterChip(
        filter: const PostedByFilter(author: 'alice'),
        onChanged: (_) {},
      ),
      exercise: (WidgetTester tester) async {
        await tester.tap(find.byType(PostedByFilterChip));
        await tester.pump(const Duration(milliseconds: 300));
      },
      covers: <String>{
        'lib/screens/search/widgets/posted_by_filter_chip.dart#PostedByFilterChip',
      },
    ),
  ]);
}
