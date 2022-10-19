import 'dart:html';
import 'dart:svg';

class TimeNode {

  static DivElement create(int left, int top) {
    return DivElement()
      ..classes.add("node")
      ..id = "time"
      ..style.setProperty("width", "150px")
      ..style.setProperty("left", "${left}px")
      ..style.setProperty("top", "${top}px")
      ..children.addAll([
        DivElement()..classes.add("header"),
        DivElement()
          ..classes.add("input-row")
          ..children.addAll([
            DivElement()
              ..style.setProperty("min-width", "140px")
              ..children.addAll([
                DivElement()
                  ..classes.addAll(["row", "input-row"])
                  ..style.setProperty("justify-content", "center")
                  ..children.add(ParagraphElement()
                    ..text = "Time"
                    ..classes.add("text")
                    ..style.setProperty("text-align", "center")),
                DivElement()
                  ..classes.addAll(["row", "input-row"])
                  ..style.setProperty("justify-content", "center")
                  ..children.add(ParagraphElement()
                    ..classes.add("text")
                    ..text = "0.00"),
                DivElement()
                  ..classes.addAll(["row", "input-row"])
                  ..style.setProperty("justify-content", "center")
                  ..children.addAll([
                    // play button
                    SvgSvgElement()
                      ..id = "pausePlay"
                      ..setAttribute("playing", false)
                      ..style.setProperty("width", "20px")
                      ..style.setProperty("height", "20px")
                      ..children.addAll([
                        PolygonElement()
                          ..setAttribute("points", "0,0 0,20 20,10")
                          ..style.setProperty("fill", "white")
                      ]),
                    // spacer
                    ParagraphElement()
                      ..classes.add("text")
                      ..style.setProperty("min-width", "10px"),
                    // reset button
                    DivElement()
                      ..id = "resetButton"
                      ..style.setProperty("background-color", "white")
                      ..style.setProperty("min-width", "20px")
                      ..style.setProperty("min-height", "20px")
                  ])
              ]),
            DivElement()..classes.addAll(["joint", "output-joint"])
          ])
      ]);
  }
}