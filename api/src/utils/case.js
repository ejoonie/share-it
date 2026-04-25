// utils/case.js
// snake_case, kebab-case, PascalCase 등 → camelCase 변환 유틸
const _ = require('lodash');


function keysToCamel(obj) {
  if (Array.isArray(obj)) {
    return obj.map(v => keysToCamel(v));
  } else if (obj !== null && obj.constructor === Object) {
    return Object.entries(obj).reduce(
      (result, [key, value]) => ({
        ...result,
        [_.camelCase(key)]: keysToCamel(value),
      }),
      {}
    );
  }
  return obj;
}

function keysToSnake(obj) {
  if (Array.isArray(obj)) {
    return obj.map(v => keysToSnake(v));
  } else if (obj !== null && obj.constructor === Object) {
    return Object.entries(obj).reduce(
      (result, [key, value]) => ({
        ...result,
        [_.snakeCase(key)]: keysToSnake(value),
      }),
      {}
    );
  }
  return obj;
}

module.exports = {
  keysToCamel,
  keysToSnake,
};
