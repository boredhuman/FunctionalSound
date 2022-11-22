import 'dart:html';
import 'dart:math';
import 'dart:svg';
import 'elements/delete.dart';
import 'elements/expression_node.dart';
import 'elements/settings.dart';
import 'line_renderer.dart';
import 'elements/output_node.dart';
import 'sound/audio_manager.dart';
import 'elements/time_node.dart';
import 'util/util.dart';

var id = 0;
LineRenderer lineRenderer = LineRenderer();
AudioManager audioManager = AudioManager();
late DivElement elementContainer;

void main() {
  var timeNode = TimeNode.create(500, 400);

  var outputNode = OutputNode.create(1200, 440);

  var settings = Settings.createSettings();

  elementContainer = DivElement()
    ..id = "nodeBox"
    ..children.addAll([timeNode, outputNode, ExpressionNode.create(800, 400)]);

  document.body?.children.addAll([lineRenderer.background, elementContainer, settings]);

  addDocumentFunctions();
  addFunctions();
}

void disableTextSelection() {
  document.body!.style.setProperty("user-select", "none");
}

void enableTextSelection() {
  document.body!.style.removeProperty("user-select");
}

// functions which operate on the document instead of the nodes
addDocumentFunctions() {
  addDragAllFunction();
  addDoubleClickCreateFunction();
  addJointFunctions();
}

addFunctions() {
  List<Node> nodes = document.getElementsByClassName("node");
  addDragFunctions(nodes);
  var inputNodes = document.getElementsByClassName("addInput");
  addInputFunctions(inputNodes);
  var constRows = document.getElementsByClassName("addConst");
  addConstFunctions(constRows);
  addPausePlayFunctions();
  addDeleteFunctions(document.getElementsByClassName("delete-icon"));

  var constBoxes = document.getElementsByClassName("constBox");
  addSliderFunctions(constBoxes);
}

addNodeFunctions(Element node) {
  addDragFunctions([node]);
  addInputFunctions(node.getElementsByClassName("addInput"));
  addDeleteFunctions(node.getElementsByClassName("delete-icon"));
  addConstFunctions(node.getElementsByClassName("addConst"));
}

void addDoubleClickCreateFunction() {
  document.body?.onDoubleClick.listen((event) {
    if (event is MouseEvent && (event.target == lineRenderer.background || event.target == document.body)) {
      Element newNode = ExpressionNode.create(event.client.x.toInt() - 150, event.client.y.toInt());
      // add dragging and the input functions
      addNodeFunctions(newNode);
      elementContainer.children.add(newNode);
    }
  });
}

void addDragAllFunction() {
  int prevX = 0;
  int prevY = 0;
  bool dragging = false;

  document.body!.onMouseDown.listen((event) {
    if (event.target == document.body || event.target == lineRenderer.background) {
      prevX = event.client.x.toInt();
      prevY = event.client.y.toInt();
      dragging = true;
      // stop things from being highlighted
      document.body!.style.setProperty("user-select", "none");
    }
  });

  document.body!.onMouseUp.listen((event) {
    dragging = false;
    // all things to be highlighted again
    document.body!.style.removeProperty("user-select");
  });

  document.body!.onMouseMove.listen((event) {
    if (dragging) {
      int deltaX = event.client.x.toInt() - prevX;
      int deltaY = event.client.y.toInt() - prevY;
      if (deltaX != 0 || deltaY != 0) {
        prevX = event.client.x.toInt();
        prevY = event.client.y.toInt();

        Element nodeBox = document.getElementById("nodeBox")!;

        for (Element node in nodeBox.children) {
          String left = node.style.getPropertyValue("left");
          String top = node.style.getPropertyValue("top");
          int leftNumber = int.parse(left.substring(0, left.length - 2));
          int topNumber = int.parse(top.substring(0, top.length - 2));

          node.style.setProperty("left", "${leftNumber + deltaX}px");
          node.style.setProperty("top", "${topNumber + deltaY}px");
        }

        lineRenderer.update();
      }
    }
  });
}

