// Throw from any route to answer with a specific status; app.js turns it into { error }.
export class HttpError extends Error {
  constructor(status, message) { super(message); this.status = status; }
}
export const bad = (msg) => new HttpError(400, msg);
export const notFound = (what = 'That item') => new HttpError(404, `${what} could not be found.`);
