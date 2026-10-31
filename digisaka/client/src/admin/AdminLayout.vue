<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { useRoute, useRouter, RouterView } from 'vue-router';
import { useAuthStore } from '../stores/auth.js';
import { useUseCaseStore } from '../stores/useCase.js';
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

// Use case dropdown
const usecaseOpen = ref(false);
const currentUsecaseLabel = computed(() => uc.cases.find(c => c.slug === uc.slug)?.label ?? '');

function leave() { closeMenu(); auth.signOut(); router.push('/login'); }
function toApp() { closeMenu(); router.push('/scan'); }
const to = (screen) => (screen === 'overview' ? '/admin' : `/admin/${screen}`);

function toggleUsecase() { usecaseOpen.value = !usecaseOpen.value; }
function selectUsecase(slug) { uc.select(slug); usecaseOpen.value = false; }

// Close use case dropdown on outside click
onMounted(() => {
  document.addEventListener('click', closeUsecaseOnOutsideClick);
  uc.load().catch(() => {});
});
onUnmounted(() => {
  document.removeEventListener('click', closeUsecaseOnOutsideClick);
});

function closeUsecaseOnOutsideClick(e) {
  if (usecaseOpen.value && !e.target.closest('.topbar-usecase')) {
    usecaseOpen.value = false;
  }
}

// Close sidebar on route change (mobile)
watch(route, () => { if (narrow.value) sidebarOpen.value = false; });
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
      <!-- Decorative leaf silhouettes (matching reference) -->
      <svg class="leaf-deco leaf-deco--1" aria-hidden="true" width="80" height="120" viewBox="0 0 80 120">
        <path d="M70 6C40 10 20 40 10 110C50 90 76 50 70 6Z" fill="#fff" opacity="0.07"/>
      </svg>
      <svg class="leaf-deco leaf-deco--2" aria-hidden="true" width="150" height="130" viewBox="0 0 150 130">
        <path d="M0 30C40 40 50 80 30 110C-10 90 -10 60 0 30Z" fill="#fff" opacity="0.08"/>
        <path d="M0 90C50 70 110 90 140 110C90 130 30 125 0 110Z" fill="#fff" opacity="0.08"/>
      </svg>
      <svg class="leaf-deco leaf-deco--3" aria-hidden="true" width="160" height="170" viewBox="0 0 160 170">
        <path d="M5 5C80 20 140 80 150 170H20C0 110 -5 50 5 5Z" fill="#fff" opacity="0.06"/>
        <path d="M130 0C165 30 160 100 140 140C110 100 110 40 130 0Z" fill="#fff" opacity="0.06"/>
      </svg>

      <!-- Branding - Toka AI logo -->
      <div class="sidebar-brand">
        <span class="sidebar-mark" aria-hidden="true">
          <img src="../assets/bananaleaf2.png" alt="" width="32" height="36" />
        </span>
        <span class="sidebar-title">Toka AI</span>
      </div>

      <!-- Workspace label -->
      <div class="sidebar-section">Workspace</div>

      <!-- Navigation -->
      <nav class="sidebar-nav" aria-label="Admin navigation">
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

      <!-- Sign Out button at fixed position -->
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
    </aside>

    <!-- Main content area -->
    <div class="admin-main">
      <!-- Topbar -->
      <header class="topbar">
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
            ⮐ Toka app
          </button>
          <div class="topbar-usecase">
            <span>Use Case</span>
            <div class="usecase-select" @click="toggleUsecase" tabindex="0" @keydown.enter="toggleUsecase" @keydown.space.prevent="toggleUsecase" role="combobox" aria-expanded="usecaseOpen" aria-haspopup="listbox" aria-label="Select use case">
              <span>{{ currentUsecaseLabel }}</span>
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#056b43" stroke-width="3" aria-hidden="true"><path d="M5 9l7 7 7-7"/></svg>
            </div>
            <div v-if="usecaseOpen" class="usecase-dropdown" role="listbox">
              <div v-for="c in uc.cases" :key="c.slug" class="usecase-option" role="option" :aria-selected="uc.slug === c.slug" @click="selectUsecase(c.slug)">
                {{ c.label }}
              </div>
            </div>
          </div>
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
              <button v-if="auth.practitioner" type="button" class="topbar-menu-item" @click="toApp">⮐ Toka app</button>
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

/* Sidebar - full height, dark forest green (#056b43 per reference) */
.sidebar {
  position: relative;
  width: var(--sidebar-w);
  background: #056b43;
  color: #fff;
  overflow: hidden;
  z-index: 20;
}

/* Decorative leaf silhouettes - matching reference positions exactly */
.leaf-deco {
  position: absolute;
  pointer-events: none;
  z-index: 0;
}
.leaf-deco--1 {
  right: -10px;
  top: 0;
  width: 80px;
  height: 120px;
}
.leaf-deco--2 {
  left: -20px;
  top: 620px;
  width: 150px;
  height: 130px;
}
.leaf-deco--3 {
  left: 100px;
  top: 780px;
  width: 160px;
  height: 170px;
}

