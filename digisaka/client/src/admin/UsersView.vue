<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { api } from '../api.js';
import Icon from '../components/Icon.vue';

const SIZE = 25;
const q = ref(''), page = ref(0), users = ref([]), total = ref(0), loading = ref(true), status = ref(null), fileInput = ref(null);
const from = computed(() => (total.value ? page.value * SIZE + 1 : 0));
const to = computed(() => Math.min((page.value + 1) * SIZE, total.value));

let seq = 0;   // ignore responses from superseded requests
async function load() {
  const mine = ++seq; loading.value = true;
  try {
    const d = await api.get(`/api/admin/users?q=${encodeURIComponent(q.value.trim())}&limit=${SIZE}&offset=${page.value * SIZE}`);
    if (mine !== seq) return;
    users.value = d.users; total.value = d.total;
  } catch (e) { status.value = { error: true, text: e.message }; }
  finally { if (mine === seq) loading.value = false; }
}

let t;
watch(q, () => { clearTimeout(t); t = setTimeout(() => { page.value = 0; load(); }, 250); });
watch(page, load);
onMounted(load);

async function importFile(e) {
  const file = e.target.files[0]; e.target.value = '';
  if (!file) return;
  try {
    const r = await api.post('/api/admin/users/import', { csv: await file.text() });
    status.value = { created: r.created, skipped: r.skipped };
    page.value === 0 ? load() : (page.value = 0);
  } catch (err) { status.value = { error: true, text: err.message }; }
}
</script>

<template>
  <header class="head"><h1>Users</h1><p>Farmer/User accounts registered on DigiSaka.</p></header>

  <div class="toolbar">
    <label class="search">
      <Icon name="search" :size="16" />
      <input v-model="q" type="search" placeholder="Search name, email or contact" aria-label="Search users" @keydown.enter="load">
      <button type="button" @click="load">Search</button>
    </label>
    <button class="btn primary" type="button" @click="fileInput.click()"><Icon name="upload" :size="16" />Import Master List</button>
    <button class="btn" type="button" @click="load"><Icon name="refresh" :size="16" />Refresh</button>
    <input ref="fileInput" type="file" accept=".csv,text/csv" hidden @change="importFile">
  </div>

  <div v-if="status" class="status" :class="{ err: status.error }" role="status">
    <template v-if="status.error">{{ status.text }}</template>
    <template v-else>
      Imported {{ status.created }} farmer{{ status.created === 1 ? '' : 's' }}<template v-if="status.skipped.length">; skipped {{ status.skipped.length }}:</template>
      <ul v-if="status.skipped.length">
        <li v-for="s in status.skipped.slice(0, 5)" :key="s.line">Line {{ s.line }}: {{ s.reason }}<template v-if="s.email"> ({{ s.email }})</template></li>
        <li v-if="status.skipped.length > 5">and {{ status.skipped.length - 5 }} more</li>
      </ul>
    </template>
  </div>

  <div class="card">
    <div class="scroll">
      <table>
        <thead><tr><th>Last name</th><th>First name</th><th>Middle name</th><th>Email</th><th>Contact</th></tr></thead>
        <tbody>
          <tr v-for="u in users" :key="u.id">
            <td class="last">{{ u.lastName }}</td>
            <td><span class="who"><i>{{ u.firstName.charAt(0).toUpperCase() }}</i>{{ u.firstName }}</span></td>
            <td>{{ u.middleName }}</td>
            <td class="mail">{{ u.email }}</td>
            <td>{{ u.contact }}</td>
          </tr>
        </tbody>
      </table>
      <p v-if="!loading && !users.length" class="none">{{ q ? 'No farmers match your search.' : 'No farmers yet. Import a master list to get started.' }}</p>
    </div>
    <footer>
      <span>{{ total ? `Showing ${from}–${to} of ${total}` : '' }}</span>
      <span class="pager"><button type="button" :disabled="page === 0" @click="page--">Previous</button><button type="button" :disabled="to >= total" @click="page++">Next</button></span>
    </footer>
  </div>
</template>

<style scoped>
.head h1 { font: 800 24px var(--font-display); color: var(--forest); } .head p { margin-top: 2px; color: var(--ink-soft); }
.toolbar { display: flex; flex-wrap: wrap; gap: 12px; margin: 18px 0 14px; }
.search { flex: 1; min-width: 260px; display: flex; align-items: center; gap: 10px; padding-left: 16px; border: 1px solid var(--line); border-radius: 999px; background: #fff; color: var(--ink-soft); }
.search input { flex: 1; min-width: 0; height: 42px; border: 0; background: transparent; outline: none; }
.search:focus-within { outline: 3px solid var(--leaf); outline-offset: 2px; }
.search button { height: 42px; padding: 0 22px; border: 0; border-radius: 0 999px 999px 0; background: var(--forest); color: #fff; font-weight: 800; }
.btn { display: inline-flex; align-items: center; gap: 8px; height: 44px; padding: 0 18px; border: 1px solid var(--line); border-radius: 999px; background: #fff; font-weight: 800; color: var(--forest); }
.btn:hover { background: var(--tint); }
.btn.primary { background: var(--forest); border-color: var(--forest); color: #fff; } .btn.primary:hover { background: var(--forest-deep); }
.status { margin-bottom: 14px; padding: 10px 14px; border-radius: 12px; background: var(--tint); color: var(--forest); font-weight: 800; font-size: 14px; }
.status.err { background: var(--warn-tint); color: #B4432A; }
.status ul { margin: 6px 0 0 18px; list-style: disc; font-weight: 600; }
.card { border: 1px solid var(--line); border-radius: var(--radius-lg); background: #fff; box-shadow: var(--shadow); overflow: hidden; }
.scroll { overflow-x: auto; }
table { width: 100%; min-width: 720px; border-collapse: collapse; }
th { padding: 14px 20px; background: var(--forest); color: #fff; font: 800 12px var(--font-display); letter-spacing: .08em; text-transform: uppercase; text-align: left; }
td { padding: 14px 20px; border-top: 1px solid var(--line); }
.last { font-weight: 800; color: #1F5FBF; } .mail { color: #1F5FBF; font-weight: 700; }
.who { display: inline-flex; align-items: center; gap: 12px; }
.who i { display: grid; place-items: center; width: 36px; height: 36px; border-radius: 50%; background: var(--leaf); color: #fff; font: 800 14px var(--font-display); font-style: normal; }
.none { padding: 30px; text-align: center; color: var(--ink-soft); }
footer { display: flex; justify-content: space-between; align-items: center; gap: 12px; padding: 12px 20px; border-top: 1px solid var(--line); color: var(--ink-soft); font-size: 14px; }
.pager { display: flex; gap: 8px; }
.pager button { padding: 7px 14px; border: 1px solid var(--line); border-radius: 10px; background: #fff; font-weight: 800; color: var(--forest); }
.pager button:disabled { opacity: .45; cursor: default; }
</style>
