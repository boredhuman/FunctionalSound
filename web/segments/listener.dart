import 'dart:html';

import 'segment.dart';

abstract class Listener<T extends Segment> {
  // event will be null if render type
  // return true to prevent event from propagating
  bool onEvent(Event? event, T segment);
  List<String> getEventTypes();
}