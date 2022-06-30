import 'dart:html';
import 'dart:web_gl';

import 'main.dart';
import 'segments/nodes.dart';
import 'render/render_util.dart';
import 'segments/add_segment.dart';
import 'segments/expression_segment.dart';
import 'segments/input_segment.dart';
import 'segments/label_segment.dart';
import 'segments/segment.dart';
import 'segments/time_segment.dart';
import 'util/util.dart';

class UIManager {
  List<Node> elements = [];
  int lastMouseX = 0;
  // do not use this by itself as its references the top left when we want the bottom left
  int lastMouseY = 0;
  int clientWidth = 0;
  int clientHeight = 0;
  CanvasElement canvas;
  Object? selectedNode;
  bool? isOutput;
  late Node outputNode;
  late Node timeNode;

  UIManager(this.canvas) {
    consoleLog("initializing ui manager");

    canvas.onClick.listen((event) {
      handleEvent(event);
    });

    canvas.onMouseDown.listen((event) {
      for (var element in elements) {
        element.handleMouseDown(event);
      }
    });

    canvas.onMouseUp.listen((event) {
      for (var element in elements) {
        element.handleMouseUp(event);
      }
    });

    canvas.onMouseMove.listen((event) {
      lastMouseX = event.client.x.toInt();
      lastMouseY = event.client.y.toInt();
    });

    // for some reason does not work with backspace
    window.onKeyPress.listen((event) {
      handleEvent(event);
    });

    // gets backspace for us
    window.onKeyDown.listen((event) {
      if (event.key != null && (event.key == "Backspace" || event.key == "ArrowLeft" || event.key == "ArrowRight")) {
        handleEvent(event);
      }
    });

    canvas.width = document.body?.clientWidth;
    canvas.height = document.body?.clientHeight;
    // make background black
    gl.clearColor(0, 0, 0, 255);
    gl.clearDepth(1.0);
    gl.enable(WebGL.DEPTH_TEST);
    gl.depthFunc(WebGL.LEQUAL);
    gl.enable(WebGL.BLEND);
    gl.blendFuncSeparate(WebGL.SRC_ALPHA, WebGL.ONE_MINUS_SRC_ALPHA, WebGL.ONE, WebGL.ONE);
    gl.viewport(0, 0, canvas.width!, canvas.height!);

    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);

    clientWidth = canvas.clientWidth;
    clientHeight = canvas.clientHeight;

    timeNode = Node(100, 500, 200, renderOutput: true);
    timeNode.addSegment(LabelSegment("Time"));
    TimeSegment timeSegment = TimeSegment();
    timeSegment.onclick = () {
      backPropagate();
    };
    timeNode.addSegment(timeSegment);

    Node exampleNode = Node(400, 450, 400);
    exampleNode.addSegment(LabelSegment("Example"));
    exampleNode.addSegment(AddSegment());

    outputNode = Node(900, 500, 200, renderInput: true, renderOutput: false);
    outputNode.addSegment(LabelSegment("Output"));

    elements.add(timeNode);
    elements.add(exampleNode);
    elements.add(outputNode);
  }

  void render() {
    for (Node element in elements) {
      element.render(lastMouseX, uiManager.getMouseY());
    }
    drawQuad(lastMouseX, getMouseY() + 1, lastMouseX + 1, getMouseY(), 0xFF0000FF);
  }

  void handleEvent(Event event) {
    if (event is MouseEvent) {
      if (handleMouseEvent(event)) {
        print("Returning");
        return;
      }
    }
    for (Node element in elements) {
      if (element.handleEvent(event)) {
        print("node consumed click");
        return;
      }
    }
  }

  bool handleMouseEvent(MouseEvent event) {
    Object? clickedNode;
    bool isOutput = false;

    for (Node element in elements) {
      if (element.clickedOutputNode()) {
        clickedNode = element;
        isOutput = true;
        break;
      }
      if (element.clickedInputNode()) {
        clickedNode = element;
        break;
      }
      for (Segment segment in element.segments) {
        if (segment is InputSegment) {
          print("Asking ${segment.runtimeType} ");
          if (segment.clickedInputNode()) {
            print("Clicked segment");
            clickedNode = segment;
            break;
          }
        }
      }
    }

    // input node should be added to the inputs list of the output node
    if (clickedNode != null && selectedNode != null && this.isOutput != isOutput) {
      if (this.isOutput!) {
        if (clickedNode is Node) {
          clickedNode.input = selectedNode as Node;
        } else if (clickedNode is InputSegment) {
          clickedNode.input = selectedNode as Node;
        }
      } else {
        if (selectedNode is Node) {
          (selectedNode as Node).input = clickedNode as Node;
        } else if (selectedNode is InputSegment) {
          (selectedNode as InputSegment).input = clickedNode as Node;
        }
      }
      selectedNode = null;
      this.isOutput = null;
    } else {
      selectedNode = clickedNode;
      this.isOutput = isOutput;
    }

    return clickedNode != null;
  }

  void backPropagate() {
    if (outputNode.input != null) {
      ExpressionSegment? expressionSegment = getExpressionSegment(outputNode.input!);

      if (expressionSegment != null) {
        String expression = resolveInputs(outputNode.input!, expressionSegment);

        print(expression);
        audioManager.playSound(expression);
      }
    }
  }

  String resolveInputs(Node node, ExpressionSegment expressionSegment) {
    String expression = expressionSegment.text;

    for (Segment segment in node.segments) {
      if (segment is InputSegment) {
       Node? inputOfSegment = segment.input;

       if (inputOfSegment != null) {
         ExpressionSegment? subExpressionSegment = getExpressionSegment(inputOfSegment);
         if (subExpressionSegment != null) {
           expression = expression.replaceAll("i${segment.index}", resolveInputs(inputOfSegment, subExpressionSegment));
         } else {
           if (inputOfSegment == timeNode) {
             expression = expression.replaceAll("i${segment.index}", "x");
           }
         }
       }
      }
    }

    return expression;
  }

  ExpressionSegment? getExpressionSegment(Node node) {
    for (Segment segment in node.segments) {
      if (segment is ExpressionSegment) {
        return segment;
      }
    }
    return null;
  }

  // inverts mouse y so bottom left is the reference
  int getMouseY() {
    return clientHeight - lastMouseY;
  }
}
