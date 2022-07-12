import 'dart:math';
import 'dart:web_gl';

import '../render/render_util.dart';
import "../main.dart";
import "dart:html";

import 'segment.dart';

enum Alignment {
  left,
  center,
  right;
}

class LabelSegment extends Segment {
  Alignment alignment = Alignment.center;
  int textColor = 0xFFFFFFFF;
  String text;
  bool mutableName = false;
  bool selected = false;
  // when caret is at end of text its equal to 0,
  int caretPosition = 0;
  // push text away from left
  int leftPad = 0;
  int minTextLength = 0;

  LabelSegment(this.text) : super(50);

  @override
  render() {
    // hide overflow
    gl.enable(WebGL.SCISSOR_TEST);
    gl.scissor(x, y, width, height);

    int bottomPad = (height - 32) ~/ 2;
    int renderY = y + bottomPad;
    int stringWidth = getStringWidth();
    int textStart = getTextStart(stringWidth);

    switch (alignment) {
      case Alignment.left:
        drawString(text, textStart, renderY, textColor);
        break;
      case Alignment.center:
        drawString(text, textStart, renderY, textColor);
        break;
      default:
        drawString(text, textStart, renderY, textColor);
        break;
    }

    if (inputSegment) {
      drawCircle(x + width - 2, renderY + height ~/ 2 - (height ~/ 8), height ~/ 4, 0x444444FF);
    }

    if (selected) {
      if (DateTime.now().millisecondsSinceEpoch % 1000 > 500) {
        drawCaret(textStart);
      }
    }

    gl.disable(WebGL.SCISSOR_TEST);
  }

  int getTextStart(int strWidth) {
    int textStart = leftPad;

    int overflow = 0;

    if (strWidth > width) {
      overflow = strWidth - width;
      textStart -= 3; // space for caret
    }

    switch(alignment) {
      case Alignment.left:
        textStart -= overflow;
        textStart += x;
        break;
      case Alignment.center:
        textStart -= overflow ~/ 2;
        textStart += x + (width ~/ 2) - (strWidth ~/ 2);
        break;
      default:
        textStart += x + width - strWidth;
        break;
    }
    return textStart;
  }

  int getStringWidth() {
    return fontRenderer!.getStringWidth(text);
  }

  drawCaret(int textStart) {
    int textWidth = fontRenderer!.getStringWidth(text.substring(0, max(0, text.length - caretPosition)));
    drawQuad(textStart + textWidth, y + 40, textStart + textWidth + 1, y + 8, 0xFFFFFFFF);
  }

  @override
  bool handleEvent(Event event) {
    if (event is MouseEvent) {
      handleMouse(event);
    }
    if (event is KeyboardEvent) {
      handleKeyboard(event);
    }
    return false;
  }

  handleMouse(MouseEvent event) {
    int mouseX = event.client.x.toInt();
    int mouseY = uiManager.clientHeight - event.client.y.toInt();

    selected = inElement(mouseX, mouseY);
    int stringWidth = getStringWidth();
    int textStart = getTextStart(stringWidth);

    // too far to the right place caret at end
    if (mouseX > textStart + stringWidth) {
      caretPosition = 0;
      // too far to the left place caret at beginning
    } else if (mouseX < textStart) {
      caretPosition = text.length;
    } else {
      
      int i = 0;
      int totalWidth = 0;
      for (int letter in text.codeUnits) {
        int width = fontRenderer!.getLetterWidth(letter);
        totalWidth += i == 0 ? width ~/ 2 : width;
        if (mouseX < totalWidth + textStart) {
          caretPosition = text.length - i;
          break;
        }
        i++;
      }
    }
  }

  handleKeyboard(KeyboardEvent event) {
    if (!selected) {
      return;
    }

    if (event.keyCode == 8) {
      if (text.isEmpty) {
        return;
      }
      if (text.length == minTextLength) {
        return;
      }
      // when caret is at the end we can just remove the final letter
      // otherwise split the string into two, make the left shorter
      if (caretPosition == 0) {
        text = text.substring(0, text.length - 1);
      } else {
        String left = text.substring(0, max(0, text.length - caretPosition));
        String right = text.substring(text.length - caretPosition, text.length);
        if (left.isNotEmpty) {
          left = text.substring(0, left.length - 1);
        }
        text = left + right;
      }
    } else {
      // move caret left
      if (event.key == "ArrowLeft") {
        caretPosition = min(text.length, caretPosition + 1);
        // move caret right
      } else if (event.key == "ArrowRight") {
        caretPosition = max(caretPosition - 1, 0);
      } else {
        // when caret is 0 aka at the end we can just append the letter otherwise split, append to the left and rejoin
        // caret == text.length caret is at the beginning of the string so just append the letter with text
        if (event.key != null) {
          if (caretPosition == 0) {
            text += event.key!;
          } else if (caretPosition == text.length) {
            text = event.key! + text;
          } else {
            String left = text.substring(0, max(0, text.length - caretPosition));
            String right = text.substring(text.length - caretPosition, text.length);
            text = left + event.key! + right;
          }
        }
      }
      // dont allow caret to move into min text
      if (minTextLength != 0) {
        int maxCaret = text.length - minTextLength;
        caretPosition = min(maxCaret, caretPosition);
      }
    }
  }
}