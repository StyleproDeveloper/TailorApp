// DISABLED SERVICE WORKER - NO CACHING
// This service worker is disabled to prevent caching issues
'use strict';

// Immediately unregister this service worker
self.addEventListener('install', function(event) {
  console.log('Service worker install - DISABLED');
  self.skipWaiting();
});

self.addEventListener('activate', function(event) {
  console.log('Service worker activate - UNREGISTERING');
  event.waitUntil(
    caches.keys().then(function(cacheNames) {
      return Promise.all(
        cacheNames.map(function(cacheName) {
          console.log('Deleting cache:', cacheName);
          return caches.delete(cacheName);
        })
      );
    }).then(function() {
      return self.registration.unregister();
    })
  );
});

// Don't cache anything - always fetch from network
self.addEventListener('fetch', function(event) {
  console.log('Service worker fetch - BYPASSING CACHE');
  event.respondWith(fetch(event.request));
});
