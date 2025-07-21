const CACHE_NAME = 'riyales-pwa-cache-v1';
const urlsToCache = [
  '/',
  '/index.html',
  '/manifest.json',
  '/favicon.png',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  '/icons/Icon-maskable-192.png',
  '/icons/Icon-maskable-512.png',
  '/assets/images/logo.png',
  '/assets/images/logo-dark.png',
  '/assets/images/logo-light.png',
  '/assets/fonts/Vazirmatn.ttf',
  '/assets/fonts/SF-Pro.ttf',
  '/assets/fonts/CourierPrime.ttf',
  '/assets/fonts/Onest.ttf',
  '/assets/icons/flags',
  '/assets/icons/crypto',
  '/assets/icons/commodity',
  '/assets/config/terms_en.json',
  '/assets/config/terms_fa.json',
  '/assets/config/priority.json',
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
  );
});

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => response || fetch(event.request))
  );
});

self.addEventListener('activate', event => {
  const cacheWhitelist = [CACHE_NAME];
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (!cacheWhitelist.includes(cacheName)) {
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});