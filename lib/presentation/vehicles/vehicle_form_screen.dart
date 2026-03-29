import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/vehicle.dart';
import 'vehicle_form.dart';

/// Add or edit a vehicle from vehicle management. Reuses [VehicleForm].
class VehicleFormScreen extends ConsumerWidget {
  const VehicleFormScreen({super.key, this.initial});

  final Vehicle? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEdit = initial != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit vehicle' : 'Add vehicle')),
      body: VehicleForm(
        initial: initial,
        saveLabel: isEdit ? 'Save changes' : 'Add vehicle',
        onSaved: (_) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/vehicles');
          }
        },
      ),
    );
  }
}
