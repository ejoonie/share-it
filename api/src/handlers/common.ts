import type { APIGatewayProxyResult } from 'aws-lambda';

export interface ParseJsonBodyResult<T = Record<string, unknown>> {
  ok: boolean;
  body: T | null;
}

export const createResponse = (statusCode: number, body: unknown): APIGatewayProxyResult => ({
  statusCode,
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify(body),
});

export function getUserId(headers: Record<string, string | undefined> = {}): string | undefined {
  return headers['x-user-id'] ?? headers['X-User-Id'];
}

export function parseJsonBody(rawBody: string | null | undefined): ParseJsonBodyResult {
  try {
    return { ok: true, body: JSON.parse(rawBody ?? '{}') as Record<string, unknown> };
  } catch {
    return { ok: false, body: null };
  }
}
