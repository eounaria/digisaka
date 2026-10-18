import { createStub } from './server.js';

const port = Number(process.env.STUB_PORT) || 9000;
createStub().listen(port, '0.0.0.0', () => console.log(`[stub] listening on :${port}`));
