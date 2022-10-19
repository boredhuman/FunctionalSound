import 'dart:html';
import 'dart:web_audio';
import 'package:js/js_util.dart' as reflection;
import '../expression/compiler.dart';
import '../expression/expression_parser.dart';
import '../util/util.dart';

class AudioManager {
  AudioContext context = AudioContext();
  ExpressionParser parser = ExpressionParser();
  late MessagePort vmPort;
  int playStart = -1;
  // pausetime is equal to the last pause or -1 if its not paused
  int pauseTime = -1;
  int totalPlayTime = 0;
  String? currentExpression;
  bool initialized = false;

  Future init() async {
    if (initialized) {
      return;
    }
    Future addModuleFuture = promiseToFuture(reflection.callMethod(reflection.getProperty(context, 'audioWorklet'), 'addModule', ['sound/engine_wasm.js']));

    var request = await HttpRequest.request('sound/audioVM.wasm', responseType: 'arraybuffer', mimeType: 'application/wasm');
    var audioVM = request.response;

    await addModuleFuture; // Wait for addModule to finish

    var node = AudioWorkletNode(context, "engine");
    node.connectNode(context.destination as AudioNode);

    vmPort = reflection.getProperty(node, "port");
    vmPort.postMessage(audioVM); // Send WASM bytes to audio worklet
    consoleLog("initialized audiomanager");
    initialized = true;
  }

  // returns true if instructions is set to audio vm aka something is going to be played
  bool setExpression(String expression) {
    if (!initialized) {
      return false;
    }
    if (currentExpression == expression) {
      return true;
    }
    print("Setting expression $expression");
    try {
      currentExpression = expression;
      List<Instruction>? instructions = parser.parse(expression);
      if (instructions != null) {
        var data = parser.toVMFormat(instructions, {});
        print("posting message to vm");
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
    if (!initialized) {
      return;
    }
    playStart = DateTime.now().millisecondsSinceEpoch;
    vmPort.postMessage([1]);
    totalPlayTime = 0;
  }

  void setPlaying(bool playing) {
    if (!initialized) {
      return;
    }

    if (context.state == "running" && !playing) {
      context.suspend();
      pauseTime = DateTime.now().millisecondsSinceEpoch;
      totalPlayTime += pauseTime - playStart;
    } else if (context.state == "suspended" && playing) {
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
