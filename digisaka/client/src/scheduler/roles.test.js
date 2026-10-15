import { describe, it, expect } from 'vitest';
import { profileFromToken, isTechnicalUser } from './roles.js';

const jwt = (payload) => `h.${btoa(JSON.stringify(payload)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')}.s`;

describe('profileFromToken', () => {
  it('reads the email and app_metadata.roles', () => {
    expect(profileFromToken(jwt({ email: 'a@b.co', app_metadata: { roles: ['administrator', 'practitioner'] } }))).toEqual({ email: 'a@b.co', roles: ['administrator', 'practitioner'] });
  });
  it('gives no roles for a missing claim or an unreadable token', () => {
    expect(profileFromToken(jwt({ email: 'a@b.co' })).roles).toEqual([]);
    expect(profileFromToken('garbage')).toEqual({ email: '', roles: [] });
    expect(profileFromToken(null)).toEqual({ email: '', roles: [] });
  });
});

describe('isTechnicalUser', () => {
  it('accepts the three Technical User roles and rejects Practitioner', () => {
    for (const r of ['administrator', 'domain_expert', 'plant_pathologist']) expect(isTechnicalUser([r])).toBe(true);
    expect(isTechnicalUser(['practitioner'])).toBe(false);
    expect(isTechnicalUser([])).toBe(false);
  });
});
