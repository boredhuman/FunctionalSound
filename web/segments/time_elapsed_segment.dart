import '../main.dart';
import 'label_segment.dart';
import 'render_listener.dart';

class TimeElapsedSegment extends LabelSegment {
  TimeElapsedSegment() : super("0.00", mutableName: false) {
    addListener(RenderListener((segment) {
      if (audioManager.playStart == -1) {
        return false;
      }
      text = (audioManager.getRenderTime() / 1000).abs().toStringAsFixed(2);
      return false;
    }));
  }

  static TimeElapsedSegment fromMap(Map data) {
    TimeElapsedSegment timeElapsedSegment = TimeElapsedSegment();
    LabelSegment.applyMapData(timeElapsedSegment, data);
    return timeElapsedSegment;
  }
}