import 'package:math_expressions/math_expressions.dart';

dynamic evaluate(String expression, Map<String, num> scope) {
  Parser p = Parser();
  Expression exp = p.parse(expression);

  ContextModel contextModel = ContextModel();

  for (var entry in scope.entries) {
    Variable variable = Variable(entry.key);
    contextModel.bindVariable(variable, Number(entry.value));
  }

  return exp.evaluate(EvaluationType.REAL, contextModel);
}