import 'dart:html';

import 'listener.dart';
import 'segment.dart';

class DynamicListener<T extends Segment> implements Listener<T> {

  List<String> eventTypes;
  bool Function(Event? event, T segment) onEventDelegate;

  DynamicListener(this.eventTypes, this.onEventDelegate);

  @override
  bool onEvent(Event? event, T segment) {
    return onEventDelegate(event, segment);
  }

  @override
  List<String> getEventTypes() {
    return eventTypes;
  }

}