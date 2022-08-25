import 'dart:html';
import 'dart:web_audio';
import 'package:js/js_util.dart' as reflection;
import '../expression/compiler.dart';
import '../expression/expression_parser.dart';

class AudioManager {
  AudioContext context = AudioContext();
  ExpressionParser parser = ExpressionParser();
  late MessagePort vmPort;
  int playStart = -1;
  // pausetime is equal to the last pause or -1 if its not paused
  int pauseTime = -1;
  int totalPlayTime = 0;
  String? currentExpression;

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

  bool setExpression(String expression) {
    if (currentExpression == expression) {
      return true;
    }
    print("Setting expression $expression");
    try {
      currentExpression = expression;
      List<Instruction>? instructions = parser.parse(expression);
      if (instructions != null) {
        var data = parser.toVMFormat(instructions, {});
        vmPort.postMessage(data);
        playStart = DateTime
            .now()
            .millisecondsSinceEpoch;
        return true;
      }
      return false;
    } on Exception {
      return false;
    }
  }

  void resetTime() {
    playStart = DateTime.now().millisecondsSinceEpoch;
    vmPort.postMessage([1]);
    totalPlayTime = 0;
  }

  void cycle() {
    if (context.state == "running") {
      context.suspend();
      pauseTime = DateTime.now().millisecondsSinceEpoch;
      totalPlayTime += pauseTime - playStart;
    } else if (context.state == "suspended") {
      context.resume();
      pauseTime = -1;
      playStart = DateTime.now().millisecondsSinceEpoch;
    }
  }

  int getRenderTime() {
    if (pauseTime != -1) {
      return totalPlayTime;
    } else {
      return totalPlayTime + (DateTime.now().millisecondsSinceEpoch - playStart);
    }
  }
}
