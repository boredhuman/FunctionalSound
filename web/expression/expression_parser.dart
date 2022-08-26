import 'dart:math' as Math;
import 'dart:typed_data';

import 'compiler.dart';
import 'token_grouper.dart';
import 'tokenizer.dart';

class ExpressionParser {
  Tokenizer tokenizer = Tokenizer();
  TokenGrouper grouper = TokenGrouper();
  Compiler compiler = Compiler();

  ExpressionParser() {
    tokenizer.setConstant("PI", Math.pi);
    tokenizer.setConstant("pi", Math.pi);
    tokenizer.setConstant("E", Math.e);
    tokenizer.setConstant("e", Math.e);

    // When adding new functions make sure to add them in audioVM.ts applyFunction as well!
    // ^ Make sure the index is consistent between this class and audioVM.ts !
    int index = 0;
    tokenizer.addFunction("sin", false, index++);
    tokenizer.addFunction("cos", false, index++);
    tokenizer.addFunction("tan", false, index++);
    tokenizer.addFunction("sinh", false, index++);
    tokenizer.addFunction("cosh", false, index++);
    tokenizer.addFunction("tanh", false, index++);
    tokenizer.addFunction("asin", false, index++);
    tokenizer.addFunction("arcsin", false, index++);
    tokenizer.addFunction("acos", false, index++);
    tokenizer.addFunction("arccos", false, index++);
    tokenizer.addFunction("atan", false, index++);
    tokenizer.addFunction("arctan", false, index++);
    tokenizer.addFunction("abs", false, index++);
    tokenizer.addFunction("ln", false, index++); // Math.log
    tokenizer.addFunction("log", false, index++); // Math.log(x) / Math.log(10)
    tokenizer.addFunction("floor", false, index++);
    tokenizer.addFunction("ceil", false, index++);
    tokenizer.addFunction("round", false, index++);
    tokenizer.addFunction("mod", true, index++); // a % b
    tokenizer.addFunction("sign", false, index++);
    tokenizer.addFunction("pow", true, index++);
    tokenizer.addFunction("sqrt", false, index++);
    tokenizer.addFunction("exp", false, index++);
    tokenizer.addFunction("min", true, index++);
    tokenizer.addFunction("max", true, index++);
  }

  List<Instruction>? parse(String expression) {
    List<Token> tokens = tokenizer.tokenize(expression);
    Group group = grouper.groupTokens(tokens);
    if (!_verifyGroup(group)) {
      print("Invalid expression");
      return null;
    }
    return compiler.compileGroup(group, tokenizer);
  }

  // Convert instructions to binary format for audioVM
  Float64List toVMFormat(List<Instruction> instructions, Map<String, double> variables) {
    if (variables.containsKey("x")) {
      // TODO: Handle invalid (x is time)
    }

    List<double> data = [];
    _insertVariables(instructions, variables); // Replace PUSHV with PUSCH (from variables map)

    // TODO: Optimize instructions here (precompute everything that can be precomputed)

    data.add(0); // first element in list is the message type
    data.add(_computeMaxStackSize(instructions) as double); // second element in list is the required stack size

    for (Instruction instruction in instructions) {
      data.add(InstructionType.values.indexOf(instruction.type) as double);

      if (instruction.type == InstructionType.FUN || instruction.type == InstructionType.FUN_2) {
        double d = tokenizer.getFunctionIndex(instruction.value!) as double;
        data.add(d);
      } else if (instruction.type == InstructionType.PUSHC) {
        data.add(double.parse(instruction.value!));
      }
    }

    Float64List list = Float64List(data.length);
    list.setAll(0, data);
    return list;
  }

  bool _verifyGroup(Group g) {
    for (GroupToken group in g.tokens) {
      if (group.functionName != null) {
        if (tokenizer.isTwoParamFunction(group.functionName!)) {
          if (group.group == null) {
            return false;
          }
          List<GroupToken> tokens = group.group!.tokens;
          if (tokens.length != 3) {
            return false;
          }
          if (tokens[1].token == null || tokens[1].token!.type != TokenType.COMMA) {
            return false;
          }
          if (tokens[0].group != null) {
            if (!_verifyGroup(tokens[0].group!)) {
              return false;
            }
          }
          if (tokens[2].group != null) {
            if (!_verifyGroup(tokens[2].group!)) {
              return false;
            }
          }
          return true;
        }
      }
    }
    return true;
  }

  int _computeMaxStackSize(List<Instruction> instructions) {
    int stackSize = 0;
    int maxSize = 0;

    for (Instruction instruction in instructions) {
      switch (instruction.type) {
        case InstructionType.ADD:
          stackSize--;
          break;
        case InstructionType.SUB:
          stackSize--;
          break;
        case InstructionType.MUL:
          stackSize--;
          break;
        case InstructionType.DIV:
          stackSize--;
          break;
        case InstructionType.PUSHC:
          stackSize++;
          maxSize = Math.max(stackSize, maxSize);
          break;
        case InstructionType.PUSHV:
          stackSize++;
          maxSize = Math.max(stackSize, maxSize);
          break;
        case InstructionType.NEG:
          break;
        case InstructionType.FUN:
          break;
        case InstructionType.FUN_2:
          stackSize--;
          break;
        case InstructionType.NOP:
          break;
        case InstructionType.PUSH_TIME:
          stackSize++;
          maxSize = Math.max(stackSize, maxSize);
          break;
      }
    }

    return maxSize;
  }

  void _insertVariables(List<Instruction> instructions, Map<String, double> variables) {
    for (Instruction instruction in instructions) {
      if (instruction.type == InstructionType.PUSHV) {
        bool neg = instruction.value![0] == '-';
        String name = instruction.value!;

        if (neg) {
          name = name.substring(1, name.length);
        }

        if (!variables.containsKey(name)) {
          // invalid ..?
          continue;
        }

        instruction.type = InstructionType.PUSHC;
        double value = variables[name]!;
        instruction.value = ((neg ? -1 : 1) * value).toString();
      }
    }
  }
}
