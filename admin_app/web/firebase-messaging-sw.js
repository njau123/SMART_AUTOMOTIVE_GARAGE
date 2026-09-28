// Firebase Messaging Service Worker — Admin
// Background notifications (browser imefungwa / tab haiko active)

importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyBWTqUOMT2kIqs51KyWdngnzdzy8Epafdc",
  authDomain: "smart-automotive-garage.firebaseapp.com",
  projectId: "smart-automotive-garage",
  storageBucket: "smart-automotive-garage.firebasestorage.app",
  messagingSenderId: "556100186888",
  appId: "1:556100186888:web:0e7eaa6d91cd2dc3b6b2bd",
});

const messaging = firebase.messaging();

// Background message handler
messaging.onBackgroundMessage((payload) => {
  console.log('[sw.js] Background message:', payload);

  const title = payload.notification?.title || 'Smart Garage';
  const body = payload.notification?.body || '';
  const icon = payload.notification?.image || '/icons/Icon-192.png';
  const data = payload.data || {};

  self.registration.showNotification(title, {
    body: body,
    icon: icon,
    badge: '/icons/Icon-192.png',
    tag: 'smart-garage-' + (data.type || 'default'),
    requireInteraction: true,
    data: data,
  });
});

// Click handler — fungua app
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = event.notification.data?.url || '/';
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((wins) => {
      for (const w of wins) {
        if (w.url.includes(self.location.origin) && 'focus' in w) {
          return w.focus();
        }
      }
      if (clients.openWindow) return clients.openWindow(url);
    })
  );
});
