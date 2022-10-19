import 'dart:html';
import 'dart:svg';

class LineRenderer {
  late SvgSvgElement background;

  LineRenderer() {
    background = SvgSvgElement()
      ..style.setProperty("position", "absolute")
      ..style.setProperty("width", "100%")
      ..style.setProperty("height", "100%");
  }

  void update() {
    background.children.clear();

    var inputJoints = document.getElementsByClassName("input-joint");

    for (var joint in inputJoints) {
      if (joint is Element) {
        var srcNode = joint.getAttribute("src-node");

        if (srcNode != null) {
          var node = getNodeById(srcNode);

          if (node != null) {
            var outputJoint = getOutputJoint(node);

            if (outputJoint != null) {
              addLine(joint, outputJoint);
            }
          }
        }
      }
    }
  }

  Element? getNodeById(String id) {
    var nodes = document.getElementsByClassName("node");

    for (var node in nodes) {
      if (node is Element) {
        if (node.id == id) {
          return node;
        }
      }
    }

    return null;
  }

  Element? getOutputJoint(Element node) {
    for (var child in node.children) {
      if (child.classes.contains("output-joint")) {
        return child;
      } else {
        var outputJoint = getOutputJoint(child);
        if (outputJoint != null) {
          return outputJoint;
        }
      }
    }

    return null;
  }

  void addLine(Element inputJoint, Element outputJoint) {
    var inputRect = inputJoint.getBoundingClientRect();
    var outputrect = outputJoint.getBoundingClientRect();

    var x1 = inputRect.left + inputRect.width / 2;
    var y1 = inputRect.top + inputRect.height / 2;
    var x2 = outputrect.left + outputrect.width / 2;
    var y2 = outputrect.top + outputrect.height / 2;

    background.children.add(LineElement()
      ..setAttribute("x1", "$x1")
      ..setAttribute("y1", "$y1")
      ..setAttribute("x2", "$x2")
      ..setAttribute("y2", "$y2")
      ..setAttribute("stroke", "white"));

  }
}
