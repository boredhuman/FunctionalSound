import 'dart:html';
import 'dart:svg';

import 'delete.dart';
import '../main.dart';

class ExpressionNode {
  
  static DivElement createAddRow(List<String> svgClasses, String text) {
    return DivElement()
      ..classes.addAll(["row", "input-row"])
      ..style.setProperty("justify-content", "center")
      ..children.addAll([
      SvgSvgElement()
        ..classes.addAll(svgClasses)
        ..style.setProperty("width", "20px")
        ..style.setProperty("height", "20px")
        ..children.addAll([
          RectElement()
            ..setAttribute("x", "7.5")
            ..setAttribute("y", "0")
            ..setAttribute("width", "5")
            ..setAttribute("height", "20")
            ..setAttribute("rx", "2")
            ..style.setProperty("fill", "white"),
          RectElement()
            ..setAttribute("x", "0")
            ..setAttribute("y", "7.5")
            ..setAttribute("width", "20")
            ..setAttribute("height", "5")
            ..setAttribute("rx", "2")
            ..style.setProperty("fill", "white")
        ]),
      DivElement()..style.setProperty("min-width", "10px"),
      ParagraphElement()
        ..text = text
        ..classes.add("text")
    ]);
  }

  static DivElement create(int left, int top) {
    int nodeID = id++;
    return DivElement()
      ..classes.add("node")
      ..id = "$nodeID"
      ..style.setProperty("width", "300px")
      ..style.setProperty("left", "${left}px")
      ..style.setProperty("top", "${top}px")
      ..children.addAll([
        DivElement()..classes.add("header"),
        DivElement()
          ..classes.add("input-row")
          ..children.addAll([
            DivElement()
              ..style.setProperty("min-width", "290px")
              ..children.addAll([
                DivElement()
                  ..classes.addAll(["row", "input-row"])
                  ..children.addAll([
                    DivElement()
                      ..classes.addAll(["material-symbols-outlined"])
                      ..style.setProperty("color", "white")
                      ..style.setProperty("margin-left", "10px")
                      ..text = "settings",
                    DivElement()
                      ..classes.addAll(["row", "input-row"])
                      ..style.setProperty("justify-content", "center")
                      ..style.setProperty("flex", "1")
                      ..children.add(InputElement(type: "text")
                        ..placeholder = "untitled module"
                        ..classes.add("text")
                        ..style.setProperty("text-align", "center")),
                    Delete.getDeleteButton("node-$nodeID"),
                  ]),
                DivElement()
                  ..classes.addAll(["row", "input-row"])
                  ..style.setProperty("justify-content", "center")
                  ..children.add(InputElement(type: "text")
                    ..placeholder = "expression"
                    ..classes.addAll(["text", "expression-text"])
                    ..style.setProperty("text-align", "center")),
                ExpressionNode.createAddRow(["addInput"], "Add Input"),
                ExpressionNode.createAddRow(["addConst"], "Add Const")
              ]),
            DivElement()..classes.addAll(["joint", "output-joint"])
          ])
      ]);
  }
}
