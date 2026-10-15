import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from './stores/auth.js';
import { redirectFor } from './routeGuard.js';

const routes = [
  { path: '/login', component: () => import('./views/LoginView.vue'), meta: { guest: true } },
  {
    path: '/', component: () => import('./components/AppLayout.vue'), meta: { auth: true },
    children: [
      { path: '', component: () => import('./views/DashboardView.vue'), meta: { title: 'Dashboard' } },
      { path: 'scan', component: () => import('./views/ScanView.vue'), meta: { title: 'Disease Detection' } },
      { path: 'history', component: () => import('./views/HistoryView.vue'), meta: { title: 'Diagnosis History' } },
      { path: 'schedule', component: () => import('./views/ScheduleListView.vue'), meta: { title: 'Treatment Schedule' } },
      { path: 'treatment/:lineId/:week', component: () => import('./views/TreatmentDetailView.vue'), meta: { title: 'Treatment' } },
      { path: 'schedule/:lineId', component: () => import('./views/ScheduleLineView.vue'), meta: { title: 'Treatment Schedule' } },
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
router.beforeEach((to) => redirectFor(to, useAuthStore()));

export default router;
