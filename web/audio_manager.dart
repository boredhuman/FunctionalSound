import 'dart:math';
import 'dart:typed_data';
import 'dart:web_audio';
import 'package:math_expressions/math_expressions.dart';


class AudioManager {
  AudioContext audioContext;
  AudioManager() : audioContext = AudioContext();

  void playSound(String expression) {
    int time = 5;
    int samplesPerSecond = 44100;
    int bufferSize = time * samplesPerSecond;
    AudioBuffer buffer = audioContext.createBuffer(1, bufferSize, samplesPerSecond);

    Float32List channelBuffer = buffer.getChannelData(0);

    Parser p = Parser();
    Expression exp = p.parse(expression);

    ContextModel contextModel = ContextModel();

    Variable timeVariable = Variable("x");
    Variable piVariable = Variable("pi");
    contextModel.bindVariable(piVariable, Number(pi));

    for (int i = 0; i < bufferSize; i++) {
      var time = i / samplesPerSecond;
      contextModel.bindVariable(timeVariable, Number(time));

      dynamic amplitude = exp.evaluate(EvaluationType.REAL, contextModel);

      channelBuffer[i] = amplitude;
    }

    AudioBufferSourceNode audioBufferSourceNode = audioContext.createBufferSource();

    audioBufferSourceNode.buffer = buffer;

    audioBufferSourceNode.connectNode(audioContext.destination!);

    audioBufferSourceNode.start();
    print("Playing sound");
  }
}