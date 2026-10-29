<script setup>
import { ref, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useAuthStore } from '../stores/auth.js';
import { landingFor, safeNext } from '../routeGuard.js';

const router = useRouter(), route = useRoute(), auth = useAuthStore();
const busy = ref(false), error = ref('');
const f = ref({ email: '', password: '' });
const showPassword = ref(false);

// Entrance animation state
const reveal = ref({ logo: false, heading: false, form: false, button: false });

async function submit() {
  busy.value = true; error.value = '';
  try {
    await auth.signIn(f.value.email, f.value.password);
    router.push(safeNext(route.query.next) ?? landingFor(auth));
  } catch (e) { error.value = e.message; }
  finally { busy.value = false; }
}

function togglePassword() {
  showPassword.value = !showPassword.value;
}

// Staggered entrance animation
onMounted(() => {
  const steps = [
    { key: 'logo', delay: 0 },
    { key: 'heading', delay: 100 },
    { key: 'form', delay: 200 },
    { key: 'button', delay: 300 },
  ];
  steps.forEach(({ key, delay }) => {
    setTimeout(() => { reveal.value[key] = true; }, delay);
  });
});
</script>

<template>
  <div class="login-page">
    <!-- LEFT PANEL - Promotional Background -->
    <section class="left-panel" aria-hidden="true">
      <div class="left-content" :class="{ 'is-visible': reveal.logo }">
        <div class="logo-container">
          <div class="logo-box">
            <img src="../assets/bananaleaf1.png" alt="" aria-hidden="true">
          </div>
          <span class="brand-text">Toka AI</span>
        </div>
      </div>

      <div class="left-content promo-wrapper" :class="{ 'is-visible': reveal.heading }">
        <div class="promo-block">
          <h2 class="promo-heading">
            Catch Black Sigatoka<br>
            before it spreads
          </h2>
          <p class="promo-description">
            Scan banana leaves, assess them in<br>
            bulk, and schedule treatment while it<br>
            still works.
          </p>
        </div>
      </div>

      <div class="left-content footer-area" :class="{ 'is-visible': reveal.logo }">
        <p class="footer-text">
          Leads Agricultural Products Corporation
        </p>
      </div>
    </section>

    <!-- RIGHT PANEL - Login Form -->
    <section class="right-panel">
      <form class="login-card" novalidate @submit.prevent="submit">
        <div class="mobile-brand" :class="{ 'is-visible': reveal.logo }" aria-hidden="true">
          <div class="logo-box">
            <img src="../assets/bananaleaf1.png" alt="">
          </div>
          <span class="brand-text">Toka AI</span>
        </div>

        <div class="form-wrapper" :class="{ 'is-visible': reveal.form }">
          <h1 class="login-heading" :class="{ 'is-visible': reveal.heading }">Sign In</h1>
          <p class="login-subtitle" :class="{ 'is-visible': reveal.heading }">Use your Toka AI account.</p>

          <div class="form-group">
            <label class="form-label" for="email">Email</label>
            <div class="input-wrapper">
              <input
                type="email"
                id="email"
                v-model="f.email"
                class="form-input"
                placeholder="Email or Mobile Number"
                autocomplete="email"
                required
                :disabled="busy"
              >
            </div>
          </div>

          <div class="form-group">
            <label class="form-label" for="password">Password</label>
            <div class="input-wrapper">
              <input
                :type="showPassword ? 'text' : 'password'"
                id="password"
                v-model="f.password"
                class="form-input password-input"
                placeholder="Email Password"
                autocomplete="current-password"
                required
                :disabled="busy"
              >
              <button
                type="button"
                class="toggle-password"
                @click="togglePassword"
                :aria-label="showPassword ? 'Hide password' : 'Show password'"
                :aria-pressed="showPassword"
                :disabled="busy"
              >
                <svg viewBox="0 0 24 24" aria-hidden="true" v-if="!showPassword">
                  <path d="M1.5 12S5.5 5 12 5s10.5 7 10.5 7-4 7-10.5 7S1.5 12 1.5 12Z"/>
                  <circle cx="12" cy="12" r="3.2"/>
                </svg>
                <svg viewBox="0 0 24 24" aria-hidden="true" v-else>
                  <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/>
                  <line x1="1" y1="1" x2="23" y2="23"/>
                </svg>
              </button>
            </div>
          </div>

          <div class="remember-me">
            <input type="checkbox" id="rememberMe" v-model="f.rememberMe" :disabled="busy">
            <label for="rememberMe">Remember me</label>
          </div>

          <div class="err" role="alert" v-if="error">{{ error }}</div>

          <button class="signin-button" type="submit" :disabled="busy" :class="{ 'is-visible': reveal.button }">
            <span v-if="busy">Signing in…</span>
            <span v-else>Sign In</span>
          </button>
        </div>
      </form>
    </section>
  </div>
</template>

<style scoped>
.login-page {
  font-family: 'Roboto', Helvetica, Arial, sans-serif;
  color: var(--ink);
  background: #F3F4F6;
  min-height: 100vh;
  min-height: 100dvh;
  display: grid;
  grid-template-columns: 39.31% 1fr;
}

