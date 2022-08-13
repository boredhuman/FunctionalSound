import 'dart:html';
import 'dart:web_gl';

import 'main.dart';
import 'render/render_util.dart';
import 'segments/click_listener.dart';
import 'segments/dynamic_listener.dart';
import 'segments/hover_listener.dart';
import 'segments/nodes.dart';
import 'segments/add_segment.dart';
import 'segments/expression_segment.dart';
import 'segments/input_segment.dart';
import 'segments/label_segment.dart';
import 'segments/render_listener.dart';
import 'segments/segment.dart';
import 'segments/time_segment.dart';
import 'util/save_load.dart';
import 'util/util.dart';

class UIManager {
  List<Node> elements = [];
  int lastMouseX = 0;
  // do not use this by itself as its references the top left when we want the bottom left
  int lastMouseY = 0;
  CanvasElement canvas;
  Object? selectedNode;
  bool? isOutput;
  late Node outputNode;
  late Node timeNode;

  bool draggingBackground = false;
  int lastDragX = 0;
  int lastDragY = 0;

  List<Node> consumedDown = [];
  List<Segment> overlay = [];
  bool showingOptions = false;

  UIManager(this.canvas) {
    consoleLog("initializing ui manager");

    canvas.onClick.listen((event) {
      handleEvent(event);
    });

    canvas.onMouseDown.listen((event) {
      if (!overNodes() && !showingOptions) {
        print('dragging background');
        lastDragX = lastMouseX;
        lastDragY = getMouseY();
        draggingBackground = true;
        return;
      }

      for (Node element in elements) {
        if (element.handleMouseDown(event)) {
          consumedDown.add(element);
          return;
        } else {
          consumedDown.add(element);
        }
      }
    });

    canvas.onMouseUp.listen((event) {
      if (draggingBackground) {
        draggingBackground = false;
        return;
      }

      for (Node element in consumedDown) {
        element.handleMouseUp(event);
      }
      consumedDown.clear();
    });

    canvas.onMouseMove.listen((event) {
      lastMouseX = event.client.x.toInt() - canvas.getBoundingClientRect().left.toInt();
      lastMouseY = event.client.y.toInt() - canvas.getBoundingClientRect().top.toInt();
    });

    canvas.onDoubleClick.listen((event) {
      if (!overNodes()) {
        Node newElement = Node(lastMouseX - 200, getMouseY(), 400, renderOutput: true);
        newElement.addSegment(LabelSegment("Unnamed", deletable: true));
        newElement.addSegment(AddSegment());
        newElement.y -= newElement.height;
        elements.add(newElement);
      }
    });

    canvas.onDrop.listen((event) {
      event.preventDefault();
      handleEvent(event);
    });

    canvas.onDragOver.listen((event) {
      event.preventDefault();
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

    loadDefault();

    init();
  }

  void loadDefault() {
    timeNode = Node(100, 500, 200, renderOutput: true);
    timeNode.addSegment(LabelSegment("Time", mutableName: false));
    timeNode.addSegment(TimeSegment());

    Node exampleNode = Node(400, 450, 400);
    exampleNode.addSegment(LabelSegment("Example", deletable: true));
    exampleNode.addSegment(AddSegment());

    outputNode = Node(900, 500, 200, renderInput: true, renderOutput: false);
    outputNode.addSegment(LabelSegment("Output", mutableName: false));

    elements.add(timeNode);
    elements.add(outputNode);
    elements.add(exampleNode);
  }

  void handleResize() {
    if (canvas.width! != document.body?.clientWidth || canvas.height! != document.body?.clientHeight) {
      canvas.width = document.body?.clientWidth;
      canvas.height = document.body?.clientHeight;
      gl.viewport(0, 0, canvas.width!, canvas.height!);
      init();
    }
  }

  void addRedHover(Segment segment) {
    segment.addListener(HoverListener<LabelSegment>(onEnter: (seg) => seg.textColor = 0xFF0000FF, onExit: (seg) => seg.textColor = 0xFFFFFFFF));
  }

  void init() {
   if (showingOptions) {
     showOptions();
   } else {
     showSettings();
   }

   addDebug();
  }

  void showSettings() {
    overlay.clear();
    LabelSegment labelSegment = LabelSegment("Settings");
    int width = fontRenderer!.getStringWidth("Settings");

    labelSegment.setDimensions(x: canvas.width! - width - 10, y: canvas.height! - 40, width: width, height: 40);
    addRedHover(labelSegment);
    labelSegment.addListener(ClickListener<LabelSegment>((seg) {
      showingOptions = true;
      init();
    }));
    overlay.add(labelSegment);

    showingOptions = false;
  }

  void showOptions() {
    overlay.clear();

    int midPoint = canvas.width! ~/ 2;
    int top = canvas.height!;

    LabelSegment saveSegment = LabelSegment("Save");
    addRedHover(saveSegment);
    int saveWidth = fontRenderer!.getStringWidth("Save");
    saveSegment.setDimensions(x: midPoint - saveWidth ~/ 2, y: top - 100, width: saveWidth, height: 40);
    saveSegment.addListener(ClickListener<LabelSegment>((seg) {
      SaveLoad.save();
    }));
    overlay.add(saveSegment);

    LabelSegment loadSegment = LabelSegment("Drag here to load.");
    addRedHover(loadSegment);
    int loadWidth = fontRenderer!.getStringWidth("Drag here to load.");
    loadSegment.setDimensions(x: midPoint - loadWidth ~/ 2, y: top - 150, width: loadWidth, height: 40);
    loadSegment.addListener(DynamicListener(["drop"], (event, seg) {
      DataTransfer dataTransfer = (event as MouseEvent).dataTransfer;
      DataTransferItemList? itemList = dataTransfer.items;

      if (itemList != null) {
        int len = itemList.length!;
        for (int i = 0; i < len; i++) {
          DataTransferItem dataTransferItem = itemList[i];
          if (dataTransferItem.kind == "file") {
            File file = dataTransferItem.getAsFile()!;
            Blob data = file.slice();
            FileReader fileReader = FileReader();
            fileReader.onLoadEnd.listen((event) {
              Object? result = fileReader.result;
              if (result is String) {
                SaveLoad.load(result);
                // close settings menu after loading is done
                showingOptions = false;
                init();
              } else {
                consoleLog("File is not of type string");
              }
            });
            fileReader.readAsText(data);
          }
        }
      }

      return true;
    }));
    overlay.add(loadSegment);

    LabelSegment closeSegment = LabelSegment("Close");
    addRedHover(closeSegment);
    int closeWidth = fontRenderer!.getStringWidth("Close");
    closeSegment.setDimensions(x: canvas.width! - closeWidth - 10, y: top - 40, width: closeWidth, height: 40);
    overlay.add(closeSegment);

    closeSegment.addListener(ClickListener<LabelSegment>((seg) {
      showingOptions = false;
      init();
    }));
  }

  void addDebug() {
    print("adding debug");
    LabelSegment mouseX = LabelSegment("");
    mouseX.addListener(RenderListener<LabelSegment>((seg) {
      seg.text = lastMouseX.toString();
      seg.width = fontRenderer!.getStringWidth(seg.text);
    }));
    mouseX.setDimensions(x: 0, y: 0, width: 0, height: 40);

    overlay.add(mouseX);

    LabelSegment mouseY = LabelSegment("");
    mouseY.addListener(RenderListener<LabelSegment>((seg) {
      seg.text = getMouseY().toString();
      seg.width = fontRenderer!.getStringWidth(seg.text);
    }));
    mouseY.setDimensions(x: 0, y: 40, width: 0, height: 40);

    overlay.add(mouseY);
  }

  void render() {
    handleResize();

    // if dragging background
    if (!showingOptions) {
      if (draggingBackground) {
        int deltaX = lastDragX - lastMouseX;
        int deltaY = lastDragY - getMouseY();
        for (Node element in elements) {
          element.x -= deltaX;
          element.y -= deltaY;
        }

        lastDragX = lastMouseX;
        lastDragY = uiManager.getMouseY();
      }

      for (Node element in elements) {
        element.render(lastMouseX, uiManager.getMouseY());
      }
    }
    // debug quad to see mouse pixel x and y
    drawQuad(lastMouseX, getMouseY() + 1, lastMouseX + 1, getMouseY(), 0xFF0000FF);

    for (Segment segment in overlay) {
      segment.render();
    }
  }

  void handleEvent(Event event) {
    if (!showingOptions) {
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

    for (Segment segment in overlay) {
      if (segment.handleEventInternal(event)) {
        return;
      }
    }
  }

  bool overNodes() {
    for (Node node in elements) {
      if (node.isOverNode()) {
        return true;
      }
    }
    return false;
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
          if (segment.clickedInputNode()) {
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
        audioManager.setExpression(expression);
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
    return canvas.clientHeight - lastMouseY;
  }
}
