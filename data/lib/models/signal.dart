import 'dart:convert';
import 'dart:io';

class Chatter {
  Chatter(this.socket);

  String name = "anonymous";
  WebSocket socket;
}

class Signal {
  Sink<dynamic> broadcastSink;
  Codec? messageCodec;
  List<Chatter> chatters = [];

  Signal(this.broadcastSink) {
    var json = JsonCodec();
    var utf8 = Utf8Codec();
    messageCodec = json.fuse(utf8);
  }

  void add(WebSocket socket) {
    var chatter = Chatter(socket);
    socket.listen((message) {
      var payload = messageCodec?.decode(message);
      handleMessage(payload, from: chatter);
    }, cancelOnError: true);

    chatters.add(chatter);
    socket.done.then((_) {
      chatters.remove(chatter);
    });
  }

  void handleMessage(Map<String, dynamic> payload, {Chatter? from}) {
    var event = payload["event"];
    switch (event) {
      case "name":
        {
          from?.name = payload["data"] ?? "anonymous";
          from?.socket.add(
              messageCodec?.encode({"event": "name_ack", "data": from.name}));
        }
        break;

      case "message":
        {
          sendMessage(payload["data"], from: from);
        }
        break;

      default:
        {
          from?.socket.add(messageCodec
              ?.encode({"event": "error", "data": "unknown command '$event'"}));
        }
    }
  }

  void sendMessage(String message, {Chatter? from}) {
    var bytes = messageCodec?.encode(
        {"event": "message", "data": "${from?.name ?? "global"}: $message"});
    sendBytesToAllConnections(bytes);
    sendBytesToOtherIsolates(bytes);
  }

  void sendBytesToAllConnections(List<int> bytes) {
    for (var chatter in chatters) {
      chatter.socket.add(bytes);
    }
  }

  void sendBytesToOtherIsolates(List<int> bytes) {
    broadcastSink.add({"event": "broadcast", "data": bytes});
  }
}
