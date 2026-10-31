<script setup>
import { ref, computed, onMounted, onBeforeUnmount, watch } from 'vue';
import { useRoute, useRouter, RouterView } from 'vue-router';
import { useAuthStore } from '../stores/auth.js';
import { useUseCaseStore } from '../stores/useCase.js';
import Icon from '../components/Icon.vue';
import { useAccountMenu } from '../components/useAccountMenu.js';
import { WORKSPACE } from './nav.js';
import '../styles/admin.css';

const scroller = ref(null);
const route = useRoute();
const router = useRouter();
const uc = useUseCaseStore();
const auth = useAuthStore();

const initial = computed(() => auth.initials);
const { menuOpen, narrow, account, avatar, toggleMenu, closeMenu } = useAccountMenu(route);
const sidebarOpen = ref(false);
const active = computed(() => {
  const path = route.path.replace(/^\/admin\/?/, '');
  if (path.startsWith('workflows/')) return 'extractions';
  return path || 'overview';
});

function leave() { closeMenu(); auth.signOut(); router.push('/login'); }
function toApp() { closeMenu(); router.push('/scan'); }
const to = (screen) => (screen === 'overview' ? '/admin' : `/admin/${screen}`);

// Close sidebar on route change (mobile)
watch(route, () => { if (narrow.value) sidebarOpen.value = false; });

onMounted(() => uc.load().catch(() => {}));
</script>

