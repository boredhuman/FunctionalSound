import 'dart:html';
import 'dart:web_audio';
import 'package:js/js_util.dart' as reflection;
import '../expression/expression_parser.dart';
import '../util/util.dart';

class AudioManager {
  AudioContext context = AudioContext();
  ExpressionParser parser = ExpressionParser();
  late MessagePort vmPort;

  void init() async {
    reflection.callMethod(reflection.getProperty(context, 'audioWorklet'), 'addModule', ['sound/engine_wasm.js']);

    var request = await HttpRequest.request('sound/audioVM.wasm', responseType: 'arraybuffer', mimeType: 'application/wasm');
    var audioVM = request.response;

    await Future.delayed(Duration(seconds: 3)); // Wait for addModule to finish

    var node = AudioWorkletNode(context, "engine");
    node.connectNode(context.destination as AudioNode);

    vmPort = reflection.getProperty(node, "port");
    vmPort.postMessage(audioVM); // Send WASM bytes to audio worklet
  }

  void setExpression(String expression) {
    consoleLog("Playing " + expression);
    var data = parser.toVMFormat(parser.parse(expression), {});
    vmPort.postMessage(data);
  }

  void cycle() {
    if (context.state == "running") {
      context.suspend();
    } else if (context.state == "suspended") {
      context.resume();
    }
  }
}
