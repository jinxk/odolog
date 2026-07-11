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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
      ),
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
