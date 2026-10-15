import { createRouter, createWebHistory } from 'vue-router';
import { sessionState } from './scheduler/session.js';

// The earlier Express-cookie shell (dashboard, scan, history, schedule, notifications, settings, login) is unrouted;
// its files remain in views/ and components/AppLayout.vue.
const routes = [
  { path: '/sign-in', component: () => import('./views/SignInView.vue'), meta: { guest: true } },
  {
    path: '/', component: () => import('./components/ShellLayout.vue'), meta: { auth: true },
    children: [
      { path: '', redirect: '/qa' },
      { path: 'qa', component: () => import('./views/QaHomeView.vue'), meta: { title: 'QA scheduler' } },
      { path: 'qa/lines/:lineId', component: () => import('./views/QaLineWeekView.vue'), meta: { title: 'QA line-week' } },
      { path: 'qa/cycles/:cycleId', component: () => import('./views/QaCycleView.vue'), meta: { title: 'QA cycle' } },
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

router.beforeEach((to) => {
  if (to.meta.auth && !sessionState.signedIn) return { path: '/sign-in', query: { next: to.fullPath } };
  if (to.meta.admin && !sessionState.technicalUser) return '/qa';
  if (to.meta.guest && sessionState.signedIn) return '/qa';
});

export default router;
