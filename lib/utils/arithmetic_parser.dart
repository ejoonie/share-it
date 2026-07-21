/// 사칙연산 + 괄호를 지원하는 재귀 하강 파서.
/// 결과는 소수점 2자리로 반올림하며, 파싱 실패 시 null 반환.
double? evaluateArithmetic(String expr) {
  try {
    final tokens = _tokenize(expr.trim());
    if (tokens.isEmpty) return null;
    final cursor = _Cursor();
    final result = _parseExpr(tokens, cursor);
    if (cursor.pos != tokens.length) return null; // 파싱 불완전
    return (result * 100).round() / 100;
  } catch (_) {
    return null;
  }
}

List<String> _tokenize(String expr) {
  final tokens = <String>[];
  var i = 0;
  while (i < expr.length) {
    final ch = expr[i];
    if (RegExp(r'[\d.]').hasMatch(ch)) {
      var num = '';
      while (i < expr.length && RegExp(r'[\d.]').hasMatch(expr[i])) {
        num += expr[i++];
      }
      tokens.add(num);
    } else if (ch == '-' &&
        (tokens.isEmpty || ['+', '-', '*', '/', '('].contains(tokens.last))) {
      // 음수 부호
      i++;
      var num = '-';
      while (i < expr.length && RegExp(r'[\d.]').hasMatch(expr[i])) {
        num += expr[i++];
      }
      tokens.add(num);
    } else if (['+', '-', '*', '/', '(', ')'].contains(ch)) {
      tokens.add(ch);
      i++;
    } else {
      i++;
    }
  }
  return tokens;
}

class _Cursor {
  int pos = 0;
}

double _parseExpr(List<String> tokens, _Cursor c) {
  var result = _parseTerm(tokens, c);
  while (c.pos < tokens.length && (tokens[c.pos] == '+' || tokens[c.pos] == '-')) {
    final op = tokens[c.pos++];
    final right = _parseTerm(tokens, c);
    result = op == '+' ? result + right : result - right;
  }
  return result;
}

double _parseTerm(List<String> tokens, _Cursor c) {
  var result = _parseFactor(tokens, c);
  while (c.pos < tokens.length && (tokens[c.pos] == '*' || tokens[c.pos] == '/')) {
    final op = tokens[c.pos++];
    final right = _parseFactor(tokens, c);
    if (op == '/' && right == 0) throw Exception('division by zero');
    result = op == '*' ? result * right : result / right;
  }
  return result;
}

double _parseFactor(List<String> tokens, _Cursor c) {
  if (c.pos < tokens.length && tokens[c.pos] == '(') {
    c.pos++; // '(' 소비
    final result = _parseExpr(tokens, c);
    if (c.pos < tokens.length && tokens[c.pos] == ')') {
      c.pos++; // ')' 소비
    }
    return result;
  }
  if (c.pos >= tokens.length) throw Exception('unexpected end');
  return double.parse(tokens[c.pos++]);
}