void addDeleteFunctions(List<Node> nodes) {
  for (Node node in nodes) {
    if (node is Element) {
      node.onClick.listen((event) {
        String? deleteAttribute = node.getAttribute("delete");
        if (deleteAttribute != null) {
          if (deleteAttribute.contains("node")) {
            String nodeID = deleteAttribute.substring(5, deleteAttribute.length);
            Element? node = document.getElementById(nodeID);
            if (node != null) {
              node.remove();
            }
          } else {
            node.parent?.remove();
          }
        }
      });
    }
  }
}

Element? getParentWithClass(Element? element, String className) {
  if (element == null) {
    return null;
  }

  var parent = element.parent;
  if (parent != null) {
    if (parent.classes.contains(className)) {
      return parent;
    } else {
      return getParentWithClass(parent, className);
    }
  } else {
    return null;
  }
}

String getExpression() {
  Element? output = document.getElementById("output");
  Element? time = document.getElementById("time");

  if (output == null || time == null) {
    return "";
  }

  Element inputJoint = output.getElementsByClassName("input-joint")[0] as Element;

  String? srcNodeID = inputJoint.getAttribute("src-node");

  if (srcNodeID == null) {
    return "";
  }

  Element? srcNode = document.getElementById(srcNodeID);

  if (srcNode == null) {
    return "";
  }

  List<Node> expressionElement = srcNode.getElementsByClassName("expression-text");

  if (expressionElement.isEmpty) {
    return "";
  }

  return resolveInputs(srcNode, (expressionElement[0] as InputElement).value!);
}

// replace all inputs with the expression from their inputs
String resolveInputs(Element element, String expression) {
  // get all inputs
  List<Node> srcRows = element.getElementsByClassName("src-row");

  for (Node srcRow in srcRows) {
    if (srcRow is Element) {
      // const box provide their own input
      if (srcRow.classes.contains("constBox")) {
        Element knobVal = srcRow.getElementsByClassName("knobVal")[0] as Element;
        String index = (srcRow.getElementsByClassName("src-index")[0] as Element).getAttribute("index")!;


        expression = expression.replaceAll("i$index", knobVal.text!);
      } else {
        // get input joint to get input node
        Element inputJoint = srcRow.getElementsByClassName("input-joint")[0] as Element;

        String? srcNodeID = inputJoint.getAttribute("src-node");

        if (srcNodeID == null) {
          continue;
        }

        if (srcNodeID == "time") {
          // if the src is the time node we just replace it with x
          List<Node> nodes = srcRow.getElementsByClassName("src-index");
          if (nodes.isNotEmpty) {
            String index = (nodes[0] as Element).getAttribute("index")!;
            expression = expression.replaceAll("i$index", "x");
          }
        } else {
          // get the src node
          Element? srcNode = document.getElementById(srcNodeID);

          if (srcNode != null) {
            // get the expression
            List<Node> expressionElement = srcNode.getElementsByClassName("expression-text");

            if (expressionElement.isNotEmpty) {
              List<Node> nodes = srcRow.getElementsByClassName("src-index");
              if (nodes.isNotEmpty) {
                // replace the ix with the expression
                String index = (nodes[0] as Element).getAttribute("index")!;
                expression = expression.replaceAll("i$index", "(${resolveInputs(srcNode, (expressionElement[0] as InputElement).value!)})");
              }
            }
          }
        }
      }
    }
  }

  return expression;
}

void addResetButtonFunctino() {
  var reset = document.getElementById("resetButton");

  if (reset == null) {
    return;
  }

  reset.onClick.listen((event) {
    audioManager.resetTime();
  });
}

