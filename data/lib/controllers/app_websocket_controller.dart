import 'dart:async';
import 'dart:io';

import 'package:conduit_core/conduit_core.dart';

import '../models/signal.dart';

class AppWebsocketController extends Controller {
  final Signal signal;

  AppWebsocketController(this.signal);
  @override
  Future<RequestOrResponse?> handle(Request request) async {
    final websocket = await WebSocketTransformer.upgrade(request.raw);
    signal.add(websocket);

    return null;
  }
}
