// Service Worker for Excel2VCF PWA
// Deployed at subpath: /excel2Vcard/

const CACHE_NAME = 'excel2vcf-v1';
const PREFIX = '/excel2Vcard';

// Core assets to precache
const PRECACHE_URLS = [
  `${PREFIX}/`,
  `${PREFIX}/index.html`,
  `${PREFIX}/manifest.webmanifest`,
  `${PREFIX}/icon-192.png`,
  `${PREFIX}/icon-512.png`,
  `${PREFIX}/maskable-512.png`
];

// Install event - precache core assets
self.addEventListener('install', (event) => {
  console.log('[SW] Installing service worker...');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('[SW] Precaching core assets');
        return cache.addAll(PRECACHE_URLS);
      })
      .then(() => self.skipWaiting())
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating service worker...');
  event.waitUntil(
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames
            .filter((name) => name !== CACHE_NAME)
            .map((name) => {
              console.log('[SW] Deleting old cache:', name);
              return caches.delete(name);
            })
        );
      })
      .then(() => self.clients.claim())
  );
});

// Fetch event - implement caching strategies
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Only handle same-origin requests under our PREFIX
  if (url.origin !== location.origin || !url.pathname.startsWith(PREFIX)) {
    return;
  }

  // Network-first strategy for HTML navigation requests
  if (request.mode === 'navigate' || request.destination === 'document') {
    event.respondWith(
      fetch(request)
        .then((response) => {
          // Cache successful navigation responses
          if (response && response.status === 200) {
            const responseClone = response.clone();
            caches.open(CACHE_NAME).then((cache) => {
              cache.put(request, responseClone);
            });
          }
          return response;
        })
        .catch(() => {
          // Fallback to cached index.html when offline
          return caches.match(`${PREFIX}/index.html`)
            .then((cachedResponse) => {
              if (cachedResponse) {
                console.log('[SW] Serving cached index.html (offline)');
                return cachedResponse;
              }
              // If no cache available, return a basic offline page
              return new Response(
                '<html><body><h1>Offline</h1><p>Please check your internet connection.</p></body></html>',
                { headers: { 'Content-Type': 'text/html' } }
              );
            });
        })
    );
    return;
  }

  // Stale-While-Revalidate strategy for static assets
  event.respondWith(
    caches.match(request)
      .then((cachedResponse) => {
        // Fetch from network in background and update cache
        const fetchPromise = fetch(request)
          .then((networkResponse) => {
            if (networkResponse && networkResponse.status === 200) {
              const responseClone = networkResponse.clone();
              caches.open(CACHE_NAME).then((cache) => {
                cache.put(request, responseClone).catch((error) => {
                  console.error('[SW] Failed to cache resource:', error);
                });
              });
            }
            return networkResponse;
          })
          .catch((error) => {
            console.log('[SW] Network request failed:', error);
            // Network failed, return cached response if available
            if (cachedResponse) {
              return cachedResponse;
            }
            // If no cached response, throw error to propagate
            throw error;
          });

        // Return cached response immediately if available, otherwise wait for network
        return cachedResponse || fetchPromise;
      })
  );
});

// Handle messages from clients
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    console.log('[SW] Received SKIP_WAITING message');
    self.skipWaiting();
  }
});
