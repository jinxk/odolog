import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'data/db/app_database.dart';
import 'presentation/providers/repositories.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The app's own MIT licence, shown on the licence page ahead of the
  // package notices Flutter bundles on its own.
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('LICENSE');
    yield LicenseEntryWithLineBreaks(const ['OdoLog'], text);
  });
  final database = await AppDatabase.open();
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: const OdoLogApp(),
    ),
  );
}
