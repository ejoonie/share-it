import 'package:flutter_test/flutter_test.dart';
import 'package:share_it/api/api_client.dart';

void main() {
  group('buildQueryString', () {
    test('단일 string 값', () {
      final result = buildQueryString({'q[kind_eq]': 'expense'});
      expect(result, 'q%5Bkind_eq%5D=expense');
    });

    test('복수 string 값', () {
      final result = buildQueryString({
        'q[occurred_at_gteq]': '2024-06-01T00:00:00.000Z',
        'q[occurred_at_lt]': '2024-07-01T00:00:00.000Z',
      });
      expect(result, contains('q%5Boccurred_at_gteq%5D=2024-06-01T00%3A00%3A00.000Z'));
      expect(result, contains('q%5Boccurred_at_lt%5D=2024-07-01T00%3A00%3A00.000Z'));
    });

    test('list 값은 같은 키를 반복해서 인코딩', () {
      final result = buildQueryString({'q[kind_in][]': ['income', 'expense']});
      expect(result, 'q%5Bkind_in%5D%5B%5D=income&q%5Bkind_in%5D%5B%5D=expense');
    });

    test('list 값이 하나일 때', () {
      final result = buildQueryString({'q[kind_in][]': ['expense']});
      expect(result, 'q%5Bkind_in%5D%5B%5D=expense');
    });

    test('list + string 혼합', () {
      final result = buildQueryString({
        'q[kind_in][]': ['income', 'expense'],
        'q[occurred_at_gteq]': '2024-06-01T00:00:00.000Z',
      });
      expect(result, contains('q%5Bkind_in%5D%5B%5D=income'));
      expect(result, contains('q%5Bkind_in%5D%5B%5D=expense'));
      expect(result, contains('q%5Boccurred_at_gteq%5D=2024-06-01T00%3A00%3A00.000Z'));
    });

    test('int 값은 문자열로 변환', () {
      final result = buildQueryString({'page': 2});
      expect(result, 'page=2');
    });

    test('빈 map 은 빈 문자열 반환', () {
      final result = buildQueryString({});
      expect(result, '');
    });

    test('특수문자 포함 값은 퍼센트 인코딩', () {
      final result = buildQueryString({'q[title_cont]': 'hello world & more'});
      expect(result, 'q%5Btitle_cont%5D=hello+world+%26+more');
    });
  });
}