/* ENTRANCE ANIMATIONS */
.left-content,
.form-wrapper,
.mobile-brand {
  opacity: 0;
  transform: translateY(20px);
  transition: opacity 0.5s ease, transform 0.5s ease;
}

.left-content.is-visible,
.form-wrapper.is-visible,
.mobile-brand.is-visible {
  opacity: 1;
  transform: translateY(0);
}

/* Children of form-wrapper animate in when parent is visible */
.form-wrapper .login-heading,
.form-wrapper .login-subtitle,
.form-wrapper .form-group,
.form-wrapper .remember-me,
.form-wrapper .err,
.form-wrapper .signin-button {
  opacity: 0;
  transform: translateY(20px);
  transition: opacity 0.5s ease, transform 0.5s ease;
}

.form-wrapper.is-visible .login-heading,
.form-wrapper.is-visible .login-subtitle,
.form-wrapper.is-visible .form-group,
.form-wrapper.is-visible .remember-me,
.form-wrapper.is-visible .err,
.form-wrapper.is-visible .signin-button {
  opacity: 1;
  transform: translateY(0);
}

/* Stagger delays for form children */
.form-wrapper.is-visible .login-heading { transition-delay: 0ms; }
.form-wrapper.is-visible .login-subtitle { transition-delay: 50ms; }
.form-wrapper.is-visible .form-group:nth-child(1) { transition-delay: 100ms; }
.form-wrapper.is-visible .form-group:nth-child(2) { transition-delay: 150ms; }
.form-wrapper.is-visible .remember-me { transition-delay: 200ms; }
.form-wrapper.is-visible .err { transition-delay: 250ms; }
.form-wrapper.is-visible .signin-button { transition-delay: 300ms; }

@media (prefers-reduced-motion: reduce) {
  .left-content,
  .form-wrapper,
  .form-wrapper .login-heading,
  .form-wrapper .login-subtitle,
  .form-wrapper .form-group,
  .form-wrapper .remember-me,
  .form-wrapper .err,
  .form-wrapper .signin-button,
  .mobile-brand {
    opacity: 1;
    transform: none;
    transition: none;
  }
}

/* LEFT PANEL */
.left-panel {
  min-height: 100vh;
  min-height: 100dvh;
  background-image:
    linear-gradient(
      180deg,
      rgba(227, 255, 241, 0.72) 0%,
      rgba(27, 151, 90, 0.72) 33%,
      rgba(5, 96, 52, 0.72) 66%,
      rgba(18, 63, 41, 0.72) 100%
    ),
    url("../assets/blacksigatoka.png");
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  padding: 40px 48px;
  box-sizing: border-box;
}

.left-content {
  width: 100%;
}

.promo-wrapper {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  padding-bottom: 40px; /* space above footer */
}

.logo-container {
  display: flex;
  align-items: center;
  gap: 10px;
}

.logo-box {
  width: 44px;
  height: 44px;
  border: 1px solid #007A48;
  border-radius: 10px;
  overflow: hidden;
  flex-shrink: 0;
}

.logo-box img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.brand-text {
  font-family: 'Roboto', sans-serif;
  font-size: 24px;
  font-weight: 700;
  color: #006D43;
  line-height: 1;
  white-space: nowrap;
}

.promo-block {
  text-align: left;
}

.promo-heading {
  font-family: 'Roboto', sans-serif;
  font-size: 36px;
  font-weight: 700;
  line-height: 44px;
  color: #8CFF91;
  margin: 0;
}

.promo-description {
  font-family: 'Roboto', sans-serif;
  font-size: 20px;
  font-weight: 400;
  line-height: 28px;
  color: #F2F2F2;
  margin: 24px 0 0 0;
}

.footer-area {
  margin-top: auto;
}

.footer-text {
  font-family: 'Roboto', sans-serif;
  font-size: 16px;
  font-weight: 400;
  color: #9AA5A4;
  margin: 0;
}

/* MOBILE BRAND (shown when left panel hidden) */
.mobile-brand {
  display: none;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  margin-bottom: 32px;
}

.mobile-brand .logo-box {
  width: 48px;
  height: 48px;
}

.mobile-brand .brand-text {
  font-size: 28px;
}

/* RIGHT PANEL */
.right-panel {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px 24px;
  min-height: 100vh;
  min-height: 100dvh;
}

.login-card {
  width: 100%;
  max-width: 483px;
  background: #FFFFFF;
  border: 1px solid #9CA3AF;
  border-radius: 12px;
  padding: 48px 72px;
  box-sizing: border-box;
}

.form-wrapper {
  width: 100%;
}

.login-heading {
  font-family: 'Roboto', sans-serif;
  font-size: 36px;
  font-weight: 700;
  line-height: 43px;
  color: #1C1C1C;
  margin-bottom: 6px;
}

.login-subtitle {
  font-family: 'Roboto', sans-serif;
  font-size: 18px;
  font-weight: 400;
  color: #98A2B3;
  margin-bottom: 36px;
}

.form-group {
  margin-bottom: 24px;
}

