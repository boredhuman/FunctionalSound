import 'dart:convert';
import 'dart:html';

import '../main.dart';
import '../segments/input_segment.dart';
import '../segments/nodes.dart';
import '../segments/segment.dart';

class SaveLoad {
  static void save() {
    Map<String, Map<String, Object>> data = uiManager.elements.asMap().map((key, value) => MapEntry(key.toString(), value.toMap()));
    String json = jsonEncode(data);
    Blob blob = Blob([json], "text/csv");
    Element element = window.document.createElement("a");
    element.setAttribute("href", Url.createObjectUrl(blob));
    element.setAttribute("download", "synth.json");
    document.body?.append(element);
    element.click();
    element.remove();
  }

  static void load(String json) {
    final map = jsonDecode(json) as Map;

    uiManager.elements.clear();
    for (dynamic element in map.keys) {
      Node node = Node.fromMap(map[element]);
      uiManager.elements.add(node);
    }

    // connect the nodes
    for (int i = 0; i < uiManager.elements.length; i++) {
      Node node = uiManager.elements[i];
      int inputIndex = map[i.toString()]["inputIndex"];
      if (inputIndex != -1) {
        node.input = uiManager.elements[inputIndex];
      }

      for (int j = 0; j < node.segments.length; j++) {
        Segment segment = node.segments[j];
        if (segment is InputSegment) {
          inputIndex = map[i.toString()]["segments"][j]["inputIndex"];

          if (inputIndex != -1) {
            segment.input = uiManager.elements[inputIndex];
          }
        }
      }
    }

    uiManager.timeNode = uiManager.elements[0];
    uiManager.outputNode = uiManager.elements[1];
  }
}
