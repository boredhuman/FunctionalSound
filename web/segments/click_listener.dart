import 'dart:html';

import 'listener.dart';
import 'segment.dart';

class ClickListener<T extends Segment> implements Listener<T> {

  void Function(T segment) onClick;

  ClickListener(this.onClick);

  @override
  bool onEvent(Event? event, T segment) {
    if (segment.isOver()) {
      onClick(segment);
      return true;
    }
    return false;
  }

  @override
  List<String> getEventTypes() {
    return ["click"];
  }
}