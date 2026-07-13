import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/vehicle.dart';
import '../common/empty_state.dart';
import '../common/formatting.dart';
import '../providers/app_providers.dart';
import '../providers/auto_backup_provider.dart';
import '../providers/usecases.dart';

/// Vehicle management: the list with add, edit, and delete. Deleting warns that
/// the vehicle's refuel history goes with it.
class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehicleListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicles')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vehicles/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: vehicles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.directions_car_outlined,
              title: 'No vehicles yet',
              message: 'Add a vehicle to start logging fills.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final vehicle = list[index];
              return ListTile(
                leading: const Icon(Icons.directions_car),
                title: Text(vehicle.name),
                subtitle: Text(
                  '${vehicleTypeLabel(vehicle.type)}, '
                  '${fuelCategoryLabel(vehicle.fuelCategory)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => context.push(
                        '/vehicles/${vehicle.id}/edit',
                        extra: vehicle,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(context, ref, vehicle),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Vehicle vehicle,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${vehicle.name}?'),
        content: const Text(
          'This also deletes all of its refuel history. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(deleteVehicleProvider).execute(vehicle.id);
    if (ref.read(activeVehicleIdProvider) == vehicle.id) {
      ref.read(activeVehicleIdProvider.notifier).select(null);
    }
    ref.invalidate(vehicleListProvider);
    unawaited(ref.read(autoBackupProvider.notifier).runIfDue());
  }
}
