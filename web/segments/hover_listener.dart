import 'dart:html';

import 'listener.dart';
import 'segment.dart';

class HoverListener<T extends Segment> implements Listener<T> {

  Function(T segment)? onHover;
  Function(T segment)? onEnter;
  Function(T segment)? onExit;
  bool over = false;

  HoverListener({this.onHover, this.onEnter, this.onExit});

  @override
  bool onEvent(Event? event, T segment) {
    //print("got event");
    if (!over && segment.isOver()) {
      over = true;
      onEnter?.call(segment);
    }
    if (over && !segment.isOver()) {
      over = false;
      onExit?.call(segment);
    }
    if (segment.isOver()) {
      onHover?.call(segment);
      return true;
    }
    return false;
  }

  @override
  List<String> getEventTypes() {
    return ["render"];
  }
}