void addPausePlayFunctions() {
  var pausePlay = document.getElementById("pausePlay");

  if (pausePlay == null) {
    return;
  }
  pausePlay.onClick.listen((event) async {
    // can only initialize stuff on user input so have to do it here
    if (!audioManager.initialized) {
      await audioManager.init();
    }
    bool playing = pausePlay.getAttribute("playing") == "true";
    // not playing but user is trying to play
    if (!playing) {
      String expression = getExpression();
      if (expression.isNotEmpty) {
        // failed to play so don't change state
        // todo notify user it failed to play
        if (!audioManager.setExpression(expression)) {
          return;
        }
      } else {
        // not expression so nothing to play so just return
        return;
      }
    }
    playing = !playing;
    audioManager.setPlaying(playing);
    pausePlay.setAttribute("playing", playing);

    pausePlay.children.clear();
    if (playing) {
      pausePlay.children.addAll([
        PolygonElement()
          ..setAttribute("points", "0,0 0,20 8,20 8,0")
          ..style.setProperty("fill", "white"),
        PolygonElement()
          ..setAttribute("points", "12,0 12,20 20,20 20,0")
          ..style.setProperty("fill", "white")
      ]);

      String expression = getExpression();
      if (expression.isNotEmpty) {
        audioManager.setExpression(expression);
      }
    } else {
      pausePlay.children.add(PolygonElement()
        ..setAttribute("points", "0,0 0,20 20,10")
        ..style.setProperty("fill", "white"));
    }
  });
}

void addConstFunctions(List<Node> nodes) {
  for (var node in nodes) {
    if (node is Element) {
      node.addEventListener("click", (event) {
        // svg -> row -> rows container
        var container = node.parent!.parent!;
        var last = container.children[container.children.length - 2];

        Element? lastSrcRow;

        for (Element element in container.children) {
          if (element.classes.contains("src-row")) {
            lastSrcRow = element;
          }
        }

        int index = 0;

        if (lastSrcRow != null) {
          String? indexAttrib = (lastSrcRow.getElementsByClassName("src-index")[0] as Element).getAttribute("index");
          index = int.parse(indexAttrib!) + 1;
        }

        SvgSvgElement deleteIcon = Delete.getDeleteButton("");

        addDeleteFunctions([deleteIcon]);

        var newSrcRow = DivElement()
          ..classes.addAll(["input-row", "src-row", "constBox"])
          ..style.setProperty("margin", "5px 0")
          ..style.setProperty("height", "120px")
          ..children.addAll([
            DivElement()
              ..style.setProperty("width", "34px")
              ..style.setProperty("transform", "translate(-50%, 0)"),
            DivElement()
              ..style.setProperty("height", "120px")
              ..style.setProperty("display", "flex")
              ..style.setProperty("align-items", "center")
              ..style.setProperty("padding", "0 5px")
              ..style.setProperty("margin", "0 2px")
              ..style.setProperty("background-color", "#444")
              ..style.setProperty("border-radius", "5px")
              ..children.addAll([
                ParagraphElement()
                  ..text = "i$index :\xa0"
                  ..classes.addAll(["text", "src-index"])
                  ..style.setProperty("white-space", "nowrap")
                  ..setAttribute("index", "$index"),
                DivElement()
                  ..style.setProperty("display", "flex")
                  ..children.addAll([
                    // the knob
                    DivElement()
                      ..style.setProperty("width", "120px")
                      ..style.setProperty("height", "120px")
                      ..style.setProperty("min-width", "120px")
                      ..children.addAll([
                        DivElement()
                          ..style.setProperty("width", "80px")
                          ..style.setProperty("height", "80px")
                          ..style.setProperty("margin", "auto")
                          ..children.addAll([
                            SvgSvgElement()
                              ..classes.addAll(["knob"])
                              ..style.setProperty("width", "80px")
                              ..style.setProperty("height", "80px")
                              ..children.addAll([
                                CircleElement()
                                  ..setAttribute("cx", "40")
                                  ..setAttribute("cy", "40")
                                  ..setAttribute("r", "28")
                                  ..setAttribute("fill", "#222"),
                                CircleElement()
                                  ..classes.addAll(["dial"])
                                  ..setAttribute("cx", "55")
                                  ..setAttribute("cy", "55")
                                  ..setAttribute("r", "2")
                                  ..setAttribute("fill", "aqua")
                              ])
                          ]),
                        ParagraphElement()
                          ..text = "1.0"
                          ..style.setProperty("margin", "0")
                          ..style.setProperty("text-align", "center")
                          ..classes.addAll(["text", "knobVal"])
                      ]),
                  ]),
                // the settings for it
                DivElement()
                  ..style.setProperty("height", "100%")
                  ..style.setProperty("padding", "0px 5px")
                  ..children.addAll([
                    ParagraphElement()
                      ..text = "Min"
                      ..classes.addAll(["text"])
                      ..style.setProperty("font-size", "12px")
                      ..style.setProperty("margin", "0")
                      ..style.setProperty("min-width", "0"),
                    InputElement()
                      ..value = "0"
                      ..classes.addAll(["text", "centerText", "min"])
                      ..style.setProperty("background-color", "#222")
                      ..style.setProperty("width", "100%")
                      ..style.setProperty("border-radius", "2px"),
                    ParagraphElement()
                      ..text = "Max"
                      ..classes.addAll(["text"])
                      ..style.setProperty("font-size", "12px")
                      ..style.setProperty("margin", "0"),
                    InputElement()
                      ..value = "1"
                      ..classes.addAll(["text", "centerText", "max"])
                      ..style.setProperty("background-color", "#222")
                      ..style.setProperty("width", "100%")
                      ..style.setProperty("border-radius", "2px"),
                    ParagraphElement()
                      ..text = "Precision"
                      ..classes.addAll(["text"])
                      ..style.setProperty("font-size", "12px")
                      ..style.setProperty("margin", "0"),
                    InputElement()
                      ..value = "2"
                      ..classes.addAll(["text", "centerText", "precision"])
                      ..style.setProperty("background-color", "#222")
                      ..style.setProperty("width", "100%")
                      ..style.setProperty("border-radius", "2px")
                  ]),
                deleteIcon
              ])
          ]);

        print("adding const");
        addSliderFunctions([newSrcRow]);

        container.insertBefore(newSrcRow, last);
      });
    }
  }
}