<template>
  <div class="admin-layout">
    <!-- Sidebar backdrop (mobile) -->
    <div
      v-if="narrow"
      class="sidebar-backdrop"
      :class="{ 'sidebar-backdrop--visible': sidebarOpen }"
      @click="sidebarOpen = false"
      aria-hidden="true"
    ></div>

    <!-- Sidebar -->
    <aside id="admin-sidebar" class="sidebar" :class="{ 'sidebar--open': sidebarOpen, 'sidebar--narrow': narrow }">
      <!-- Decorative banana leaves - top -->
      <div class="leaf-decoration leaf-decoration--top" aria-hidden="true">
        <svg viewBox="0 0 200 200" fill="currentColor" class="leaf-svg">
          <path d="M100 0 C60 0 30 30 20 60 C10 90 30 130 60 150 C90 170 130 170 160 150 C190 130 190 90 180 60 C170 30 140 0 100 0 Z" />
          <path d="M100 10 C70 10 45 35 38 65 C31 95 45 135 75 150 C105 165 145 155 162 135 C179 115 185 80 175 50 C165 20 130 10 100 10 Z" opacity="0.5"/>
        </svg>
      </div>

      <div class="sidebar-content">
        <!-- Branding -->
        <div class="sidebar-brand">
          <span class="sidebar-mark" aria-hidden="true">🌾</span>
          <span class="sidebar-title">DigiSaka</span>
        </div>

        <!-- Navigation -->
        <nav class="sidebar-nav" aria-label="Admin navigation">
          <h2 class="sidebar-section">Workspace</h2>
          <ul class="sidebar-list" role="list">
            <li v-for="n in WORKSPACE" :key="n.screen">
              <button
                v-if="n.unavailable"
                type="button"
                class="sidebar-link sidebar-link--unavailable"
                :title="'Not available yet'"
                disabled
              >
                <svg viewBox="0 0 24 24" class="sidebar-icon" v-html="n.svg" aria-hidden="true"></svg>
                <span class="sidebar-label">{{ n.label }}</span>
                <span class="sidebar-badge" aria-label="Not available">Soon</span>
              </button>
              <button
                v-else
                type="button"
                class="sidebar-link"
                :class="{ 'sidebar-link--active': active === n.screen }"
                @click="router.push(to(n.screen))"
              >
                <svg viewBox="0 0 24 24" class="sidebar-icon" v-html="n.svg" aria-hidden="true"></svg>
                <span class="sidebar-label">{{ n.label }}</span>
              </button>
            </li>
          </ul>
        </nav>

        <!-- Spacer pushes sign-out to bottom -->
        <div class="sidebar-spacer"></div>

        <!-- Sign Out -->
        <div class="sidebar-footer">
          <button
            type="button"
            class="sidebar-signout"
            @click="leave"
          >
            <svg viewBox="0 0 24 24" class="sidebar-icon" aria-hidden="true">
              <path d="M9 4H5v16h4"></path>
              <path d="M16 8l4 4-4 4"></path>
              <path d="M20 12H9"></path>
            </svg>
            <span>Sign out</span>
          </button>
        </div>
      </div>

      <!-- Decorative banana leaves - bottom -->
      <div class="leaf-decoration leaf-decoration--bottom" aria-hidden="true">
        <svg viewBox="0 0 200 200" fill="currentColor" class="leaf-svg">
          <path d="M100 0 C60 0 30 30 20 60 C10 90 30 130 60 150 C90 170 130 170 160 150 C190 130 190 90 180 60 C170 30 140 0 100 0 Z" />
          <path d="M100 10 C70 10 45 35 38 65 C31 95 45 135 75 150 C105 165 145 155 162 135 C179 115 185 80 175 50 C165 20 130 10 100 10 Z" opacity="0.5"/>
        </svg>
      </div>
    </aside>

    <!-- Main content area -->
    <div class="admin-main">
      <!-- Topbar -->
      <header class="topbar">
        <div class="topbar-brand">
          <span class="topbar-mark" aria-hidden="true">🌾</span>
          <span class="topbar-title">DigiSaka AI</span>
        </div>
        <div class="topbar-tools">
          <!-- Mobile hamburger menu -->
          <button
            v-if="narrow"
            type="button"
            class="topbar-hamburger"
            @click="sidebarOpen = true"
            aria-label="Open navigation"
            aria-expanded="sidebarOpen"
            aria-controls="admin-sidebar"
          >
            <svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
              <line x1="3" y1="6" x2="21" y2="6"></line>
              <line x1="3" y1="12" x2="21" y2="12"></line>
              <line x1="3" y1="18" x2="21" y2="18"></line>
            </svg>
          </button>
          <button v-if="auth.practitioner" type="button" class="topbar-btn" @click="toApp">
            ⮐ Digisaka app
          </button>
          <label class="topbar-usecase">
            <span>Use Case</span>
            <select
              :value="uc.slug"
              @change="uc.select($event.target.value)"
              aria-label="Select use case"
            >
              <option v-for="c in uc.cases" :key="c.slug" :value="c.slug">{{ c.label }}</option>
            </select>
          </label>
          <div ref="account" class="topbar-account">
            <button
              ref="avatar"
              type="button"
              class="topbar-avatar"
              :title="auth.email"
              aria-label="Account"
              :tabindex="narrow ? 0 : -1"
              :aria-expanded="narrow ? menuOpen : undefined"
              :aria-controls="narrow ? 'admin-account-menu' : undefined"
              @click="toggleMenu"
            >{{ initial }}</button>
            <div v-if="menuOpen" id="admin-account-menu" class="topbar-menu">
              <p class="topbar-menu-who">{{ auth.email }}</p>
              <button v-if="auth.practitioner" type="button" class="topbar-menu-item" @click="toApp">⮐ Digisaka app</button>
              <button type="button" class="topbar-menu-item" @click="leave">Sign out</button>
            </div>
          </div>
        </div>
      </header>

      <!-- Page content -->
      <main ref="scroller" class="admin-content">
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
/* Admin layout grid */
.admin-layout {
  display: grid;
  grid-template-columns: var(--sidebar-w) 1fr;
  height: 100dvh;
  min-height: 100vh;
}

/* Sidebar - full height, dark forest green */
.sidebar {
  position: relative;
  display: flex;
  flex-direction: column;
  background: linear-gradient(180deg, var(--forest) 0%, var(--forest-deep) 100%);
  color: #fff;
  overflow: hidden;
  z-index: 20;
}

/* Decorative banana leaves - prominent silhouette accents */
.leaf-decoration {
  position: absolute;
  pointer-events: none;
  z-index: 0;
  opacity: 0.12;
  color: rgba(255, 255, 255, 0.25);
}
.leaf-decoration--top {
  top: -60px;
  right: -40px;
  width: 220px;
  height: 220px;
}
.leaf-decoration--bottom {
  bottom: -70px;
  left: -50px;
  width: 260px;
  height: 260px;
  transform: rotate(180deg);
}
.leaf-svg {
  width: 100%;
  height: 100%;
}

