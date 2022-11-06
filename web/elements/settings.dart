import 'dart:html';
import 'dart:svg';

import '../main.dart';
import '../util/util.dart';

class Settings {
  static DivElement createSettings() {
    bool extended = true;
    late DivElement ret;
    late SvgElement rotate;
    late InputElement fileInput;
    return ret = DivElement()
      ..style.setProperty("position", "absolute")
      ..style.setProperty("width", "500px")
      ..style.setProperty("height", "100%")
      ..style.setProperty("margin", "0")
      ..style.setProperty("display", "flex")
      ..children.addAll([
        DivElement()
          ..style.setProperty("width", "410px")
          ..style.setProperty("background-color", "#222222")
          ..style.setProperty("height", "100%")
          ..style.setProperty("color", "white")
          ..style.setProperty("font-size", "24px")
          ..style.setProperty("padding", "20px")
          ..style.setProperty("text-align", "center")
          ..children.addAll([
            ParagraphElement()
              ..text = "FunctionalSound"
              ..style.setProperty("font-size", "32px")
              ..style.setProperty("margin", "0"),
            ParagraphElement()
              ..text = "Save Project"
              ..classes.addAll(["button"])
              ..style.setProperty("display", "inline-block")
              ..style.setProperty("background-color", "#111111")
              ..style.setProperty("padding", "10px")
              ..style.setProperty("border-radius", "5px")
              ..onClick.listen((event) {
                var nodeBox = document.getElementById("nodeBox");
                Blob blob = Blob([nodeBox!.outerHtml], "text/csv");
                Element element = window.document.createElement("a");
                element.setAttribute("href", Url.createObjectUrl(blob));
                element.setAttribute("download", "synth.json");
                document.body?.append(element);
                element.click();
                element.remove();
              }),
            DivElement()
              ..style.setProperty("display", "flex")
              ..style.setProperty("justify-content", "center")
              ..children.addAll([
                fileInput = InputElement()
                  ..style.setProperty("display", "block")
                  ..setAttribute("type", "file")
                  ..style.setProperty("background-color", "#111111")
              ]),
            ParagraphElement()
              ..text = "Load Project"
              ..classes.addAll(["button"])
              ..style.setProperty("display", "inline-block")
              ..style.setProperty("background-color", "#111111")
              ..style.setProperty("padding", "10px")
              ..style.setProperty("border-radius", "5px")
              ..onClick.listen((event) {
                List<File>? files = fileInput.files;

                if (files != null && files.isNotEmpty) {
                  File file = files[0];

                  FileReader fileReader = FileReader();
                  fileReader.onLoadEnd.listen((event) {
                    String text = fileReader.result as String;

                    Element nodeBox = document.getElementById("nodeBox")!;
                    nodeBox.children.clear();

                    nodeBox.appendHtml(text, treeSanitizer: NodeTreeSanitizer.trusted);

                    addFunctions();
                    lineRenderer.update();
                  });
                  fileReader.readAsText(file);
                }
              })
          ]),
        rotate = SvgSvgElement()
          ..style.setProperty("width", "44px")
          ..style.setProperty("height", "40px")
          ..style.setProperty("background-color", "#222222")
          ..style.setProperty("transform", "rotate(180deg)")
          ..onClick.listen((event) {
            if (!extended) {
              rotate.style.setProperty("transform", "rotate(180deg)");
            } else {
              rotate.style.removeProperty("transform");
            }
          })
          ..children.addAll([
            LineElement()
              ..setAttribute("x1", "32")
              ..setAttribute("y1", "10")
              ..setAttribute("x2", "32")
              ..setAttribute("y2", "30")
              ..setAttribute("stroke-width", "3px")
              ..style.setProperty("stroke", "white"),
            LineElement()
              ..setAttribute("x1", "5")
              ..setAttribute("y1", "20")
              ..setAttribute("x2", "25")
              ..setAttribute("y2", "20")
              ..setAttribute("stroke-width", "3px")
              ..style.setProperty("stroke", "white"),
            LineElement()
              ..setAttribute("x1", "15")
              ..setAttribute("y1", "10")
              ..setAttribute("x2", "25")
              ..setAttribute("y2", "20")
              ..setAttribute("stroke-width", "3px")
              ..style.setProperty("stroke", "white"),
            LineElement()
              ..setAttribute("x1", "15")
              ..setAttribute("y1", "30")
              ..setAttribute("x2", "25")
              ..setAttribute("y2", "20")
              ..setAttribute("stroke-width", "3px")
              ..style.setProperty("stroke", "white")
          ])
          ..onClick.listen((event) {
            extended = !extended;
            if (extended) {
              ret
                ..style.setProperty("animation", "slideout 0.5s")
                ..style.setProperty("animation-fill-mode", "forwards");
            } else {
              ret
                ..style.setProperty("animation", "slidein 0.5s")
                ..style.setProperty("animation-fill-mode", "forwards");
            }
          })
      ]);
  }
}
