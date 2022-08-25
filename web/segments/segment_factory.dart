import 'add_segment.dart';
import 'expression_segment.dart';
import 'input_segment.dart';
import 'label_segment.dart';
import 'segment.dart';
import 'time_elapsed_segment.dart';
import 'time_segment.dart';

class SegmentFactory {
  static final Map<String, Segment Function(Map data)> segmentFactories = {
    "AddSegment" : ((data) {return AddSegment.fromMap(data);}),
    "ExpressionSegment" : ((data) {return ExpressionSegment.fromMap(data);}),
    "InputSegment" : ((data) {return InputSegment.fromMap(data);}),
    "LabelSegment" : ((data) {return LabelSegment.fromMap(data);}),
    "TimeSegment" : ((data) {return TimeSegment.fromMap(data);}),
    "TimeElapsedSegment" : ((data) {return TimeElapsedSegment.fromMap(data);})
  };
}