import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';
import 'package:data/utils/app_env.dart';

import 'controllers/app_websocket_controller.dart';
import 'models/signal.dart';

class AppService extends ApplicationChannel {
  late final ManagedContext managedContext;
  late final Signal signal;

  @override
  Future prepare() {
    logger.onRecord.listen((rec) {
      print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}");
    });
    signal = Signal(messageHub);
    final persistentStore = _initDatabase();
    managedContext = ManagedContext(
        ManagedDataModel.fromCurrentMirrorSystem(), persistentStore);

    messageHub.listen((event) {
      Map<String, dynamic> message = event;

      switch (message["event"]) {
        case "broadcast":
          signal.sendBytesToAllConnections(message["data"]);
      }
    });
    return super.prepare();
  }

  @override
  Controller get entryPoint => Router()
    // ..route("room")
    //     .link(() => AppTokenController())!
    //     .link(() => AppRoomController(managedContext))
    ..route("signal").link(() => AppWebsocketController(signal));

  PostgreSQLPersistentStore _initDatabase() {
    return PostgreSQLPersistentStore(
      AppEnv.dbUsername,
      AppEnv.dbPassword,
      AppEnv.dbHost,
      int.tryParse(AppEnv.dbPort),
      AppEnv.dbDatabaseName,
    );
  }
}
