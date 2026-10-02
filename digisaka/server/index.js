import { config } from './config.js';
import { createApp } from './app.js';

createApp().listen(config.port, () => console.log(`Digisaka running at http://localhost:${config.port}`));