// list of const boxes
void addSliderFunctions(List<Node> nodes) {
  for (Node node in nodes) {
    if (node is Element) {
      int prevY = 0;
      bool dragging = false;
      double knobRotation = 1;

      Element knob = node.getElementsByClassName("knob")[0] as Element;
      InputElement minElement = node.getElementsByClassName("min")[0] as InputElement;
      InputElement maxElement = node.getElementsByClassName("max")[0] as InputElement;
      InputElement precisionElement = node.getElementsByClassName("precision")[0] as InputElement;
      Element knobVal = node.getElementsByClassName("knobVal")[0] as Element;
      Element dial = node.getElementsByClassName("dial")[0] as Element;

      knob.onMouseDown.listen((event) {
        dragging = true;
        prevY = event.client.y.toInt();
        disableTextSelection();
      });

      document.onMouseUp.listen((event) {
        dragging = false;
        enableTextSelection();
      });

      document.onMouseMove.listen((event) {
        if (dragging) {
          int currentY = event.client.y.toInt();
          // if vertical position changed update slider
          if (currentY != prevY) {
            String? minText = minElement.value;
            double minVal = minText != null ? double.parse(minText) : 0;
            String? maxText = maxElement.value;
            double maxVal = maxText != null ? double.parse(maxText) : 0;
            String? precisionText = precisionElement.value;
            int precision = precisionText != null ? int.parse(precisionText) : 1;

            double delta = (currentY - prevY) / 100;
            knobRotation = (knobRotation += delta).clamp(0, 1);
            var angle = 90 + (270 * knobRotation);

            double unrounded = (minVal + (maxVal - minVal) * knobRotation).clamp(minVal, maxVal);
            knobVal.text = unrounded.clamp(minVal, maxVal).toStringAsFixed(precision);

            var angleRad = angle * pi / 180;
            var newX = 15 * cos(angleRad) - 15 * sin(angleRad);
            var newY = 15 * sin(angleRad) + 15 * cos(angleRad);
            dial
              ..setAttribute("cx", (40 + newX).toInt().toString())
              ..setAttribute("cy", (40 + newY).toInt().toString());

            prevY = currentY;
          }
        }
      });
    }
  }
}

