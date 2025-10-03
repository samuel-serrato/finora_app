// my_sw.js

// ======================================================================================
// CONFIGURACIÓN
// ======================================================================================
const CACHE_NAME_PREFIX = 'finora-cache';
// ¡¡¡IMPORTANTE!!! Para probar, cámbialo a una versión superior, por ej: 'v2.0.9'
const VERSION = 'v2.0.10'; 
const CACHE_NAME = `${CACHE_NAME_PREFIX}-${VERSION}`;

// ... el resto de tu SW se queda exactamente igual ...
const APP_SHELL_URLS = [
  '/',
  '/index.html',
  '/favicon.png',
  '/icons/Icon-192.png',
  '/manifest.json'
];

self.addEventListener('install', event => {
  //console.log(`[Service Worker ${VERSION}] - Instalando...`);
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => {
      //console.log(`[Service Worker ${VERSION}] - Precargando App Shell en caché.`);
      return cache.addAll(APP_SHELL_URLS);
    })
  );
});

self.addEventListener('activate', event => {
  //console.log(`[Service Worker ${VERSION}] - Activado y listo para tomar el control.`);
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames
          .filter(name => name.startsWith(CACHE_NAME_PREFIX) && name !== CACHE_NAME)
          .map(name => {
            //console.log(`[Service Worker ${VERSION}] - Borrando caché antigua: ${name}`);
            return caches.delete(name);
          })
      );
    })
  );
});

self.addEventListener('fetch', event => {
    // Tu lógica de fetch está bien, la dejamos como está.
    if (event.request.method !== 'GET') {
      return;
    }
    const url = new URL(event.request.url);
    if (url.pathname.startsWith('/api/')) {
      event.respondWith(fetch(event.request));
      return;
    }
    event.respondWith(
      caches.match(event.request).then(cachedResponse => {
        if (cachedResponse) {
          return cachedResponse;
        }
        return fetch(event.request).then(networkResponse => {
          const responseToCache = networkResponse.clone();
          if (networkResponse && networkResponse.status === 200) {
              caches.open(CACHE_NAME).then(cache => {
                  cache.put(event.request, responseToCache);
              });
          }
          return networkResponse;
        });
      })
    );
});


// ¡LA PIEZA CLAVE QUE VAMOS A USAR!
self.addEventListener('message', event => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    //console.log(`[Service Worker ${VERSION}] - Recibido skipWaiting. Activando inmediatamente.`);
    self.skipWaiting();
  }
});