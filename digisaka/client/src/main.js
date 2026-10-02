import { createApp } from 'vue';
import { createPinia } from 'pinia';
import App from './App.vue';
import router from './router.js';
import { setUnauthorizedHandler } from './api.js';
import { useAuthStore } from './stores/auth.js';
import './styles/tokens.css';
import './styles/base.css';
import './styles/motion.css';

const pinia = createPinia();
const app = createApp(App).use(pinia).use(router);

setUnauthorizedHandler(() => { useAuthStore().user = null; router.push('/login'); });
app.mount('#app');
