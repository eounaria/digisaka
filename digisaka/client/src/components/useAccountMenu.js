import { ref, watch, onMounted, onBeforeUnmount } from 'vue';

// The topbar avatar's account menu. Below 900px the sidebar loses its account block, so the avatar opens a small
// menu; above it the avatar is a plain badge (`narrow` is false: not focusable, no popup semantics, menu closed).
// Bind `account` to the wrapper around avatar and menu, `avatar` to the button, `toggleMenu` to its click.
const NARROW = '(max-width: 900px)';

export function useAccountMenu(route) {
  const menuOpen = ref(false), narrow = ref(false), account = ref(null), avatar = ref(null);
  let query = null;
  const closeMenu = () => { menuOpen.value = false; };
  const toggleMenu = () => { if (narrow.value) menuOpen.value = !menuOpen.value; };
  const closeOnOutsideClick = (e) => { if (menuOpen.value && !account.value?.contains(e.target)) closeMenu(); };
  const closeOnEscape = (e) => { if (e.key === 'Escape' && menuOpen.value) { closeMenu(); avatar.value?.focus(); } };
  const followWidth = () => { narrow.value = query.matches; closeMenu(); };
  watch(() => route.path, closeMenu);
  onMounted(() => {
    query = window.matchMedia(NARROW);
    narrow.value = query.matches;
    query.addEventListener('change', followWidth);
    document.addEventListener('click', closeOnOutsideClick);
    document.addEventListener('keydown', closeOnEscape);
  });
  onBeforeUnmount(() => {
    query?.removeEventListener('change', followWidth);
    document.removeEventListener('click', closeOnOutsideClick);
    document.removeEventListener('keydown', closeOnEscape);
  });
  return { menuOpen, narrow, account, avatar, toggleMenu, closeMenu };
}
