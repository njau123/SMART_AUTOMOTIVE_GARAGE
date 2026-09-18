// Firebase Cloud Messaging Service Worker
// Smart Automotive Garage

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyBWTqUOMT2kIqs51KyWdngnzdzy8Epafdc",
  authDomain: "smart-automotive-garage.firebaseapp.com",
  projectId: "smart-automotive-garage",
  storageBucket: "smart-automotive-garage.firebasestorage.app",
  messagingSenderId: "556100186888",
  appId: "1:556100186888:web:0e7eaa6d91cd2dc3b6b2bd",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[SW] Background message:', payload);

  const notificationTitle = payload.notification?.title || 'Smart Automotive Garage';
  const notificationOptions = {
    body: payload.notification?.body || 'Una ujumbe mpya',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data || {},
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});
