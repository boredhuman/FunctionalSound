import 'dart:html';

import '../main.dart';
import '../render/render_util.dart';
import 'segment.dart';
import 'segment_factory.dart';

class Node {
  List<Segment> segments = [];
  // offset from the left side of the screen
  int x;
  // offset from the bottom of the screen
  int y;
  int width;
  int height = 0;
  bool dragging = false;
  int lastMouseX = 0;
  int lastMouseY = 0;
  bool renderOutput;
  bool renderInput;
  List<Segment> addQueue = [];
  Node? input;

  // almost everything has an output apart from the final output node
  Node(this.x, this.y, this.width, {this.renderOutput = true, this.renderInput = false});

  bool inHeader() {
    int xPos = uiManager.lastMouseX;
    int yPos = uiManager.getMouseY();
    return xPos > x && yPos > y + height - 7 && xPos < x + width && yPos < y + height;
  }

  bool isOverNode() {
    int xPos = uiManager.lastMouseX;
    int yPos = uiManager.getMouseY();
    bool overNode = xPos > x && yPos > y && xPos < x + width && yPos < y + height;

    // for (Segment segment in segments) {
    //   if (segment.isOver()) {
    //     overNode = true;
    //     break;
    //   }
    // }
    return overNode;
  }

  void render(int mouseX, int mouseY) {
    if (dragging) {
      int xDelta = lastMouseX - mouseX;
      int yDelta = lastMouseY - mouseY;
      x -= xDelta;
      y -= yDelta;
      lastMouseX = mouseX;
      lastMouseY = mouseY;
    }
    // background
    drawQuadColor(x, y + height, x + width, y, 0x333333FF, null, null, null, 6, 1, inHeader() || dragging ? 0xFF0000FF : 0xFFFFFFFF);

    // should only be used for time and output
    if (renderInput) {
      int color = clickedInputNode() ? 0xFF0000FF : 0xFFFFFFFF;
      if (uiManager.selectedNode != null && this == uiManager.selectedNode) {
        color = 0x00FF00FF;
      }
      drawCircle(x, y + height ~/ 2, 10, color);

    }

    if (renderOutput) {
      int color = clickedOutputNode() ? 0xFF0000FF : 0xFFFFFFFF;
      if (uiManager.selectedNode != null && this == uiManager.selectedNode) {
        color = 0x00FF00FF;
      }
      drawCircle(x + width, y + height ~/ 2, 10, color);
    }
    //renderQuad(x, y + height, x + width, y, 0xFF0000FF, globalProjectionMatrix);

    renderSegments();
    renderConnection();
  }

  bool inRadius(int x, int y, int radius) {
    int mouseY = uiManager.getMouseY();
    int xDif = (x - uiManager.lastMouseX).abs();
    int yDif = (y - mouseY).abs();
    // avoiding use sqrt
    int distanceSq = xDif * xDif + yDif * yDif;
    return distanceSq < radius * radius;
  }

  void renderSegments() {
    int yOffset = y;
    for (int i = segments.length - 1; i > -1; i--) {
      Segment segment = segments[i];

      segment.x = x;
      segment.y = yOffset;
      segment.width = width;
      segment.render();
      yOffset += segment.height;
    }

    for (Segment segment in addQueue) {
      addSegment(segment);
    }

    addQueue.clear();
  }

  void renderConnection() {
    if (input != null) {
      drawLine(x, y + height ~/ 2, input!.x + input!.width, input!.y + input!.height ~/ 2, 0xFF0000FF, lineWidth: 5);
    }
  }

  void removeSegment(Segment segment) {
    segments.remove(segment);
    height -= segment.height;
  }

  void addSegment(Segment segment) {
    segment.parent = this;
    segments.add(segment);
    height += segment.height;
  }

  bool handleEvent(Event event) {
    if (event is MouseEvent) {
      if (handleMouseEvent(event)) {
        return true;
      }
    }

    for (Segment segment in segments) {
      if (segment.handleEvent(event)) {
        return true;
      }
    }

    return false;
  }

  bool clickedInputNode() {
    if (!renderInput) {
      return false;
    }
    return inRadius(x, y + height ~/ 2, 10);
  }

  bool clickedOutputNode() {
    if (!renderOutput) {
      return false;
    }
    return inRadius(x + width, y + height ~/ 2, 10);
  }

  bool handleMouseDown(MouseEvent event) {
    if (inHeader()) {
      dragging = true;
      lastMouseX = uiManager.lastMouseX;
      lastMouseY = uiManager.getMouseY();
      return true;
    }
    return false;
  }

  void handleMouseUp(MouseEvent event) {
    dragging = false;
  }

  // return true to stop it passing event to segments
  bool handleMouseEvent(MouseEvent mouseEvent) {
    return false;
  }

  static Node fromMap(Map data) {
    Node node = Node(data["x"], data["y"], data["width"], renderOutput: data["renderOutput"], renderInput: data["renderInput"]);
    List<dynamic> segmentMaps = data["segments"];
    for (dynamic segmentMap in segmentMaps) {
      String segmentType = segmentMap["type"];
      Segment Function(Map data) factory = SegmentFactory.segmentFactories[segmentType]!;
      Segment segment = factory(segmentMap);
      node.addSegment(segment);
    }
    return node;
  }

  Map<String, Object> toMap() {
    List<Map> segmentMaps = [];

    for (Segment segment in segments) {
      Map segmentMap = segment.toMap();
      segmentMap["type"] = segment.runtimeType.toString();
      segmentMaps.add(segmentMap);
    }

    return {
      "x" : x,
      "y" : y,
      "width" : width,
      "renderOutput" : renderOutput,
      "renderInput" : renderInput,
      "segments" : segmentMaps,
      "inputIndex": input == null ? -1 : uiManager.elements.indexOf(input!)
    };
  }
}
