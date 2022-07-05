import 'dart:html';

import 'font_atlas.dart';
import '../main.dart';
import '../util/mat4.dart';

class FontRenderer {

  FontTexture fontTexture;

  FontRenderer(this.fontTexture);

  void renderString(String text, int xPos, int yPos, int color) {
    List<int> letters = text.codeUnits;

    int wid = fontTexture.width ~/ 16;
    for (int letter in letters) {
      TextMetrics textMetrics = fontTexture.textMetricsList[letter];
      int letterWidth = textMetrics.width!.toInt();

      int leftU = fontTexture.textBoxes[letter * 4];
      int bottomV = fontTexture.textBoxes[letter * 4 + 1];
      int rightU = leftU + 32;
      int topV = bottomV + 32;

      bufferBuilder.positionI(xPos, yPos).colorI(color).texF(leftU / fontTexture.width, topV / fontTexture.width);
      bufferBuilder.positionI(xPos + wid, yPos).colorI(color).texF(rightU / fontTexture.width, topV / fontTexture.width);
      bufferBuilder.positionI(xPos, yPos + wid).colorI(color).texF(leftU / fontTexture.width, bottomV / fontTexture.width);
      bufferBuilder.positionI(xPos, yPos + wid).colorI(color).texF(leftU / fontTexture.width, bottomV / fontTexture.width);
      bufferBuilder.positionI(xPos + wid, yPos).colorI(color).texF(rightU / fontTexture.width, topV / fontTexture.width);
      bufferBuilder.positionI(xPos + wid, yPos + wid).colorI(color).texF(rightU / fontTexture.width, bottomV / fontTexture.width);

      xPos += letterWidth + 1;
    }
  }

  int getStringWidth(String text) {
    List<int> letters = text.codeUnits;
    int totalWidth = 0;
    for (int i = 0; i < letters.length; i++) {
      int letter = letters[i];
      int letterWidth = fontTexture.textMetricsList[letter].width!.toInt();
      totalWidth += letterWidth + 1;
    }
    return totalWidth;
  }

  int getLetterWidth(int letter) {
    return fontTexture.textMetricsList[letter].width!.toInt() + 1;
  }
}