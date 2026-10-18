// Stand-in for the Supabase auth endpoints the web app uses: the password grant and GET /auth/v1/user.
// Tokens are signed with a fixed key so any stub process accepts a token any other issued; they are
// not secrets and mean nothing outside the stub.
import crypto from 'node:crypto';

const KEY = 'digisaka-stub-signing-key';
const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
const sign = (data) => crypto.createHmac('sha256', KEY).update(data).digest('base64url');

export const SAMPLE_USERS = [
  { id: '00000000-0000-4000-8000-000000000001', email: 'farmer@digisaka.test', name: 'Fiona Farmer', roles: ['practitioner'] },
  { id: '00000000-0000-4000-8000-000000000002', email: 'admin@digisaka.test', name: 'Adam Admin', roles: ['administrator'] },
  { id: '00000000-0000-4000-8000-000000000003', email: 'both@digisaka.test', name: 'Bo Both', roles: ['practitioner', 'domain_expert'] },
];

const TTL_SECONDS = 3600;

export function issueToken(user, now = Date.now()) {
  const iat = Math.floor(now / 1000);
  const body = `${b64({ alg: 'HS256', typ: 'JWT' })}.${b64({
    sub: user.id, email: user.email, role: 'authenticated', aud: 'authenticated', iat, exp: iat + TTL_SECONDS,
    app_metadata: { roles: user.roles }, user_metadata: { display_name: user.name },
  })}`;
  return `${body}.${sign(body)}`;
}

// The user a token was issued for, or null for anything forged, garbled or expired.
export function userForToken(token, now = Date.now()) {
  const parts = String(token || '').split('.');
  if (parts.length !== 3) return null;
  const expected = Buffer.from(sign(`${parts[0]}.${parts[1]}`));
  const given = Buffer.from(parts[2]);
  if (expected.length !== given.length || !crypto.timingSafeEqual(expected, given)) return null;
  let claims;
  try { claims = JSON.parse(Buffer.from(parts[1], 'base64url').toString()); } catch { return null; }
  if (!(claims.exp * 1000 > now)) return null;
  return SAMPLE_USERS.find((u) => u.id === claims.sub) || null;
}

// Supabase's own shapes: invalid credentials is a 400 with error_code, a bad token is a 401.
const publicUser = (u) => ({ id: u.id, aud: 'authenticated', role: 'authenticated', email: u.email, app_metadata: { roles: u.roles }, user_metadata: { display_name: u.name } });

export const supabaseRoutes = [
  {
    method: 'POST', path: '/auth/v1/token',
    handle: ({ query, body }) => {
      if (query.get('grant_type') !== 'password') return { status: 400, body: { code: 400, error_code: 'unsupported_grant_type', msg: 'Unsupported grant_type' } };
      const user = SAMPLE_USERS.find((u) => u.email === String(body?.email || '').trim().toLowerCase());
      if (!user || !body.password || body.password === 'wrong') {
        return { status: 400, body: { code: 400, error_code: 'invalid_credentials', msg: 'Invalid login credentials' } };
      }
      return { status: 200, body: { access_token: issueToken(user), token_type: 'bearer', expires_in: TTL_SECONDS, refresh_token: 'stub-refresh', user: publicUser(user) } };
    },
  },
  {
    method: 'GET', path: '/auth/v1/user',
    handle: ({ headers }) => {
      const user = userForToken((headers.authorization || '').replace(/^Bearer\s+/i, ''));
      if (!user) return { status: 401, body: { code: 401, error_code: 'bad_jwt', msg: 'invalid JWT' } };
      return { status: 200, body: publicUser(user) };
    },
  },
];
