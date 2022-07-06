enum TokenType {
  PARENTHESE,
  CONSTANT,
  VARIABLE,
  FUNCTION,
  FUNCTION_2,
  OPERATOR,
  NEGATION,
  COMMA;

  bool isFunctionToken() {
    return this == FUNCTION || this == FUNCTION_2;
  }
}

class Token<String> {
  String value;
  TokenType type;

  Token(this.value, this.type);
}

class _Function {
  int index;
  bool twoParameters;

  _Function(this.index, this.twoParameters);
}

class Tokenizer {
  Map<String, double> _constants = {};
  Map<String, _Function> _functions = {};

  void setConstant(String name, double value) {
    _constants[name] = value;
  }

  void addFunction(String functionName, bool twoParameters, int index) {
    _functions[functionName] = (_Function(index, twoParameters));
  }

  int? getFunctionIndex(String functionName) {
    _Function? func = _functions[functionName];

    if (func == null) {
      return null;
    }

    return func.index;
  }

  bool isTwoParamFunction(String functionName) {
    return _functions[functionName]!.twoParameters;
  }

  Iterable<String> getSupportedFunctions() {
    return _functions.keys;
  }

  List<Token> tokenize(String s) {
    s = s.replaceAll(RegExp(" +"), "").trim();
    List<Token> tokens = [];

    for (int i = 0; i < s.length; i++) {
      var token = s[i];

      Token? t;

      switch (token) {
        case ',':
          t = Token(token, TokenType.COMMA);
          break;
        case '(':
        case ')':
          t = Token(token, TokenType.PARENTHESE);
          break;
        case '+':
        case '-':
        case '*':
        case '/':
          t = Token(token, TokenType.OPERATOR);
          break;
        default:
          String? value = _searchConstant(s, i);

          if (value != null) {
            t = Token(value, TokenType.CONSTANT);
            i += value.length - 1;
            break;
          }

          String? function = _searchFunction(s, i);

          if (function != null) {
            // TODO: Are there any functions we want to support that take 3 parameters?
            _Function func = _functions[function]!;
            t = Token(function, func.twoParameters ? TokenType.FUNCTION_2 : TokenType.FUNCTION);
            i += function.length - 1;
            break;
          }

          String? constantName = _searchNamedConstant(s, i);

          if (constantName != null) {
            t = Token(_constants[constantName].toString(), TokenType.CONSTANT);
            i += constantName.toString().length - 1;
            break;
          }

          // TODO: Support variables with more than 1 character
          if (token.contains(RegExp("^[a-z A-Z]"))) {
            t = Token(token, TokenType.VARIABLE);
            break;
          }

          break;
      }

      if (t == null) {
        print("invalid token $token"); // TODO: Handle invalid
      } else {
        tokens.add(t);
      }
    }

    // Negations
    for (int i = 0; i < tokens.length; i++) {
      Token token = tokens[i];

      if (token.value == '-') {
        bool broken = false;

        for (int j = i - 1; j >= 0; j--) {
          Token thisToken = tokens[j];

          if (thisToken.type == TokenType.CONSTANT || thisToken.type == TokenType.VARIABLE) {
            broken = true;
            break;
          }

          if (thisToken.type == TokenType.OPERATOR) {
            broken = true;
            tokens[i].type = TokenType.NEGATION;
            break;
          }
        }

        if (!broken) {
          tokens[i].type = TokenType.NEGATION;
        }
      }
    }

    List<Token> toRemove = [];

    for (int i = 0; i < tokens.length; i++) {
      Token token = tokens[i];
      Token? previousToken = i == 0 ? null : tokens[i - 1];

      if (token.type == TokenType.VARIABLE || token.type == TokenType.CONSTANT) {
        if (previousToken != null && previousToken.type == TokenType.NEGATION) {
          token.value = "-" + token.value;
          toRemove.add(previousToken);
        }
      }
    }

    for (Token token in toRemove) {
      tokens.remove(token);
    }

    return tokens;
  }

  String? _searchConstant(String s, int startIndex) {
    String value = "";
    bool dot = false;

    for (int i = startIndex; i < s.length; i++) {
      var char = s[i];

      if (char == '.') {
        if (dot) {
          return null; // TODO: Handle invalid
        }

        dot = true;
        value += ".";
        continue;
      }

      try {
        double.parse(char);
        value += char;
      } catch (ignored) {
        break;
      }
    }

    try {
      double.parse(value);
      return value;
    } catch (e) {
      return null; // TODO: Handle invalid
    }
  }

  String? _searchNamedConstant(String s, int startIndex) {
    s = s.substring(startIndex, s.length);

    for (String constantName in _constants.keys) {
      if (s.startsWith(constantName)) {
        return constantName;
      }
    }

    return null;
  }

  String? _searchFunction(String s, int startIndex) {
    String name = s.substring(startIndex, s.length);

    int idx = name.indexOf("(");

    if (idx != -1) {
      name = name.substring(0, idx);
    }

    if (_functions.containsKey(name)) {
      return name;
    }

    return null;
  }
}
