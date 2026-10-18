<script setup>
import { ref, computed } from 'vue';
import { useRoute, useRouter, RouterLink, RouterView } from 'vue-router';
import { useAuthStore } from '../stores/auth.js';
import Icon from './Icon.vue';
import { useAccountMenu } from './useAccountMenu.js';

const scroller = ref(null);
const route = useRoute(), router = useRouter(), auth = useAuthStore();
const title = computed(() => route.meta.title || 'Digisaka');

const MENU = [
  { to: '/', label: 'Dashboard', icon: 'home' },
  { to: '/scan', label: 'Disease Detection', icon: 'scan' },
  { to: '/history', label: 'Diagnosis History', icon: 'history' },
  { to: '/schedule', label: 'Treatment Schedule', icon: 'calendar' },
];

const { menuOpen, narrow, account, avatar, toggleMenu, closeMenu } = useAccountMenu(route);
function signOut() { closeMenu(); auth.signOut(); router.push('/login'); }
</script>

<template>
  <div class="shell">
    <aside class="sidebar">
      <div class="brand"><span class="mark">🍌</span>Digisaka</div>
      <p class="group">Menu</p>
      <nav>
        <RouterLink v-for="m in MENU" :key="m.to" :to="m.to" class="link" :active-class="m.to === '/' ? '' : 'active'" exact-active-class="active">
          <Icon :name="m.icon" :size="18" /><span>{{ m.label }}</span>
        </RouterLink>
      </nav>
      <p class="group">Account</p>
      <nav>
        <p class="who">{{ auth.email }}</p>
        <button class="link signout" type="button" @click="signOut"><Icon name="logout" :size="18" /><span>Sign out</span></button>
      </nav>
      <div class="spacer"></div>
      <div class="foot">
        <b>Black Sigatoka AI</b>On-device leaf analysis for early disease detection.
        <RouterLink v-if="auth.technicalUser" to="/admin" class="admin-link">🛠️ Switch to Admin Web</RouterLink>
      </div>
    </aside>

    <div class="main">
      <header class="topbar">
        <div class="where"><span class="mark small">🍌</span><h2>{{ title }}</h2></div>
        <div class="tools">
          <RouterLink to="/scan" class="pill"><Icon name="scan" :size="15" />New Scan</RouterLink>
          <div ref="account" class="account">
            <button ref="avatar" type="button" class="avatar" :title="auth.email" aria-label="Account" :tabindex="narrow ? 0 : -1"
                    :aria-expanded="narrow ? menuOpen : undefined" :aria-controls="narrow ? 'account-menu' : undefined" @click="toggleMenu">{{ auth.initials }}</button>
            <div v-if="menuOpen" id="account-menu" class="menu">
              <p class="menu-who">{{ auth.email }}</p>
              <button type="button" class="menu-out" @click="signOut"><Icon name="logout" :size="18" /><span>Sign out</span></button>
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
.shell { display: grid; grid-template-columns: var(--sidebar-w) 1fr; height: 100dvh; }
.sidebar { display: flex; flex-direction: column; padding: 24px 16px 20px; color: #fff; background: linear-gradient(180deg, #087E42, var(--forest-deep)); overflow-y: auto; }
.brand { display: flex; align-items: center; gap: 12px; padding: 0 8px 22px; font: 800 24px var(--font-display); }
.mark { display: grid; place-items: center; width: 36px; height: 36px; border-radius: 11px; background: rgba(255, 255, 255, .14); font-size: 20px; }
.mark.small { width: 32px; height: 32px; font-size: 17px; background: linear-gradient(135deg, var(--leaf), var(--forest)); box-shadow: 0 4px 10px rgba(8, 120, 63, .25); }
.who { padding: 4px 14px 8px; font-size: 13px; color: rgba(255, 255, 255, .6); overflow: hidden; text-overflow: ellipsis; }
.group { padding: 14px 12px 8px; font: 800 12px var(--font-display); letter-spacing: .1em; text-transform: uppercase; color: rgba(255, 255, 255, .55); }
nav { display: grid; gap: 4px; }
.link { display: flex; align-items: center; gap: 12px; width: 100%; padding: 12px 14px; border: 1px solid transparent; border-radius: 14px; background: none; color: rgba(255, 255, 255, .78); font: 700 15px var(--font-body); text-align: left; transition: background .15s; }
.link:hover { background: rgba(255, 255, 255, .08); }
.link.active { background: rgba(255, 255, 255, .16); border-color: rgba(255, 255, 255, .2); color: #fff; }
.link:focus-visible { outline-color: #fff; }
.spacer { flex: 1; min-height: 16px; }
.foot { padding: 14px; border-radius: 16px; background: rgba(255, 255, 255, .1); font-size: 13.5px; line-height: 1.4; color: rgba(255, 255, 255, .78); }
.foot b { display: block; margin-bottom: 2px; font: 800 15px var(--font-display); color: #fff; }
.admin-link { display: block; margin-top: 12px; padding: 9px 10px; border-radius: 10px; background: rgba(255, 255, 255, .14); color: #fff; font-weight: 800; text-align: center; }
.main { display: flex; flex-direction: column; min-width: 0; height: 100dvh; }
.topbar { display: flex; align-items: center; justify-content: space-between; gap: 12px; height: var(--header-h); padding: 0 var(--gutter); background: #fff; border-bottom: 1px solid var(--line); flex: none; }
.where { display: flex; align-items: center; gap: 12px; min-width: 0; }
.where h2 { font: 800 20px var(--font-display); color: var(--forest); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.tools { display: flex; align-items: center; gap: 10px; }
.pill { display: inline-flex; align-items: center; gap: 8px; height: 40px; padding: 0 18px; border: 1px solid var(--line); border-radius: 999px; background: #fff; color: var(--forest); font: 800 15px var(--font-display); }
.pill:hover { background: var(--tint); }
.round, .avatar { position: relative; border: 0; display: grid; place-items: center; width: 40px; height: 40px; border-radius: 50%; }
.round { background: var(--tint); color: var(--forest); }
.avatar { background: var(--leaf); color: #fff; font: 800 14px var(--font-display); }
.account { position: relative; }
.menu { display: none; }
.menu-who { padding: 8px 12px; font-size: 13px; color: var(--ink-soft); overflow: hidden; text-overflow: ellipsis; }
.menu-out { display: flex; align-items: center; gap: 10px; width: 100%; padding: 10px 12px; border: 0; border-radius: 10px; background: none; color: var(--forest); font: 800 15px var(--font-body); }
.menu-out:hover { background: var(--tint); }
.dot { position: absolute; top: 8px; right: 9px; width: 9px; height: 9px; border-radius: 50%; background: var(--warn); border: 2px solid #fff; }
.content { flex: 1; min-height: 0; overflow-y: auto; }
@media (max-width: 900px) {
  .shell { grid-template-columns: 1fr; }
  .sidebar { position: fixed; inset: auto 0 0 0; z-index: 30; flex-direction: row; padding: 6px 6px calc(6px + env(safe-area-inset-bottom, 0px)); height: calc(var(--tabbar-h) + env(safe-area-inset-bottom, 0px)); box-shadow: 0 -4px 16px rgba(6, 40, 20, .2); overflow: visible; }
  .brand, .group, .spacer, .foot, .signout, .who { display: none; }
  nav { display: contents; }
  .link { flex: 1; min-width: 0; flex-direction: column; justify-content: center; gap: 3px; padding: 4px 2px; font-size: 11px; line-height: 1.1; text-align: center; }
  .pill, .where h2 { display: none; }
  .avatar { cursor: pointer; }
  .menu { display: block; position: absolute; top: calc(100% + 8px); right: 0; z-index: 40; min-width: 200px; max-width: calc(100vw - 2 * var(--gutter)); padding: 6px; border: 1px solid var(--line); border-radius: 14px; background: #fff; box-shadow: 0 8px 24px rgba(6, 40, 20, .18); }
  .tools { gap: 8px; }
}
</style>
