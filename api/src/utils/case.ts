// utils/case.ts
// snake_case, kebab-case, PascalCase 등 → camelCase 변환 유틸
import _ from 'lodash';

type AnyValue = Record<string, unknown> | unknown[] | unknown;

function keysToCamel(obj: AnyValue): AnyValue {
  if (Array.isArray(obj)) {
    return obj.map((v) => keysToCamel(v));
  } else if (obj !== null && typeof obj === 'object' && obj.constructor === Object) {
    return Object.entries(obj as Record<string, unknown>).reduce<Record<string, unknown>>(
      (result, [key, value]) => ({
        ...result,
        [_.camelCase(key)]: keysToCamel(value),
      }),
      {},
    );
  }
  return obj;
}

function keysToSnake(obj: AnyValue): AnyValue {
  if (Array.isArray(obj)) {
    return obj.map((v) => keysToSnake(v));
  } else if (obj !== null && typeof obj === 'object' && obj.constructor === Object) {
    return Object.entries(obj as Record<string, unknown>).reduce<Record<string, unknown>>(
      (result, [key, value]) => ({
        ...result,
        [_.snakeCase(key)]: keysToSnake(value),
      }),
      {},
    );
  }
  return obj;
}

export { keysToCamel, keysToSnake };
