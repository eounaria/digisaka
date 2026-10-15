import { createApp } from 'vue';
import { createPinia } from 'pinia';
import App from './App.vue';
import router from './router.js';
import { setUnauthorizedHandler, setTokenProvider } from './api.js';
import { useAuthStore } from './stores/auth.js';
import './styles/tokens.css';
import './styles/base.css';
import './styles/motion.css';

const pinia = createPinia();
const app = createApp(App).use(pinia).use(router);

const auth = useAuthStore(pinia);
setTokenProvider(() => auth.token);
setUnauthorizedHandler(() => { auth.signOut(); router.push({ path: '/login', query: { next: router.currentRoute.value.fullPath } }); });
app.mount('#app');
