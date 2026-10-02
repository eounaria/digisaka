import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from './stores/auth.js';

const routes = [
  { path: '/login', component: () => import('./views/LoginView.vue'), meta: { guest: true } },
  {
    path: '/', component: () => import('./components/AppLayout.vue'), meta: { auth: true },
    children: [
      { path: '', component: () => import('./views/DashboardView.vue'), meta: { title: 'Dashboard' } },
      { path: 'scan', component: () => import('./views/LegacyFrame.vue'), props: { screen: 'scan' }, meta: { title: 'Disease Detection' } },
      { path: 'history', component: () => import('./views/HistoryView.vue'), meta: { title: 'Diagnosis History' } },
      { path: 'schedule', component: () => import('./views/ScheduleListView.vue'), meta: { title: 'Treatment Schedule' } },
      { path: 'schedule/:bulkId', component: () => import('./views/BulkStagesView.vue'), meta: { title: 'Treatment Schedule' } },
      { path: 'schedule/:bulkId/:stage', component: () => import('./views/TreatmentDetailView.vue'), meta: { title: 'Treatment Schedule' } },
      { path: 'notifications', component: () => import('./views/NotificationsView.vue'), meta: { title: 'Notifications' } },
      { path: 'settings', component: () => import('./views/SettingsView.vue'), meta: { title: 'Settings' } },
    ],
  },
  {
    path: '/admin', component: () => import('./admin/AdminLayout.vue'), meta: { auth: true, admin: true },
    children: [
      { path: '', component: () => import('./admin/OverviewView.vue') },
      { path: 'users', component: () => import('./admin/UsersView.vue') },
      { path: 'processing', component: () => import('./admin/ProcessingView.vue') },
      { path: 'datasets', component: () => import('./admin/DatasetsView.vue') },
      { path: 'extractions', component: () => import('./admin/ExtractionsView.vue') },
      { path: 'tracing', component: () => import('./admin/TracingView.vue') },
      { path: 'history', component: () => import('./admin/AuditView.vue') },
      { path: 'kg', component: () => import('./admin/KnowledgeGraphView.vue') },
      { path: 'ontology', component: () => import('./admin/OntologyView.vue') },
    ],
  },
  { path: '/:pathMatch(.*)*', redirect: '/' },
];

const router = createRouter({ history: createWebHistory(), routes });

router.beforeEach(async (to) => {
  const auth = useAuthStore();
  if (!auth.checked) await auth.fetchMe();
  if (to.meta.auth && !auth.user) return '/login';
  if (to.meta.admin && !auth.isAdmin) return '/';
  if (to.meta.guest && auth.user) return to.query.next === 'admin' && auth.isAdmin ? '/admin' : '/';
});

export default router;
