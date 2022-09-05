import 'dart:html';

import 'listener.dart';
import '../main.dart';
import 'nodes.dart';

abstract class Segment {
  int height;
  int x = 0;
  int y = 0;
  int width = 0;
  Node? parent;
  Map<String, List<Listener>> eventListeners = {};

  bool inElement(int xPos, int yPos) {
    return xPos > x && yPos > y && xPos < x + width && yPos < y + height;
  }

  Segment(this.height);

  void render() {
    handleEventInternal(null);
  }

  bool handleEvent(Event event) {
    return handleEventInternal(event);
  }

  // return true to prevent passing event
  bool handleEventInternal(Event? event) {
    var listeners = eventListeners[event != null ? event.type : "render"];
    if (listeners != null) {
      for (var listener in listeners) {
        if (listener.onEvent(event, this)) {
          return true;
        }
      }
    }
    return false;
  }

  void addListener(Listener listener) {
    for (String eventType in listener.getEventTypes()) {
      List<Listener>? listeners = eventListeners[eventType];
      if (listeners == null) {
        listeners = [listener];
        eventListeners[eventType] = listeners;
      } else {
        listeners.add(listener);
      }
    }
  }

  void removeListener(Listener listener) {
    for (String eventType in listener.getEventTypes()) {
      eventListeners[eventType]?.remove(listener);
    }
  }

  void setDimensions({x, y, width, height}) {
    this.x = x ?? this.x;
    this.y = y ?? this.y;
    this.width = width ?? this.width;
    this.height = height ?? this.height;
  }

  bool isOver() {
    return uiManager.getMouseX() > x && uiManager.getMouseX() < x + width && uiManager.getMouseY() > y && uiManager.getMouseY() < y + height;
  }

  Map toMap();
}
