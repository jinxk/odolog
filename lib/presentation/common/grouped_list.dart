import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/shapes.dart';

/// An inset grouped list container: one rounded surface holding several rows,
/// each separated by a hairline that starts past the leading icon rather than
/// running edge to edge.
class GroupedList extends StatelessWidget {
  const GroupedList({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final hairline = Theme.of(context).extension<AppColorRoles>()?.hairline;
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(AppShapes.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 56, endIndent: 16, color: hairline),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// The sliver form of [GroupedList] for long lists: same surface and dividers,
/// but rows are built only as they scroll into view.
class GroupedSliverList extends StatelessWidget {
  const GroupedSliverList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final hairline = Theme.of(context).extension<AppColorRoles>()?.hairline;
    const corner = Radius.circular(AppShapes.cardRadius);
    return DecoratedSliver(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
      ),
      sliver: SliverList.separated(
        itemCount: itemCount,
        // The card colour is painted by the decoration above, so a row's ink
        // needs its own Material on top of it. The first and last rows are
        // clipped to the card's corners.
        itemBuilder: (context, i) {
          final row = Material(
            type: MaterialType.transparency,
            child: itemBuilder(context, i),
          );
          final first = i == 0;
          final last = i == itemCount - 1;
          if (!first && !last) return row;
          return ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: first ? corner : Radius.zero,
              bottom: last ? corner : Radius.zero,
            ),
            child: row,
          );
        },
        separatorBuilder: (context, index) =>
            Divider(height: 1, indent: 56, endIndent: 16, color: hairline),
      ),
    );
  }
}