/* Sidebar content sits above decorations - no scrolling, fixed height */
.sidebar-content {
  position: relative;
  z-index: 1;
  display: flex;
  flex-direction: column;
  height: 100%;
  padding: clamp(16px, 3vh, 24px) clamp(12px, 2vw, 16px) clamp(12px, 2vh, 20px);
}

/* Branding */
.sidebar-brand {
  display: flex;
  align-items: center;
  gap: clamp(10px, 2vw, 12px);
  padding: 0 clamp(6px, 1vw, 8px) clamp(12px, 2.5vh, 16px);
  font: 800 clamp(20px, 3vw, 24px) var(--font-display);
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
  margin-bottom: clamp(6px, 1vh, 10px);
}
.sidebar-mark {
  display: grid;
  place-items: center;
  width: clamp(32px, 5vw, 36px);
  height: clamp(32px, 5vw, 36px);
  border-radius: 11px;
  background: rgba(255, 255, 255, 0.12);
  font-size: clamp(18px, 3vw, 20px);
  flex-shrink: 0;
}
.sidebar-title {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* Navigation - no scrolling, fits in viewport */
.sidebar-nav {
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
}
.sidebar-section {
  padding: clamp(8px, 1.5vh, 10px) clamp(8px, 1.5vw, 12px) clamp(4px, 0.5vh, 6px);
  font: 800 clamp(10px, 1.5vw, 12px) var(--font-display);
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: rgba(255, 255, 255, 0.5);
}
.sidebar-list {
  display: grid;
  gap: clamp(1px, 0.3vh, 2px);
  padding: 0 clamp(4px, 1vw, 8px);
}
.sidebar-link {
  display: flex;
  align-items: center;
  gap: clamp(10px, 2vw, 12px);
  width: 100%;
  padding: clamp(9px, 1.8vh, 10px) clamp(10px, 2vw, 14px);
  border: 0;
  border-radius: clamp(10px, 1.5vw, 12px);
  background: transparent;
  color: rgba(255, 255, 255, 0.78);
  font: 700 clamp(13px, 1.8vw, 14.5px) var(--font-body);
  text-align: left;
  cursor: pointer;
  transition: background var(--t-fast) var(--ease), color var(--t-fast) var(--ease);
}
.sidebar-link:hover:not(:disabled) {
  background: rgba(255, 255, 255, 0.08);
  color: #fff;
}
.sidebar-link:focus-visible {
  outline: 3px solid var(--leaf);
  outline-offset: 2px;
}
.sidebar-link--active {
  background: rgba(255, 255, 255, 0.16);
  color: #fff;
  font-weight: 800;
}
.sidebar-icon {
  width: clamp(16px, 2.5vw, 18px);
  height: clamp(16px, 2.5vw, 18px);
  flex: none;
  fill: none;
  stroke: currentColor;
  stroke-width: 1.8;
  stroke-linecap: round;
  stroke-linejoin: round;
}
.sidebar-label {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.sidebar-link--unavailable {
  opacity: 0.45;
  cursor: not-allowed;
}
.sidebar-link--unavailable:hover {
  background: transparent;
  color: rgba(255, 255, 255, 0.45);
}
.sidebar-badge {
  margin-left: auto;
  padding: 2px 8px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.12);
  font: 700 10px var(--font-display);
  text-transform: uppercase;
  color: rgba(255, 255, 255, 0.7);
}

/* Spacer - pushes sign-out to bottom, flexible but constrained */
.sidebar-spacer {
  flex: 1;
  min-height: clamp(8px, 1.5vh, 12px);
  max-height: clamp(40px, 8vh, 80px);
}

/* Footer - Sign out */
.sidebar-footer {
  padding: 0 clamp(4px, 1vw, 8px) clamp(6px, 1vh, 10px);
}
.sidebar-signout {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: clamp(10px, 2vw, 12px);
  width: 100%;
  padding: clamp(11px, 1.8vh, 13px) clamp(14px, 2.5vw, 16px);
  border: 0;
  border-radius: clamp(10px, 1.5vw, 12px);
  background: #fff;
  color: var(--forest);
  font: 800 clamp(13px, 1.8vw, 15px) var(--font-body);
  cursor: pointer;
  transition: background var(--t-fast) var(--ease), transform var(--t-fast) var(--ease), box-shadow var(--t-base) var(--ease);
}
.sidebar-signout:hover {
  background: var(--tint);
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(8, 120, 63, 0.2);
}
.sidebar-signout:active {
  transform: scale(0.98);
}
.sidebar-signout:focus-visible {
  outline: 3px solid var(--leaf);
  outline-offset: 2px;
}

/* Main content area */
.admin-main {
  display: flex;
  flex-direction: column;
  min-width: 0;
  height: 100dvh;
}

/* Topbar */
.topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: clamp(10px, 2vw, 12px);
  height: var(--header-h);
  min-height: var(--header-h);
  padding: 0 var(--gutter);
  background: #fff;
  border-bottom: 1px solid var(--line);
  flex: none;
  position: sticky;
  top: 0;
  z-index: 10;
}
.topbar-brand {
  display: flex;
  align-items: center;
  gap: clamp(10px, 2vw, 12px);
  font: 800 clamp(16px, 2.5vw, 17px) var(--font-display);
  color: var(--forest);
  white-space: nowrap;
}
.topbar-mark {
  display: grid;
  place-items: center;
  width: clamp(28px, 4vw, 32px);
  height: clamp(28px, 4vw, 32px);
  border-radius: 10px;
  background: linear-gradient(135deg, var(--leaf), var(--forest));
  font-size: clamp(14px, 2.5vw, 16px);
  flex-shrink: 0;
}
.topbar-tools {
  display: flex;
  align-items: center;
  gap: clamp(8px, 1.5vw, 12px);
  flex-wrap: nowrap;
}
.topbar-hamburger {
  display: none;
}
.topbar-btn {
  height: 40px;
  padding: 0 clamp(12px, 2vw, 16px);
  border: 1px solid var(--line);
  border-radius: 999px;
  background: #fff;
  color: var(--forest);
  font: 800 clamp(12px, 1.5vw, 14px) var(--font-body);
  white-space: nowrap;
  transition: background var(--t-fast) var(--ease);
}
.topbar-btn:hover {
  background: var(--tint);
}
.topbar-usecase {
  display: flex;
  align-items: center;
  gap: clamp(8px, 1.5vw, 10px);
  height: 40px;
  padding: 0 clamp(10px, 1.5vw, 12px) 0 clamp(12px, 2vw, 16px);
  border: 1px solid var(--line);
  border-radius: 999px;
  font: 800 clamp(12px, 1.5vw, 14px) var(--font-body);
  color: var(--forest);
  white-space: nowrap;
}
.topbar-usecase select {
  border: 0;
  background: transparent;
  font: inherit;
  color: inherit;
  cursor: pointer;
  min-width: 0;
}
.topbar-account {
  position: relative;
}
.topbar-avatar {
  border: 0;
  display: grid;
  place-items: center;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: var(--leaf);
  color: #fff;
  font: 800 clamp(12px, 1.5vw, 14px) var(--font-display);
  cursor: pointer;
  transition: background var(--t-fast) var(--ease), transform var(--t-fast) var(--ease);
}
.topbar-avatar:hover {
  background: var(--forest);
  transform: scale(1.02);
}
.topbar-avatar:focus-visible {
  outline: 3px solid var(--leaf);
  outline-offset: 2px;
}
.topbar-menu {
  display: none;
  position: absolute;
  top: calc(100% + 8px);
  right: 0;
  z-index: 40;
  min-width: 200px;
  max-width: calc(100vw - 2 * var(--gutter));
  padding: 6px;
  border: 1px solid var(--line);
  border-radius: 14px;
  background: #fff;
  box-shadow: 0 8px 24px rgba(6, 40, 20, 0.18);
}
.topbar-menu-who {
  padding: 8px 12px;
  font-size: 13px;
  color: var(--ink-soft);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.topbar-menu-item {
  display: flex;
  align-items: center;
  gap: 10px;
  width: 100%;
  padding: 10px 12px;
  border: 0;
  border-radius: 10px;
  background: transparent;
  color: var(--forest);
  font: 800 15px var(--font-body);
  text-align: left;
}
.topbar-menu-item:hover {
  background: var(--tint);
}

/* Content */
.admin-content {
  flex: 1;
  min-height: 0;
  overflow-y: auto;
  padding: clamp(20px, 3vh, 26px) var(--gutter) clamp(32px, 4vh, 40px);
}

/* Mobile responsive - below 900px */
@media (max-width: 900px) {
  .admin-layout {
    grid-template-columns: 1fr;
    grid-template-rows: auto 1fr;
  }

  .sidebar {
    position: fixed;
    left: 0;
    right: 0;
    top: 0;
    bottom: 0;
    z-index: 50;
    flex-direction: column;
    height: 100dvh;
    max-height: 100dvh;
    box-shadow: 4px 0 24px rgba(6, 40, 20, 0.2);
    transform: translateX(-100%);
    transition: transform var(--t-slow) var(--ease);
    overflow: visible;
  }
  .sidebar.sidebar--open {
    transform: translateX(0);
  }
  .sidebar.sidebar--narrow {
    transform: translateX(-100%);
  }
  .sidebar-content {
    height: 100%;
    padding: clamp(12px, 2vh, 16px) clamp(12px, 2vw, 16px) clamp(16px, 3vh, 20px);
    border-bottom-left-radius: 0;
    border-bottom-right-radius: 0;
  }
  .leaf-decoration {
    display: none;
  }

  /* Backdrop */
  .sidebar-backdrop {
    position: fixed;
    inset: 0;
    z-index: 40;
    background: rgba(6, 40, 20, 0.4);
    opacity: 0;
    visibility: hidden;
    transition: opacity var(--t-base) var(--ease), visibility var(--t-base) var(--ease);
  }
  .sidebar-backdrop--visible {
    opacity: 1;
    visibility: visible;
  }

  .sidebar-brand {
    padding-bottom: clamp(12px, 2vh, 16px);
    margin-bottom: clamp(6px, 1vh, 8px);
  }

  .sidebar-section {
    padding: clamp(10px, 1.5vh, 12px) clamp(8px, 1vw, 12px) clamp(4px, 0.5vh, 6px);
  }

  .sidebar-list {
    gap: clamp(2px, 0.5vh, 3px);
  }

  .sidebar-link {
    padding: clamp(10px, 1.5vh, 12px) clamp(10px, 1.5vw, 14px);
    font-size: clamp(13px, 1.8vw, 15px);
  }

  .sidebar-signout {
    padding: clamp(12px, 1.5vh, 14px) clamp(14px, 2vw, 16px);
    font-size: clamp(14px, 1.8vw, 15px);
  }

  .topbar {
    height: var(--header-h);
    min-height: var(--header-h);
    padding: 0 var(--gutter);
  }
  .topbar-title {
    display: none;
  }
  .topbar-btn {
    display: none;
  }
  .topbar-usecase span {
    display: none;
  }
  .topbar-usecase {
    padding: 0 clamp(8px, 1.5vw, 12px);
  }
  .topbar-hamburger {
    display: grid;
    place-items: center;
    width: 40px;
    height: 40px;
    border: 0;
    border-radius: 10px;
    background: transparent;
    color: var(--forest);
    transition: background var(--t-fast) var(--ease);
  }
  .topbar-hamburger:hover {
    background: var(--tint);
  }
  .topbar-hamburger:focus-visible {
    outline: 3px solid var(--leaf);
    outline-offset: 2px;
  }
  .topbar-hamburger svg {
    width: 24px;
    height: 24px;
  }
}

/* Tablet - sidebar as drawer */
@media (min-width: 600px) and (max-width: 899px) {
  .sidebar {
    max-width: 320px;
    left: auto;
    right: 0;
    border-bottom-left-radius: 24px;
    border-top-left-radius: 24px;
    transform: translateX(100%);
  }
  .sidebar.sidebar--open {
    transform: translateX(0);
  }
}
</style>