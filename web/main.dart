import 'dart:html';
import 'dart:svg';
import 'elements/delete.dart';
import 'elements/expression_node.dart';
import 'line_renderer.dart';
import 'elements/output_node.dart';
import 'sound/audio_manager.dart';
import 'elements/time_node.dart';
import 'util/util.dart';

var id = 0;
LineRenderer lineRenderer = LineRenderer();
AudioManager audioManager = AudioManager();

void main() {
  var timeNode = TimeNode.create(100, 400);

  var outputNode = OutputNode.create(800, 440);

  document.body?.children.addAll([lineRenderer.background, timeNode, outputNode, ExpressionNode.create(400, 400)]);

  addDragFunctions();
  addJointFunctions();
  addInputFunctions();
  addPausePlayFunctions();
  addDeleteFunctions(document.getElementsByClassName("delete-icon"));
}

void addDeleteFunctions(List<Node> nodes) {
  for (Node node in nodes) {
    if (node is Element) {
      consoleLog(node);
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
        ..style.setProperty("fill", "white")]);

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

// add input row to node logic
void addInputFunctions() {
  var nodes = document.getElementsByClassName("addInput");

  for (var node in nodes) {
    if (node is Element) {
      node.addEventListener("click", (event) {
        var container = node.parent!.parent!;
        var last = container.children.last;

        Element? lastSrcRow;

        for (Element element in container.children) {
          if (element.classes.contains("src-row")) {
            lastSrcRow = element;
          }
        }

        int index = 0;

        if (lastSrcRow != null) {
          String? indexAttrib = lastSrcRow.children[1].getAttribute("index");
          index = int.parse(indexAttrib!) + 1;
        }

        SvgSvgElement deleteIcon = Delete.getDeleteButton("");

        addDeleteFunctions([deleteIcon]);

        var newSrcRow = DivElement()
          ..classes.addAll(["row", "input-row", "src-row"])
          ..children.addAll([
            DivElement()
              ..classes.addAll(["joint", "input-joint"])
              ..style.setProperty("transform", "translate(-50%, 0)"),
            ParagraphElement()
              ..text = "i$index :\xa0"
              ..classes.addAll(["text", "src-index"])
              ..style.setProperty("white-space", "nowrap")
              ..setAttribute("index", "$index"),
            InputElement(type: "text")
              ..placeholder = "untitled module"
              ..classes.add("text")
              ..style.setProperty("text-align", "left")
              ..style.setProperty("min-width", "0"),
            deleteIcon
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

void addDragFunctions() {
  List<Node> nodes = document.getElementsByClassName("node");

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
            document.body!.style.setProperty("user-select", "none");
          });

          document.onMouseUp.listen((event) {
            dragging = false;
            child.style.setProperty("background-color", "white");
            // allow text to be highlighted again
            document.body!.style.removeProperty("user-select");
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
