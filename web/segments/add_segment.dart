import 'dart:html';

import '../render/render_util.dart';
import "../main.dart";
import '../util/util.dart';
import 'expression_segment.dart';
import 'input_segment.dart';
import 'segment.dart';

class AddSegment extends Segment {
  bool forExpressionSegment = true;

  AddSegment({this.forExpressionSegment = true}) : super(50);

  @override
  render() {
    super.render();

    if (forExpressionSegment) {
      int color = overCross(x + width ~/ 2, y + height ~/ 2, 30) ? 0xFF0000FF : 0xFFFFFFFF;
      drawRoundedCross(x + width ~/ 2, y + height ~/ 2, 30, color);
    } else {
      int color = overCross(x + 20, y + height ~/ 2, 21) ? 0xFF0000FF : 0xFFFFFFFF;
      // left cross
      drawRoundedCross(x + 20, y + height ~/ 2, 21, color);
      int bottomPad = (height - 32) ~/ 2;
      drawString("Add Input", x + 40, y + bottomPad, 0xFFFFFFFF);
    }
  }

  bool over() {
    return overCross(x + width ~/ 2, y + height ~/ 2, 30);
  }

  @override
  bool handleEvent(Event event) {
    super.handleEvent(event);
    if (event is MouseEvent) {
      if (handleMouseEvent(event)) {
        return true;
      }
    }
    return false;
  }

  bool handleMouseEvent(MouseEvent event) {
    if (over() && forExpressionSegment) {
      parent!.removeSegment(this);
      parent!.addQueue.add(ExpressionSegment());
      parent!.addQueue.add(AddSegment(forExpressionSegment: false));
      print('Consuming click');
      return true;
    }

    bool overLeftCross = overCross(x + 20, y + height ~/ 2, 21);
    if (overLeftCross && !forExpressionSegment) {
      parent!.removeSegment(this);
      int index = 0;
      for (Segment segment in parent!.segments) {
        if (segment is InputSegment) {
          index++;
        }
      }
      parent!.addQueue.add(InputSegment(index));
      parent!.addQueue.add(this);

      return true;
    }
    return false;
  }

  static AddSegment fromMap(Map data) {
    return AddSegment(forExpressionSegment: data["forExpressionSegment"]);
  }

  @override
  Map toMap() {
    return {"forExpressionSegment" : forExpressionSegment};
  }
}
