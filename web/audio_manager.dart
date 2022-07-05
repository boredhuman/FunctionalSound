import 'dart:html';
import 'dart:math';
import 'dart:typed_data';
import 'dart:web_audio';
import 'package:math_expressions/math_expressions.dart';


class AudioManager {
  AudioContext audioContext;
  late AudioBuffer audioBuffer;
  AudioManager() : audioContext = AudioContext() {
    audioBuffer = audioContext.createBuffer(1, 44100, 44100);
  }
  int sampleOffset = 0;
  late double Function(double time) sampleProvider;

  void playSound(String expression) {
    Parser p = Parser();
    Expression exp = p.parse(expression);

    ContextModel contextModel = ContextModel();

    Variable timeVariable = Variable("x");
    Variable piVariable = Variable("pi");
    contextModel.bindVariable(piVariable, Number(pi));

    sampleProvider = (time) {
      contextModel.bindVariable(timeVariable, Number(time));

      dynamic amplitude = exp.evaluate(EvaluationType.REAL, contextModel);

      return amplitude;
    };

    AudioBufferSourceNode audioBufferSourceNode = audioContext.createBufferSource();

    audioBufferSourceNode.buffer = audioBuffer;

    audioBufferSourceNode.connectNode(audioContext.destination!);

    writeBuffer(44100, 44100);

    audioBufferSourceNode.start();

    audioBufferSourceNode.onEnded.listen((event) {
      onEnd(event);
    });
  }

  void writeBuffer(int samplesPerSecond, int bufferSize) {
    Float32List buffer = audioBuffer.getChannelData(0);
    for (int i = 0; i < bufferSize; i++) {
      double time = (sampleOffset + i) / samplesPerSecond;
      double amp = sampleProvider(time);
      buffer[i] = amp;
    }
    sampleOffset += bufferSize;
  }

  void onEnd(Event event) {
    AudioBufferSourceNode audioBufferSourceNode = audioContext.createBufferSource();

    audioBufferSourceNode.buffer = audioBuffer;

    audioBufferSourceNode.connectNode(audioContext.destination!);

    writeBuffer(44100, 44100);

    audioBufferSourceNode.start();

    audioBufferSourceNode.onEnded.listen((event) {
      onEnd(event);
    });
  }
}