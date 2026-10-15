<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRoute, useRouter, RouterView } from 'vue-router';
import { useAuthStore } from '../stores/auth.js';
import { useUseCaseStore } from '../stores/useCase.js';
import Icon from '../components/Icon.vue';
import { useAccountMenu } from '../components/useAccountMenu.js';
import { WORKSPACE } from './nav.js';
import '../styles/admin.css';

const scroller = ref(null);
const route = useRoute(), router = useRouter(), uc = useUseCaseStore(), auth = useAuthStore();
const initial = computed(() => auth.initials);
const { menuOpen, narrow, account, avatar, toggleMenu, closeMenu } = useAccountMenu(route);
function leave() { closeMenu(); auth.signOut(); router.push('/login'); }
function toApp() { closeMenu(); router.push('/scan'); }
const to = (screen) => (screen === 'overview' ? '/admin' : `/admin/${screen}`);
const active = computed(() => route.path.replace(/^\/admin\/?/, '').replace(/^workflows\/.*/, 'extractions') || 'overview');
onMounted(() => uc.load().catch(() => {}));
</script>

<template>
  <div class="admin">
    <aside class="side">
      <div class="brand"><span class="mark">🌾</span>DigiSaka</div>
      <p class="group">Workspace</p>
      <nav>
        <button v-for="n in WORKSPACE" :key="n.screen" type="button" class="link" :class="{ active: active === n.screen, off: n.unavailable }" :disabled="n.unavailable" :title="n.unavailable ? 'Not available yet' : undefined" @click="router.push(to(n.screen))">
          <svg viewBox="0 0 24 24" v-html="n.svg"></svg><span>{{ n.label }}</span>
        </button>
      </nav>
      <div class="spacer"></div>
      <div class="foot"><b>AI Knowledge Hub</b>Managing knowledge for {{ uc.cases.length }} use cases.</div>
    </aside>

    <div class="main">
      <header class="top">
        <div class="where"><span class="mark small">🌾</span><span>Digisaka AI</span></div>
        <div class="tools">
          <button v-if="auth.practitioner" type="button" class="exit" @click="router.push('/scan')">&#8617; Digisaka app</button>
          <button type="button" class="exit" @click="leave">Sign out</button>
          <label class="uc"><span>Use Case</span>
            <select :value="uc.slug" @change="uc.select($event.target.value)"><option v-for="c in uc.cases" :key="c.slug" :value="c.slug">{{ c.label }}</option></select>
          </label>
          <div ref="account" class="account">
            <button ref="avatar" type="button" class="avatar" :title="auth.email" aria-label="Account" :tabindex="narrow ? 0 : -1"
                    :aria-expanded="narrow ? menuOpen : undefined" :aria-controls="narrow ? 'admin-account-menu' : undefined" @click="toggleMenu">{{ initial }}</button>
            <div v-if="menuOpen" id="admin-account-menu" class="menu">
              <p class="menu-who">{{ auth.email }}</p>
              <button v-if="auth.practitioner" type="button" class="menu-item" @click="toApp">&#8617; Digisaka app</button>
              <button type="button" class="menu-item" @click="leave">Sign out</button>
            </div>
          </div>
        </div>
      </header>
      <main ref="scroller" class="content">
        <RouterView v-slot="{ Component, route }">
          <Transition name="page" mode="out-in" @after-leave="scroller.scrollTo({ top: 0 })">
            <div :key="route.path" class="route-wrap"><component :is="Component" /></div>
          </Transition>
        </RouterView>
      </main>
    </div>
  </div>
</template>

