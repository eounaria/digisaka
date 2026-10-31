<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '../stores/auth.js';
import Icon from '../components/Icon.vue';

const router = useRouter(), auth = useAuthStore();
const notificationsEnabled = ref(true);
const loading = ref(false);
const error = ref('');

// Mock user profile data - in real app this would come from API
const profile = ref({
  fullName: 'Juan Dela Cruz',
  email: auth.email || 'juan.delacruz@example.com',
  farmName: 'Sitio Malabo Banana Farm',
  farmLocation: 'Balayan, Batangas',
  plantLines: 6,
  language: 'English',
});

const initials = computed(() => {
  const parts = profile.value.fullName.split(' ');
  return parts.length > 1
    ? (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
    : profile.value.fullName.slice(0, 2).toUpperCase();
});

async function updateProfile(field, value) {
  loading.value = true;
  error.value = '';
  try {
    // TODO: Replace with actual API call
    await new Promise(r => setTimeout(r, 500));
    profile.value[field] = value;
  } catch (e) {
    error.value = 'Failed to update profile';
  } finally {
    loading.value = false;
  }
}

async function signOut() {
  loading.value = true;
  try {
    await auth.signOut();
    router.push('/login');
  } catch (e) {
    error.value = 'Failed to sign out';
  } finally {
    loading.value = false;
  }
}

onMounted(() => {
  // In a real app, fetch user profile from API here
});
</script>

<template>
  <div class="page profile-page">
    <div class="profile-header">
      <div class="profile-banner">
        <div class="avatar-large">{{ initials }}</div>
        <h2>{{ profile.fullName }}</h2>
        <p class="farm-location">{{ profile.farmName }} · {{ profile.farmLocation }}</p>
      </div>
    </div>

    <section class="card-section">
      <h3 class="section-title">Account</h3>

      <div class="card">
        <div class="profile-row">
          <div class="icon-tile"><Icon name="person" :size="20" /></div>
          <div class="row-content">
            <label class="row-label">Full Name</label>
            <input
              class="row-input"
              type="text"
              :value="profile.fullName"
              @change="updateProfile('fullName', $event.target.value)"
              :disabled="loading"
            />
          </div>
        </div>

        <div class="divider"></div>

        <div class="profile-row">
          <div class="icon-tile"><Icon name="mail" :size="20" /></div>
          <div class="row-content">
            <label class="row-label">Email</label>
            <input
              class="row-input"
              type="email"
              :value="profile.email"
              @change="updateProfile('email', $event.target.value)"
              :disabled="loading"
            />
          </div>
        </div>

        <div class="divider"></div>

        <div class="profile-row clickable" @click="goToFarmInfo">
          <div class="icon-tile"><Icon name="map-pin" :size="20" /></div>
          <div class="row-content flex-1">
            <label class="row-label">Farm Information</label>
            <span class="row-value">{{ profile.farmName }}</span>
          </div>
          <Icon name="chevron-right" :size="20" class="chevron" />
        </div>
      </div>
    </section>

    <section class="card-section">
      <h3 class="section-title">Preferences</h3>

      <div class="card">
        <div class="profile-row">
          <div class="icon-tile"><Icon name="bell" :size="20" /></div>
          <div class="row-content flex-1">
            <label class="row-label">Notifications</label>
            <span class="row-value muted">Push & email alerts</span>
          </div>
          <label class="toggle">
            <input
              type="checkbox"
              v-model="notificationsEnabled"
              @change="updateProfile('notificationsEnabled', $event.target.checked)"
              :disabled="loading"
            />
            <span class="toggle-slider"></span>
          </label>
        </div>

        <div class="divider"></div>

        <div class="profile-row">
          <div class="icon-tile"><Icon name="globe" :size="20" /></div>
          <div class="row-content flex-1">
            <label class="row-label">Language</label>
            <select
              class="row-select"
              :value="profile.language"
              @change="updateProfile('language', $event.target.value)"
              :disabled="loading"
            >
              <option value="English">English</option>
              <option value="Filipino">Filipino</option>
              <option value="Spanish">Spanish</option>
            </select>
          </div>
        </div>
      </div>
    </section>

    <section class="card-section">
      <h3 class="section-title">Farm Details</h3>

      <div class="card">
        <div class="profile-row">
          <div class="icon-tile"><Icon name="map-pin" :size="20" /></div>
          <div class="row-content flex-1">
            <label class="row-label">Assigned Farm</label>
            <span class="row-value">{{ profile.farmName }}</span>
          </div>
        </div>

        <div class="divider"></div>

        <div class="profile-row">
          <div class="icon-tile"><Icon name="navigation" :size="20" /></div>
          <div class="row-content flex-1">
            <label class="row-label">Location</label>
            <span class="row-value">{{ profile.farmLocation }}</span>
          </div>
        </div>

        <div class="divider"></div>

        <div class="profile-row">
          <div class="icon-tile"><Icon name="grid" :size="20" /></div>
          <div class="row-content flex-1">
            <label class="row-label">Plant Lines</label>
            <span class="row-value">{{ profile.plantLines }}</span>
          </div>
        </div>

        <p class="card-note">Profile data is example content for UI demonstration.</p>
      </div>
    </section>

    <section class="card-section">
      <h3 class="section-title">Support</h3>

      <div class="card">
        <button class="profile-row clickable" type="button">
          <div class="icon-tile"><Icon name="info" :size="20" /></div>
          <div class="row-content flex-1">
            <label class="row-label">About DigiSaka AI</label>
          </div>
          <Icon name="chevron-right" :size="20" class="chevron" />
        </button>

        <div class="divider"></div>

        <button class="profile-row clickable" type="button">
          <div class="icon-tile"><Icon name="help-circle" :size="20" /></div>
          <div class="row-content flex-1">
            <label class="row-label">Help & Support</label>
          </div>
          <Icon name="chevron-right" :size="20" class="chevron" />
        </button>
      </div>
    </section>

    <section class="card-section">
      <button class="card signout-card" type="button" @click="signOut" :disabled="loading">
        <div class="icon-tile danger"><Icon name="logout" :size="20" /></div>
        <div class="row-content flex-1">
          <span class="signout-label">Log Out</span>
        </div>
      </button>
    </section>

    <div v-if="error" class="error-toast" role="alert">{{ error }}</div>
  </div>
</template>

<style scoped>
.profile-page {
  max-width: 720px;
  margin: 0 auto;
  padding: 24px var(--gutter) 40px;
}

.profile-header {
  margin-bottom: 8px;
}

.profile-banner {
  border-radius: 20px;
  padding: 32px 24px;
  text-align: center;
  background: linear-gradient(120deg, #8fbda3, #f3e6ae);
  color: #fff;
}

.avatar-large {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background: #147b41;
  color: #fff;
  display: grid;
  place-items: center;
  font-weight: 800;
  font-size: 28px;
  margin: 0 auto 16px;
  box-shadow: 0 4px 16px rgba(20, 123, 65, 0.3);
}

.profile-banner h2 {
  margin: 0 0 4px;
  font: 800 24px var(--font-display);
  color: #fff;
}

.farm-location {
  margin: 0;
  font-size: 15px;
  color: rgba(255, 255, 255, 0.85);
}

.card-section {
  margin-top: 28px;
}

.section-title {
  margin: 0 0 12px;
  font: 800 14px var(--font-display);
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--ink-soft);
}

.card {
  background: #fff;
  border: 1px solid var(--line);
  border-radius: var(--radius-lg);
  overflow: hidden;
  box-shadow: var(--shadow);
}

.profile-row {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 14px 16px;
  background: none;
  border: 0;
  width: 100%;
  text-align: left;
  cursor: default;
}

.profile-row.clickable {
  cursor: pointer;
}

.profile-row.clickable:hover {
  background: var(--tint);
}

.icon-tile {
  display: grid;
  place-items: center;
  flex: none;
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: #f3e9d8;
  color: var(--forest);
}

.icon-tile.danger {
  background: #ffe4e0;
  color: #b42318;
}

.row-content {
  display: grid;
  gap: 2px;
  min-width: 0;
  flex: 1;
}

.row-content.flex-1 {
  flex: 1;
}

.row-label {
  font-size: 12px;
  font-weight: 700;
  color: var(--muted);
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.row-value {
  font: 600 15px var(--font-body);
  color: var(--ink);
}

.row-value.muted {
  color: var(--ink-soft);
  font-weight: 500;
}

.row-input,
.row-select {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: #fff;
  color: var(--ink);
  font: inherit;
  font-size: 15px;
}

.row-input:focus,
.row-select:focus {
  outline: none;
  border-color: var(--leaf);
  box-shadow: 0 0 0 3px rgba(10, 159, 85, 0.15);
}

.row-input:disabled,
.row-select:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.divider {
  height: 1px;
  background: var(--line);
  margin: 0 16px;
}

.chevron {
  flex: none;
  color: var(--ink-soft);
}

.toggle {
  position: relative;
  display: inline-flex;
  align-items: center;
  flex: none;
}

.toggle input {
  position: absolute;
  opacity: 0;
  width: 0;
  height: 0;
}

.toggle-slider {
  position: relative;
  display: block;
  width: 44px;
  height: 24px;
  background: #cbd6d1;
  border-radius: 12px;
  transition: background 0.2s;
}

.toggle-slider::before {
  content: '';
  position: absolute;
  top: 2px;
  left: 2px;
  width: 20px;
  height: 20px;
  background: #fff;
  border-radius: 50%;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
  transition: transform 0.2s;
}

.toggle input:checked + .toggle-slider {
  background: var(--forest);
}

.toggle input:checked + .toggle-slider::before {
  transform: translateX(20px);
}

.toggle input:disabled + .toggle-slider {
  opacity: 0.5;
  cursor: not-allowed;
}

.toggle input:focus-visible + .toggle-slider {
  outline: 3px solid var(--leaf);
  outline-offset: 2px;
}

.card-note {
  margin: 12px 16px 16px;
  padding: 10px 12px;
  background: #fff0ce;
  border-radius: 10px;
  color: #80500d;
  font-size: 13px;
  font-weight: 600;
}

.signout-card {
  width: 100%;
  padding: 14px 16px;
  background: #fff;
  border: 1px solid var(--line);
  border-radius: var(--radius-lg);
  display: flex;
  align-items: center;
  gap: 14px;
  box-shadow: var(--shadow);
  transition: border-color 0.15s, background 0.15s;
}

.signout-card:hover:not(:disabled) {
  border-color: #fb6666;
  background: #fff8f8;
}

.signout-card:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.signout-label {
  font: 700 15px var(--font-body);
  color: #b42325;
}

.error-toast {
  position: fixed;
  bottom: 24px;
  right: 24px;
  z-index: 100;
  padding: 12px 18px;
  background: var(--warn);
  color: #fff;
  border-radius: 10px;
  font-weight: 700;
  font-size: 14px;
  box-shadow: 0 8px 24px rgba(180, 35, 37, 0.3);
  animation: slideIn 0.3s ease;
}

@keyframes slideIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

@media (max-width: 600px) {
  .profile-page {
    padding: 16px var(--gutter) 100px;
  }

  .profile-banner {
    padding: 24px 16px;
    border-radius: 16px;
  }

  .avatar-large {
    width: 64px;
    height: 64px;
    font-size: 22px;
    margin-bottom: 12px;
  }

  .profile-banner h2 {
    font-size: 20px;
  }

  .card-section {
    margin-top: 20px;
  }

  .profile-row {
    padding: 12px 14px;
    gap: 12px;
  }

  .icon-tile {
    width: 36px;
    height: 36px;
  }
}
</style>