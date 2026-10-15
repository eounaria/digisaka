// Who may open which route. Display logic only: the servers verify the token and enforce access.
export const landingFor = (auth) => (auth.technicalUser && !auth.practitioner ? '/admin' : '/');

// Only same-site paths, never the login itself or an external address.
export const safeNext = (n) => (typeof n === 'string' && /^\/(?!\/)/.test(n) && n !== '/login' ? n : null);

// Returns a redirect target, or undefined to let the navigation through.
export function redirectFor(to, auth) {
  if (to.meta.guest) return auth.signedIn ? landingFor(auth) : undefined;
  if (!to.meta.auth) return undefined;
  if (!auth.signedIn) return { path: '/login', query: { next: to.fullPath } };
  if (to.meta.admin) return auth.technicalUser ? undefined : landingFor(auth);
  if (!auth.practitioner && auth.technicalUser) return '/admin';
}
