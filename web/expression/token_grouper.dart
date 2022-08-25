import '../main.dart';
import '../util/stack.dart';
import 'tokenizer.dart';

class GroupToken {
  Token? token;
  String? functionName;
  Group? group;
  bool negated = false;
}

class Group {
  List<GroupToken> tokens = [];
}

class TokenGrouper {
  Group groupTokens(List<Token> tokens) {
    Stack<Group> groups = Stack();
    Group startingGroup = Group();
    groups.push(startingGroup);

    Token? previousToken;
    int index = 0;

    for (Token token in tokens) {
      if (token.value == '(') {
        Group g = Group();

        GroupToken gt = GroupToken();
        gt.group = g;

        if (previousToken != null) {
          if (previousToken.type.isFunctionToken()) {
            gt.functionName = previousToken.value;

            if (index > 1 && tokens[index - 2].type == TokenType.NEGATION) {
              gt.negated = true;
            }
          } else if (previousToken.type == TokenType.NEGATION) {
            gt.negated = true;
          }
        }

        groups.peek.tokens.add(gt);

        groups.push(g);
      } else if (token.value == ')') {
        groups.pop();
      } else if (!token.type.isFunctionToken() && token.type != TokenType.NEGATION) {
        GroupToken gt = GroupToken();
        gt.token = token;
        groups.peek.tokens.add(gt);
      }

      previousToken = token;
      index++;
    }

    _explicifyMultiplies(startingGroup);
    _groupPriority(startingGroup, true); // Group multiply & divide
    // _groupPriority(startingGroup, false); // Group add and subtract

    return startingGroup;
  }

  bool verifyGroups(Group g) {
    for (GroupToken group in g.tokens) {
      if (group.functionName != null) {
        if (audioManager.parser.tokenizer.isTwoParamFunction(group.functionName!)) {
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
          if (tokens[0].group is GroupToken) {
            if (!verifyGroups(tokens[0].group!)) {
              return false;
            }
          }
          if (tokens[2].group is GroupToken) {
            if (!verifyGroups(tokens[2].group!)) {
              return false;
            }
          }
          return true;
        }
      }
    }
    return true;
  }

  String visualizeGroup(Group g) {
    String str = "";

    for (GroupToken t in g.tokens) {
      // check if leaf
      if (t.token != null) {
        str += t.token!.value;
      } else if (t.group != null) {
        // if negative add minus sign
        if (t.negated) {
          str += "-";
        }

        // is function
        if (t.functionName != null) {
          str += t.functionName!;
        }

        // add the sub tokens of this token to the string
        str += visualizeGroup(t.group!);
      }
    }

    return "($str)";
  }

  void _groupPriority(Group startingGroup, bool firstPass) {
    for (int index = 0; index < startingGroup.tokens.length; index++) {
      GroupToken t = startingGroup.tokens[index];

      if (t.token != null) {
        Token token = t.token!;

        if (token.value == '*' || token.value == '/' || (!firstPass && (token.value == '+' || token.value == '-'))) {
          GroupToken gt = GroupToken();
          gt.group = Group();

          GroupToken left = startingGroup.tokens[index - 1];
          GroupToken right = startingGroup.tokens[index + 1];

          if (right.group != null) {
            _groupPriority(right.group!, firstPass);
          }

          gt.group!.tokens.add(left);

          GroupToken operator = GroupToken();
          operator.token = token;
          gt.group!.tokens.add(operator);

          gt.group!.tokens.add(right);

          startingGroup.tokens.insert(index, gt);
          index--;

          startingGroup.tokens.remove(right);
          startingGroup.tokens.remove(t);
          startingGroup.tokens.remove(left);
        }
      } else if (t.group != null) {
        _groupPriority(t.group!, firstPass);
      }
    }
  }

  void _explicifyMultiplies(Group startingGroup) {
    for (int index = 0; index < startingGroup.tokens.length; index++) {
      GroupToken t = startingGroup.tokens[index];
      GroupToken? previousToken = index == 0 ? null : startingGroup.tokens[index - 1];

      if (t.group != null) {
        _explicifyMultiplies(t.group!);
      }

      if (previousToken != null) {
        bool a = previousToken.group != null ||
            (previousToken.token != null && (previousToken.token!.type == TokenType.VARIABLE || previousToken.token!.type == TokenType.CONSTANT));

        bool b = t.group != null || (t.token != null && (t.token!.type == TokenType.VARIABLE || t.token!.type == TokenType.CONSTANT));

        if (a && b) {
          GroupToken gt = GroupToken();
          gt.token = Token("*", TokenType.OPERATOR);
          startingGroup.tokens.insert(index, gt);
          index++;
        }
      }
    }
  }
}
