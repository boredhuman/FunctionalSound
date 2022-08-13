import 'dart:html';

import 'listener.dart';
import 'segment.dart';

class RenderListener<T extends Segment> implements Listener<T> {

  bool? Function(T segment) onRender;

  RenderListener(this.onRender);

  @override
  bool onEvent(Event? event, T segment) {
    bool? cancelPropagate = onRender(segment);
    return cancelPropagate ?? false;
  }

  @override
  List<String> getEventTypes() {
    return ["render"];
  }
}