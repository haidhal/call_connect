import 'package:call_connect/services/call_kit_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/call_repository.dart';
import '../services/call_event_service.dart';


final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final callRepositoryProvider = Provider<CallRepository>((ref) {
  return CallRepository(ref.watch(appDatabaseProvider));
});

final callEventServiceProvider = Provider<CallEventService>((ref) {
  final service = CallEventService();
  ref.onDispose(service.dispose);
  return service;
});

final callKitServiceProvider = Provider<CallKitService>((ref) {
  return createCallKitService();
});
