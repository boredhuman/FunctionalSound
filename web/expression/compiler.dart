import '../util/stack.dart';
import 'token_grouper.dart';
import 'tokenizer.dart';

// When adding a new instruction, make sure to update audioVM.ts as well!
enum InstructionType { ADD, SUB, MUL, DIV, PUSHC, PUSHV, NEG, FUN, FUN_2, PUSH_TIME, NOP }

class Instruction {
  InstructionType type;
  String? value;

  Instruction(this.type, this.value);

  Map toJson() => {'type': type.name, 'value': value};
}

class Compiler {
  List<Instruction>? compileGroup(Group group, Tokenizer tokenizer) {
    List<Instruction> list = [];
    Stack<Token> operatorStack = Stack();

    for (int i = 0; i < group.tokens.length; i++) {
      GroupToken t = group.tokens[i];

      if (t.token != null) {
        Token token = t.token!;

        if (token.type == TokenType.OPERATOR) {
          if (i == 0 || i >= group.tokens.length - 1) {
            return null;
          }

          operatorStack.push(token);
        } else if (token.type == TokenType.VARIABLE) {
          if (token.value == 'x') {
            list.add(Instruction(InstructionType.PUSH_TIME, null));
          } else {
            list.add(Instruction(InstructionType.PUSHV, token.value));
          }

          if (!operatorStack.isEmpty) {
            list.add(_getOperatorInstruction(operatorStack.pop()));
          }
        } else if (token.type == TokenType.CONSTANT) {
          list.add(Instruction(InstructionType.PUSHC, token.value));

          if (!operatorStack.isEmpty) {
            list.add(_getOperatorInstruction(operatorStack.pop()));
          }
        }
      } else if (t.group != null) {
        list.addAll(compileGroup(t.group!, tokenizer)!);

        if (t.functionName != null) {
          if (tokenizer.isTwoParamFunction(t.functionName!)) {
            list.add(Instruction(InstructionType.FUN_2, t.functionName!));
          } else {
            list.add(Instruction(InstructionType.FUN, t.functionName!));
          }
        }

        if (t.negated) {
          list.add(Instruction(InstructionType.NEG, null));
        }

        if (!operatorStack.isEmpty) {
          list.add(_getOperatorInstruction(operatorStack.pop()));
        }
      }
    }

    return list;
  }

  Instruction _getOperatorInstruction(Token operator) {
    switch (operator.value) {
      case '+':
        return Instruction(InstructionType.ADD, null);
      case '-':
        return Instruction(InstructionType.SUB, null);
      case '*':
        return Instruction(InstructionType.MUL, null);
      case '/':
        return Instruction(InstructionType.DIV, null);
    }

    return Instruction(InstructionType.NOP, null); // TODO: Handle invalid
  }

  String visualizeInstructions(List<Instruction> insns) {
    String s = "";

    for (Instruction i in insns) {
      s += "${i.type.name}${i.value == null ? "" : "[${i.value!}]"}\n";
    }

    return s;
  }
}
