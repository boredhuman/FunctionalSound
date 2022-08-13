import 'label_segment.dart';

class ExpressionSegment extends LabelSegment {
  ExpressionSegment([String? text]) : super(text ?? "sin(i0*2*pi*440)");

  static ExpressionSegment fromMap(Map data) {
    ExpressionSegment expressionSegment = ExpressionSegment(data["text"]);
    LabelSegment.applyMapData(expressionSegment, data);
    return expressionSegment;
  }
}
