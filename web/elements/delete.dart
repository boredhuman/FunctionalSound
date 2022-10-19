import 'dart:svg';

class Delete {
  static SvgSvgElement getDeleteButton(String deleteAttribute) {
    return SvgSvgElement()
      ..setAttribute("delete", deleteAttribute)
      ..classes.add("delete-icon")
      ..style.setProperty("width", "15px")
      ..style.setProperty("min-width", "15px")
      ..style.setProperty("height", "15px")
      ..children.addAll([
        LineElement()
          ..setAttribute("x1", "0")
          ..setAttribute("y1", "0")
          ..setAttribute("x2", "15")
          ..setAttribute("y2", "15")
          ..setAttribute("stroke", "white")
          ..setAttribute("stroke-width", "5"),
        LineElement()
          ..setAttribute("x1", "15")
          ..setAttribute("y1", "0")
          ..setAttribute("x2", "0")
          ..setAttribute("y2", "15")
          ..setAttribute("stroke", "white")
          ..setAttribute("stroke-width", "5")
      ]);
  }
}