/* Branding - absolute positioned per reference */
.sidebar-brand {
  position: absolute;
  left: 24px;
  top: 22px;
  display: flex;
  align-items: center;
  gap: 12px;
  font: 700 24px var(--font-display);
  letter-spacing: -0.3px;
  z-index: 1;
}
.sidebar-mark {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 43px;
  flex-shrink: 0;
}
.sidebar-title {
  white-space: nowrap;
}

/* Workspace section label - absolute positioned per reference */
.sidebar-section {
  position: absolute;
  left: 24px;
  top: 97px;
  font: 700 12px var(--font-display);
  line-height: 14px;
  color: rgba(255, 255, 255, 0.7);
  z-index: 1;
}

/* Navigation - absolute positioned per reference */
.sidebar-nav {
  position: absolute;
  left: 24px;
  top: 128px;
  width: 208px;
  z-index: 1;
}
.sidebar-list {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.sidebar-link {
  display: flex;
  align-items: center;
  gap: 14px;
  width: 100%;
  height: 48px;
  padding: 0 0 0 12px;
  border: 0;
  border-radius: 8px;
  background: transparent;
  color: #fff;
  font: 500 16px var(--font-body);
  text-align: left;
  cursor: pointer;
  transition: background var(--t-fast) var(--ease);
}
.sidebar-link:hover:not(:disabled):not(.sidebar-link--active) {
  background: rgba(0, 0, 0, 0.12);
}
.sidebar-link:focus-visible {
  outline: 3px solid var(--leaf);
  outline-offset: 2px;
}
.sidebar-link--active {
  background: #04583a;
  color: #fff;
}
.sidebar-icon {
  width: 18px;
  height: 18px;
  flex: none;
  fill: #fff;
  stroke: none;
}
.sidebar-label {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.sidebar-link--unavailable {
  opacity: 0.5;
  cursor: not-allowed;
}
.sidebar-link--unavailable:hover {
  background: transparent;
}
.sidebar-badge {
  margin-left: auto;
  padding: 2px 8px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.15);
  font: 700 10px var(--font-display);
  text-transform: uppercase;
  color: rgba(255, 255, 255, 0.8);
}

/* Sign Out button - absolute positioned per reference (top: 868px) */
.sidebar-signout {
  position: absolute;
  left: 24px;
  top: 868px;
  width: 208px;
  height: 52px;
  border: 0;
  border-radius: 8px;
  background: #fff;
  color: #056b43;
  font: 700 15px var(--font-body);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  z-index: 1;
  transition: background var(--t-fast) var(--ease), transform var(--t-fast) var(--ease), box-shadow var(--t-base) var(--ease);
}
.sidebar-signout:hover {
  background: #f3f4f6;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(5, 107, 67, 0.2);
}
.sidebar-signout:active {
  transform: scale(0.98);
}
.sidebar-signout:focus-visible {
  outline: 3px solid var(--leaf);
  outline-offset: 2px;
}
.sidebar-signout .sidebar-icon {
  width: 18px;
  height: 18px;
  fill: #056b43;
  stroke: none;
}

/* Main content area */
.admin-main {
  display: flex;
  flex-direction: column;
  min-width: 0;
  height: 100dvh;
}

/* Topbar - height 84px per reference */
.topbar {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 22px;
  height: 84px;
  min-height: 84px;
  padding: 0 27px 0 0;
  background: #fff;
  border-bottom: 1px solid #e5e7eb;
  flex: none;
  position: sticky;
  top: 0;
  z-index: 10;
}
.topbar-tools {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: nowrap;
}
.topbar-btn {
  height: 38px;
  padding: 0 14px 0 19px;
  border: 1px solid #056b43;
  border-radius: 10px;
  background: #fff;
  color: #056b43;
  font: 500 14px var(--font-body);
  white-space: nowrap;
  transition: background var(--t-fast) var(--ease);
}
.topbar-btn:hover {
  background: #f3f4f6;
}
.topbar-usecase {
  display: flex;
  align-items: center;
  gap: 8px;
  height: 38px;
  white-space: nowrap;
  position: relative;
}
.usecase-select {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  width: 142px;
  height: 27px;
  padding: 0 8px 0 15px;
  border: 1px solid #056b43;
  border-radius: 8px;
  background: #fff;
  color: #056b43;
  font: 500 14px var(--font-body);
  cursor: pointer;
  user-select: none;
}
.usecase-select svg {
  flex-shrink: 0;
}
.usecase-select:hover {
  background: #f3f4f6;
}
.usecase-select:focus-visible {
  outline: 3px solid var(--leaf);
  outline-offset: 2px;
}
.usecase-dropdown {
  position: absolute;
  top: calc(100% + 4px);
  left: 0;
  z-index: 30;
  min-width: 142px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #fff;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  overflow: hidden;
}
.usecase-option {
  padding: 8px 12px;
  font: 500 14px var(--font-body);
  color: #111;
  cursor: pointer;
  white-space: nowrap;
}
.usecase-option:hover,
.usecase-option[aria-selected="true"] {
  background: #f3f4f6;
  color: #056b43;
}
.topbar-account {
  position: relative;
}
.topbar-avatar {
  border: 0;
  display: grid;
  place-items: center;
  width: 44px;
  height: 44px;
  border-radius: 50%;
  background: #16a34a;
  color: #fff;
  font: 700 14px var(--font-display);
  cursor: pointer;
  transition: background var(--t-fast) var(--ease), transform var(--t-fast) var(--ease);
}
.topbar-avatar:hover {
  background: #12a150;
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
  border: 1px solid #e5e7eb;
  border-radius: 14px;
  background: #fff;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.18);
}
.topbar-menu-who {
  padding: 8px 12px;
  font-size: 13px;
  color: #6b7280;
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
  color: #056b43;
  font: 700 15px var(--font-body);
  text-align: left;
}
.topbar-menu-item:hover {
  background: #f3f4f6;
}

/* Content */
.admin-content {
  flex: 1;
  min-height: 0;
  overflow-y: auto;
  padding: 20px 32px 32px;
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
    width: 100%;
    max-width: 100%;
    height: 100dvh;
    max-height: 100dvh;
    box-shadow: 4px 0 24px rgba(5, 107, 67, 0.2);
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

  /* Hide absolute positioned elements in mobile drawer - they'll be in wrong positions */
  .sidebar.sidebar--narrow .sidebar-brand,
  .sidebar.sidebar--narrow .sidebar-section,
  .sidebar.sidebar--narrow .sidebar-nav,
  .sidebar.sidebar--narrow .sidebar-signout {
    position: static;
    width: auto;
  }
  .sidebar.sidebar--narrow .sidebar-brand {
    margin: 16px 16px 20px;
  }
  .sidebar.sidebar--narrow .sidebar-section {
    margin: 0 16px 8px;
  }
  .sidebar.sidebar--narrow .sidebar-nav {
    margin: 0 16px;
  }
  .sidebar.sidebar--narrow .sidebar-signout {
    position: static;
    width: calc(100% - 32px);
    margin: auto 16px 16px;
  }
  .sidebar.sidebar--narrow .sidebar-nav {
    position: static;
    width: auto;
  }
  .sidebar.sidebar--narrow .sidebar-list {
    gap: 2px;
  }
  .sidebar.sidebar--narrow .sidebar-link {
    padding: 12px 14px;
    height: 44px;
  }

  .leaf-deco {
    display: none;
  }

  /* Backdrop */
  .sidebar-backdrop {
    position: fixed;
    inset: 0;
    z-index: 40;
    background: rgba(5, 107, 67, 0.4);
    opacity: 0;
    visibility: hidden;
    transition: opacity var(--t-base) var(--ease), visibility var(--t-base) var(--ease);
  }
  .sidebar-backdrop--visible {
    opacity: 1;
    visibility: visible;
  }

  .topbar {
    height: 72px;
    min-height: 72px;
    padding: 0 var(--gutter);
    justify-content: flex-end;
    gap: 12px;
  }
  .topbar-btn {
    display: none;
  }
  .topbar-usecase {
    height: 38px;
    padding: 0 12px;
  }
  .topbar-usecase > span {
    display: none;
  }
  .usecase-select {
    width: 120px;
    padding: 0 8px 0 12px;
  }
  .topbar-hamburger {
    display: grid;
    place-items: center;
    width: 40px;
    height: 40px;
    border: 0;
    border-radius: 10px;
    background: transparent;
    color: #056b43;
    transition: background var(--t-fast) var(--ease);
  }
  .topbar-hamburger:hover {
    background: #f3f4f6;
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

/* Tablet - sidebar as drawer from right */
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
  .sidebar.sidebar--narrow .sidebar-brand,
  .sidebar.sidebar--narrow .sidebar-section,
  .sidebar.sidebar--narrow .sidebar-nav,
  .sidebar.sidebar--narrow .sidebar-signout {
    position: absolute;
  }
  .sidebar.sidebar--narrow .sidebar-brand {
    left: 24px;
    top: 22px;
    margin: 0;
  }
  .sidebar.sidebar--narrow .sidebar-section {
    left: 24px;
    top: 97px;
    margin: 0;
  }
  .sidebar.sidebar--narrow .sidebar-nav {
    left: 24px;
    top: 128px;
    width: 208px;
    margin: 0;
  }
  .sidebar.sidebar--narrow .sidebar-signout {
    left: 24px;
    top: 868px;
    width: 208px;
    margin: 0;
  }
  .leaf-deco {
    display: block;
  }
}
</style>