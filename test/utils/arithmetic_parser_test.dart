import 'package:flutter_test/flutter_test.dart';
import 'package:share_it/utils/arithmetic_parser.dart';

void main() {
  group('evaluateArithmetic', () {
    // 기본 사칙연산
    test('덧셈', () => expect(evaluateArithmetic('1+2'), 3.0));
    test('뺄셈', () => expect(evaluateArithmetic('5-3'), 2.0));
    test('곱셈', () => expect(evaluateArithmetic('3*4'), 12.0));
    test('나눗셈', () => expect(evaluateArithmetic('10/4'), 2.5));

    // 연산자 우선순위
    test('곱셈이 덧셈보다 우선', () => expect(evaluateArithmetic('2+3*4'), 14.0));
    test('나눗셈이 뺄셈보다 우선', () => expect(evaluateArithmetic('10-6/2'), 7.0));

    // 괄호
    test('괄호로 우선순위 변경', () => expect(evaluateArithmetic('(2+3)*4'), 20.0));
    test('중첩 괄호', () => expect(evaluateArithmetic('((2+3)*2)+1'), 11.0));

    // 음수
    test('음수 시작', () => expect(evaluateArithmetic('-5+3'), -2.0));
    test('음수 피연산자', () => expect(evaluateArithmetic('10+-3'), 7.0));

    // 소수점
    test('소수 덧셈', () => expect(evaluateArithmetic('1.5+2.5'), 4.0));
    test('소수 결과 반올림', () => expect(evaluateArithmetic('10/3'), 3.33));

    // 0으로 나누기
    test('0으로 나누기는 null', () => expect(evaluateArithmetic('5/0'), null));

    // 단순 숫자도 파싱 가능 (연산자 필터링은 호출부에서 처리)
    test('단순 숫자 파싱', () => expect(evaluateArithmetic('42'), 42.0));
    test('빈 문자열은 null', () => expect(evaluateArithmetic(''), null));

    // 잘못된 입력
    test('불완전한 수식은 null', () => expect(evaluateArithmetic('3+'), null));
    test('연산자만 있으면 null', () => expect(evaluateArithmetic('+'), null));
  });
}