// add input row to node logic
void addInputFunctions(List<Node> nodes) {
  for (var node in nodes) {
    if (node is Element) {
      node.addEventListener("click", (event) {
        var container = node.parent!.parent!;
        var last = container.children[container.children.length - 2];

        Element? lastSrcRow;

        for (Element element in container.children) {
          if (element.classes.contains("src-row")) {
            lastSrcRow = element;
          }
        }

        int index = 0;

        if (lastSrcRow != null) {
          String? indexAttrib = (lastSrcRow.getElementsByClassName("src-index")[0] as Element).getAttribute("index");
          index = int.parse(indexAttrib!) + 1;
        }

        SvgSvgElement deleteIcon = Delete.getDeleteButton("");

        addDeleteFunctions([deleteIcon]);

        var newSrcRow = DivElement()
          ..classes.addAll(["row", "input-row", "src-row"])
          ..style.setProperty("margin", "5px 0")
          ..children.addAll([
            DivElement()
              ..classes.addAll(["joint", "input-joint"])
              ..style.setProperty("transform", "translate(-50%, 0)"),
            DivElement()
              ..style.setProperty("height", "40px")
              ..style.setProperty("display", "flex")
              ..style.setProperty("background-color", "#444")
              ..style.setProperty("margin", "0 2px")
              ..style.setProperty("padding", "0 5px")
              ..style.setProperty("align-items", "center")
              ..style.setProperty("border-radius", "5px")
              ..children.addAll([
                ParagraphElement()
                  ..text = "i$index :\xa0"
                  ..classes.addAll(["text", "src-index"])
                  ..style.setProperty("white-space", "nowrap")
                  ..setAttribute("index", "$index"),
                InputElement(type: "text")
                  ..placeholder = "untitled input"
                  ..classes.add("text")
                  ..style.setProperty("text-align", "left")
                  ..style.setProperty("width", "100%")
                  ..style.setProperty("background-color", "#00000000"),
                deleteIcon
              ])
          ]);

        container.insertBefore(newSrcRow, last);
      });
    }
  }
}

// add inputs to joints logic
void addJointFunctions() {
  Element? lastClicked;

  document.onClick.listen((event) {
    var target = event.target;
    if (target is Element) {
      if (target.classes.contains("joint")) {
        if (lastClicked != null) {
          // only opposite nodes can connect
          var firstClickedInput = lastClicked!.classes.contains("input-joint");
          var currentClickedInput = target.classes.contains("input-joint");
          if (firstClickedInput != currentClickedInput) {
            if (firstClickedInput) {
              var parentNode = getParentWithClass(target, "node");
              lastClicked!.setAttribute("src-node", "${parentNode?.id}");
            } else {
              var parentNode = getParentWithClass(lastClicked, "node");
              target.setAttribute("src-node", "${parentNode?.id}");
            }

            lineRenderer.update();
          }

          lastClicked = null;
        } else {
          lastClicked = target;
        }
      }
    }
  });
}

void addDragFunctions(List<Node> nodes) {
  for (var node in nodes) {
    if (node is Element) {
      for (var child in node.children) {
        if (child.classes.contains("header")) {
          var dragging = false;
          var deltaX = 0;
          var deltaY = 0;

          child.onMouseDown.listen((event) {
            dragging = true;

            var style = node.getComputedStyle();
            var left = style.getPropertyValue("left");
            var leftNumber = int.parse(left.substring(0, left.length - 2));
            deltaX = event.client.x.toInt() - leftNumber;

            var top = style.getPropertyValue("top");
            var topNumber = int.parse(top.substring(0, top.length - 2));
            deltaY = event.client.y.toInt() - topNumber;

            child.style.setProperty("background-color", "red");

            // stop text from thinking its being selected
            disableTextSelection();
          });

          document.onMouseUp.listen((event) {
            dragging = false;
            child.style.setProperty("background-color", "white");
            // allow text to be highlighted again
            enableTextSelection();
          });

          document.onMouseMove.listen((event) {
            if (dragging) {
              var newX = "${event.client.x.toInt() - deltaX}px";
              node.style.setProperty("left", newX);

              var newY = "${event.client.y.toInt() - deltaY}px";
              node.style.setProperty("top", newY);

              lineRenderer.update();
            }
          });
          break;
        }
      }
    }
  }
}
