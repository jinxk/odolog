import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/catalog/catalog_loader.dart';
import '../../data/daos/refuel_dao.dart';
import '../../data/daos/vehicle_dao.dart';
import '../../data/reminders/local_notification_scheduler.dart';
import '../../data/repositories/catalog_repository_impl.dart';
import '../../data/repositories/refuel_repository_impl.dart';
import '../../data/repositories/vehicle_repository_impl.dart';
import '../../domain/reminders/reminder_scheduler.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/repositories/refuel_repository.dart';
import '../../domain/repositories/vehicle_repository.dart';

part 'repositories.g.dart';

/// The open database. Overridden with a concrete instance in main() once the
/// file is opened, so every downstream provider stays synchronous. Widget tests
/// override the repository providers directly and never touch this one.
@Riverpod(keepAlive: true)
Database database(Ref ref) {
  throw UnimplementedError('databaseProvider must be overridden in main().');
}

@Riverpod(keepAlive: true)
VehicleRepository vehicleRepository(Ref ref) =>
    VehicleRepositoryImpl(VehicleDao(ref.watch(databaseProvider)));

@Riverpod(keepAlive: true)
RefuelRepository refuelRepository(Ref ref) =>
    RefuelRepositoryImpl(RefuelDao(ref.watch(databaseProvider)));

@Riverpod(keepAlive: true)
CatalogRepository catalogRepository(Ref ref) =>
    CatalogRepositoryImpl(CatalogLoader());

/// The platform notification scheduler. Widget tests can override this with a
/// no-op, though the real one already stands down off Android.
@Riverpod(keepAlive: true)
ReminderScheduler reminderScheduler(Ref ref) => LocalNotificationScheduler();
