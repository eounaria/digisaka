import { createApp } from 'vue';
import { createPinia } from 'pinia';
import App from './App.vue';
import router from './router.js';
import { setUnauthorizedHandler, setTokenProvider } from './api.js';
import { setSignedOutHandler, signOut, supabase } from './scheduler/session.js';
import './styles/tokens.css';
import './styles/base.css';
import './styles/motion.css';

const pinia = createPinia();
const app = createApp(App).use(pinia).use(router);

const toSignIn = () => router.push({ path: '/sign-in', query: { next: router.currentRoute.value.fullPath } });
setTokenProvider(supabase.getToken);
setUnauthorizedHandler(() => { signOut(); toSignIn(); });
setSignedOutHandler(toSignIn);
app.mount('#app');