.form-label {
  display: block;
  font-family: 'Roboto', sans-serif;
  font-size: 16px;
  font-weight: 400;
  color: #667085;
  margin-bottom: 8px;
}

.input-wrapper {
  position: relative;
  width: 100%;
}

.form-input {
  width: 100%;
  height: 45px;
  padding: 0 20px;
  border: 1px solid var(--line);
  border-radius: 11px;
  background: #FFFFFF;
  font-family: 'Roboto', sans-serif;
  font-size: 14px;
  color: #1C1C1C;
  outline: none;
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}

.form-input:focus {
  border-color: var(--leaf);
  box-shadow: 0 0 0 3px rgba(10, 159, 85, 0.15);
}

.form-input:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.form-input::placeholder {
  color: #98A2B3;
}

.password-input {
  padding-right: 52px;
}

.toggle-password {
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
  width: 20px;
  height: 20px;
  background: none;
  border: none;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
}

.toggle-password:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.toggle-password svg {
  width: 20px;
  height: 20px;
  stroke: #666666;
  fill: none;
}

.remember-me {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 24px 0 32px 0;
}

.remember-me input[type="checkbox"] {
  width: 15px;
  height: 15px;
  border: 1px solid var(--line);
  border-radius: 2px;
  appearance: none;
  cursor: pointer;
  position: relative;
  flex-shrink: 0;
  transition: background-color 0.15s ease, border-color 0.15s ease;
}

.remember-me input[type="checkbox"]:checked {
  background: #006F47;
  border-color: #006F47;
}

.remember-me input[type="checkbox"]:checked::after {
  content: '';
  position: absolute;
  left: 4px;
  top: 1px;
  width: 4px;
  height: 8px;
  border: solid white;
  border-width: 0 2px 2px 0;
  transform: rotate(45deg);
}

.remember-me input[type="checkbox"]:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.remember-me label {
  font-family: 'Roboto', sans-serif;
  font-size: 14px;
  font-weight: 400;
  color: #111111;
  cursor: pointer;
  user-select: none;
}

.err {
  color: var(--danger);
  font-weight: 700;
  font-size: 14px;
  margin-bottom: 16px;
  min-height: 1.3em;
}

.signin-button {
  width: 100%;
  height: 52px;
  background: #006F47;
  border: none;
  border-radius: 10px;
  font-family: 'Roboto', sans-serif;
  font-size: 16px;
  font-weight: 700;
  color: #FFFFFF;
  cursor: pointer;
  transition: background-color 0.15s ease, transform 0.1s ease;
}

.signin-button:hover:not(:disabled) {
  background: #005A3A;
}

.signin-button:active:not(:disabled) {
  background: #004D30;
  transform: scale(0.98);
}

.signin-button:disabled {
  opacity: 0.6;
  cursor: wait;
}

.signin-button:focus-visible {
  outline: 3px solid #006F47;
  outline-offset: 2px;
}

/* RESPONSIVE DESIGN */
@media (max-width: 1439px) {
  .login-page {
    grid-template-columns: 39.31% 1fr;
  }
  .left-panel {
    padding: 32px 40px;
  }
  .login-card {
    padding: 40px 48px;
  }
  .promo-heading {
    font-size: 32px;
    line-height: 40px;
  }
  .promo-description {
    font-size: 18px;
    line-height: 26px;
  }
}

@media (max-width: 1023px) {
  .login-page {
    grid-template-columns: 1fr;
  }
  .left-panel {
    display: none;
  }
  .right-panel {
    padding: 32px 20px;
  }
  .login-card {
    max-width: 100%;
    padding: 32px 24px;
    border-radius: 16px;
  }
  .mobile-brand {
    display: flex;
  }
  .login-heading {
    font-size: 32px;
    line-height: 40px;
  }
  .login-subtitle {
    font-size: 16px;
  }
  .form-input {
    height: 48px;
    font-size: 16px;
  }
}

@media (max-width: 767px) {
  .login-page {
    grid-template-columns: 1fr;
  }
  .left-panel {
    display: none;
  }
  .right-panel {
    width: 100%;
    padding: 24px 16px 40px;
    align-items: flex-start;
  }
  .login-card {
    width: 100%;
    max-width: none;
    padding: 24px 20px;
    border-radius: 16px;
  }
  .mobile-brand {
    display: flex;
    margin-bottom: 24px;
  }
  .mobile-brand .logo-box {
    width: 40px;
    height: 40px;
  }
  .mobile-brand .brand-text {
    font-size: 24px;
  }
  .login-heading {
    font-size: 28px;
    line-height: 36px;
  }
  .login-subtitle {
    font-size: 16px;
    margin-bottom: 28px;
  }
  .form-label {
    font-size: 15px;
  }
  .form-input {
    height: 48px;
    font-size: 16px;
    padding: 0 16px;
  }
  .password-input {
    padding-right: 48px;
  }
  .remember-me {
    margin: 20px 0 28px 0;
  }
  .signin-button {
    height: 48px;
    font-size: 16px;
  }
}

@media (max-height: 700px) {
  .promo-content,
  .promo-description {
    display: none;
  }
}
</style>