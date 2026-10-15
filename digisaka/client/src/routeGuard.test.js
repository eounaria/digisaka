import { describe, it, expect } from 'vitest';
import { redirectFor, landingFor, safeNext } from './routeGuard.js';

const user = (o) => ({ signedIn: true, practitioner: false, technicalUser: false, ...o });
const out = { signedIn: false, practitioner: false, technicalUser: false };
const shell = { fullPath: '/history', meta: { auth: true } };
const admin = { fullPath: '/admin/users', meta: { auth: true, admin: true } };
const login = { fullPath: '/login', meta: { guest: true } };

describe('where each kind of user lands', () => {
  it('sends a Practitioner to the dashboard and a Technical User without that role to the admin console', () => {
    expect(landingFor(user({ practitioner: true }))).toBe('/');
    expect(landingFor(user({ technicalUser: true }))).toBe('/admin');
    expect(landingFor(user({ technicalUser: true, practitioner: true }))).toBe('/');
  });
});

describe('route guard', () => {
  it('sends a signed-out visitor to the login and remembers where they were going', () => {
    expect(redirectFor(shell, out)).toEqual({ path: '/login', query: { next: '/history' } });
    expect(redirectFor(admin, out)).toEqual({ path: '/login', query: { next: '/admin/users' } });
    expect(redirectFor(login, out)).toBeUndefined();
  });

  it('keeps a signed-in user off the login', () => {
    expect(redirectFor(login, user({ practitioner: true }))).toBe('/');
    expect(redirectFor(login, user({ technicalUser: true }))).toBe('/admin');
  });

  it('sends a Practitioner who types the admin address back to the shell', () => {
    expect(redirectFor(admin, user({ practitioner: true }))).toBe('/');
    expect(redirectFor(admin, user({ technicalUser: true }))).toBeUndefined();
    expect(redirectFor(admin, user({ technicalUser: true, practitioner: true }))).toBeUndefined();
  });

  it('sends a Technical User without the Practitioner role away from the scheduler screens', () => {
    expect(redirectFor(shell, user({ technicalUser: true }))).toBe('/admin');
    expect(redirectFor(shell, user({ practitioner: true }))).toBeUndefined();
    expect(redirectFor(shell, user({ technicalUser: true, practitioner: true }))).toBeUndefined();
  });
});

describe('safeNext', () => {
  it('accepts only same-site paths that are not the login', () => {
    expect(safeNext('/history')).toBe('/history');
    expect(safeNext('//evil.test')).toBeNull();
    expect(safeNext('https://evil.test')).toBeNull();
    expect(safeNext('/login')).toBeNull();
    expect(safeNext(undefined)).toBeNull();
  });
});
