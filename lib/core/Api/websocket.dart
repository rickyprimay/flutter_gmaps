import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';

WebSocketChannel connectToWebSocket() {
  WebSocketChannel channel = WebSocketChannel.connect(
    Uri.parse('wss://vehiloc.net/sub-split/7766989'),
  );
  return channel;
}

void main() {
  WebSocketChannel channel = connectToWebSocket();
  final Logger logger = Logger();

  channel.sink.add('Hello, WebSocket!');

  channel.stream.listen(
    (message) {
      logger.i('Received: $message');
    },
    onError: (error) {
      logger.i('Error: $error');
    },
    onDone: () {
      logger.i('WebSocket closed');
    },
  );
}
