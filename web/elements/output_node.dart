import 'dart:html';

class OutputNode {

  static DivElement create(int left, int top) {
    return DivElement()
      ..classes.add("node")
      ..id = "output"
      ..style.setProperty("width", "150px")
      ..style.setProperty("left", "${left}px")
      ..style.setProperty("top", "${top}px")
      ..children.addAll([
        DivElement()..classes.add("header"),
        DivElement()
          ..classes.add("input-row")
          ..style.setProperty("transform", "translate(-10px, 0)")
          ..children.addAll([
            DivElement()..classes.addAll(["joint", "input-joint"]),
            DivElement()
              ..style.setProperty("min-width", "140px")
              ..children.add(DivElement()
                ..classes.addAll(["row", "input-row"])
                ..style.setProperty("justify-content", "center")
                ..children.add(ParagraphElement()
                  ..text = "Output"
                  ..style.setProperty("margin", "0")
                  ..classes.add("text")
                  ..style.setProperty("text-align", "center")))
          ])
      ]);
  }
}
