// Theme handler service worker for Riyales
const CACHE_NAME = 'riyales-cache-v1';

// Install event - cache important files
self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll([
        '/index.html',
        '/manifest.json',
        '/flutter_bootstrap.js'
      ]);
    })
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// Handle theme change messages from the main app
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'THEME_CHANGE') {
    const { theme, color } = event.data;
    
    // Update manifest.json with new theme color
    updateManifestThemeColor(color)
      .catch(error => console.error('Failed to update manifest:', error));
    
    // Notify all clients about the theme change
    self.clients.matchAll().then(clients => {
      clients.forEach(client => {
        client.postMessage({
          type: 'THEME_UPDATED',
          theme,
          color
        });
      });
    });
  }
});

// Function to update manifest.json theme color
async function updateManifestThemeColor(color) {
  try {
    const manifestResponse = await fetch('/manifest.json');
    const manifest = await manifestResponse.json();
    
    // Update theme color
    manifest.theme_color = color;
    
    // Store in cache to serve the updated version
    const cache = await caches.open(CACHE_NAME);
    const response = new Response(JSON.stringify(manifest), {
      headers: { 'Content-Type': 'application/json' }
    });
    await cache.put('/manifest.json', response);
    
    return true;
  } catch (error) {
    console.error('Error updating manifest:', error);
    return false;
  }
} 