import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/vehicle.dart';
import '../providers/app_providers.dart';

/// The active vehicle's name, which doubles as the switcher when there is more
/// than one vehicle to switch between. The switcher opens as a menu anchored to
/// the name itself, not a bottom sheet: the finger is already at the top of the
/// screen, so the choices should appear under it instead of across the display
/// where the hand covers them on the way down.
///
/// [compact] sizes the name to sit beside a screen title rather than stand as
/// one, for the tabs that already carry their own heading.
class VehicleSwitcher extends ConsumerWidget {
  const VehicleSwitcher({
    super.key,
    required this.vehicle,
    this.compact = false,
  });

  final Vehicle vehicle;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final vehicles = ref.watch(vehicleListProvider).value ?? const <Vehicle>[];
    final hasMany = vehicles.length > 1;
    return MenuAnchor(
      menuChildren: [
        for (final option in vehicles)
          MenuItemButton(
            leadingIcon: const Icon(Icons.directions_car),
            trailingIcon: option.id == vehicle.id
                ? const Icon(Icons.check)
                : null,
            onPressed: () =>
                ref.read(activeVehicleIdProvider.notifier).select(option.id),
            child: Text(option.name),
          ),
      ],
      builder: (context, controller, _) {
        final trigger = InkWell(
          onTap: hasMany
              ? () => controller.isOpen ? controller.close() : controller.open()
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  vehicle.name,
                  style: compact
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.headlineMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasMany)
                Icon(
                  Icons.keyboard_arrow_down,
                  size: compact ? 20 : 28,
                  color: theme.colorScheme.onSurface,
                ),
            ],
          ),
        );
        // With one vehicle the name is just a heading; with more it becomes
        // the switcher, so it reads as one button carrying the name and the
        // switch hint rather than a bare label and a stray chevron.
        if (!hasMany) return trigger;
        return MergeSemantics(
          child: Semantics(
            button: true,
            hint: 'Switch vehicle',
            child: trigger,
          ),
        );
      },
    );
  }
}