<style scoped>
.admin { display: grid; grid-template-columns: 276px 1fr; height: 100dvh; }
.side { display: flex; flex-direction: column; padding: 24px 16px 20px; color: #fff; background: linear-gradient(180deg, #087E42, var(--forest-deep)); overflow-y: auto; }
.brand { display: flex; align-items: center; gap: 12px; padding: 0 8px 20px; font: 800 24px var(--font-display); }
.mark { display: grid; place-items: center; width: 36px; height: 36px; border-radius: 11px; background: rgba(255, 255, 255, .14); }
.mark.small { width: 32px; height: 32px; font-size: 16px; background: linear-gradient(135deg, var(--leaf), var(--forest)); }
.group { padding: 14px 12px 8px; font: 800 12px var(--font-display); letter-spacing: .1em; text-transform: uppercase; color: rgba(255, 255, 255, .55); }
nav { display: grid; gap: 3px; }
.link { display: flex; align-items: center; gap: 12px; width: 100%; padding: 11px 14px; border: 0; border-radius: 12px; position: relative; background: none; color: rgba(255, 255, 255, .78); font: 600 14.5px var(--font-body); text-align: left; }
.link svg { width: 18px; height: 18px; flex: none; fill: none; stroke: currentColor; stroke-width: 1.8; stroke-linecap: round; stroke-linejoin: round; }
.link:hover { background: rgba(255, 255, 255, .08); }
.link.active { background: rgba(255, 255, 255, .16); color: #fff; font-weight: 800; }
.link.off { opacity: .45; cursor: not-allowed; }
.link.off:hover { background: none; }
.link:focus-visible { outline-color: #fff; }
.spacer { flex: 1; min-height: 16px; }
.foot { padding: 14px; border-radius: 16px; background: rgba(255, 255, 255, .1); font-size: 13.5px; line-height: 1.4; color: rgba(255, 255, 255, .78); }
.foot b { display: block; margin-bottom: 2px; font: 800 15px var(--font-display); color: #fff; }

.main { display: flex; flex-direction: column; min-width: 0; height: 100dvh; }
.top { display: flex; align-items: center; justify-content: space-between; gap: 12px; height: 72px; padding: 0 var(--gutter); background: #fff; border-bottom: 1px solid var(--line); flex: none; }
.where { display: flex; align-items: center; gap: 12px; font: 800 17px var(--font-display); color: var(--forest); }
.tools { display: flex; align-items: center; gap: 12px; }
.exit { height: 40px; padding: 0 16px; border: 1px solid var(--line); border-radius: 999px; background: #fff; color: var(--forest); font-weight: 800; white-space: nowrap; }
.exit:hover { background: var(--tint); }
.uc { display: flex; align-items: center; gap: 10px; height: 40px; padding: 0 12px 0 16px; border: 1px solid var(--line); border-radius: 999px; font-weight: 800; color: var(--forest); }
.uc select { border: 0; background: transparent; font-weight: 800; color: var(--forest); cursor: pointer; }
.account { position: relative; }
.menu { display: none; }
.menu-who { padding: 8px 12px; font-size: 13px; color: var(--ink-soft); overflow: hidden; text-overflow: ellipsis; }
.menu-item { display: block; width: 100%; padding: 10px 12px; border: 0; border-radius: 10px; background: none; color: var(--forest); font: 800 15px var(--font-body); text-align: left; }
.menu-item:hover { background: var(--tint); }
.avatar { border: 0; display: grid; place-items: center; width: 40px; height: 40px; border-radius: 50%; background: var(--leaf); color: #fff; font: 800 14px var(--font-display); }
.content { flex: 1; min-height: 0; overflow-y: auto; padding: 26px var(--gutter) 40px; }

@media (max-width: 900px) {
  .admin { grid-template-columns: 1fr; grid-template-rows: auto 1fr; height: 100dvh; }
  .side { flex-direction: row; align-items: center; gap: 4px; padding: 8px; overflow-x: auto; }
  .brand, .group, .spacer, .foot { display: none; }
  nav { display: flex; gap: 4px; }
  .link { width: auto; white-space: nowrap; padding: 9px 12px; }
  .main { height: auto; min-height: 0; }
  .where span:last-child, .exit { display: none; }
  .uc span { display: none; }
  .avatar { cursor: pointer; }
  .menu { display: block; position: absolute; top: calc(100% + 8px); right: 0; z-index: 40; min-width: 200px; max-width: calc(100vw - 2 * var(--gutter)); padding: 6px; border: 1px solid var(--line); border-radius: 14px; background: #fff; box-shadow: 0 8px 24px rgba(6, 40, 20, .18); }
}
</style>
