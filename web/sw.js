// ZankoSwap service worker: makes the site installable as an app and shows a
// Kurdish message when the phone has no internet. Nothing is cached, so users
// always get the newest version of the app.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));

const OFFLINE_PAGE = `<!doctype html><html lang="ckb" dir="rtl"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>ZankoSwap</title></head>
<body style="margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;
background:#071D16;color:#ECFDF5;font:17px/1.7 system-ui,-apple-system,Tahoma,sans-serif;text-align:center">
<div style="padding:24px"><div style="font-size:44px">📶</div>
<b>ئینتەرنێت نییە</b><br>تکایە پەیوەندی ئینتەرنێتەکەت بپشکنە و دووبارە هەوڵ بدەرەوە.<br><br>
<button onclick="location.reload()" style="font:inherit;border:0;border-radius:10px;
padding:10px 22px;background:#10B981;color:#04120D;font-weight:700">دووبارە هەوڵ بدەرەوە</button>
</div></body></html>`;

self.addEventListener('fetch', (event) => {
  if (event.request.mode !== 'navigate') return;
  event.respondWith(
    fetch(event.request).catch(
      () => new Response(OFFLINE_PAGE, {
        headers: { 'Content-Type': 'text/html; charset=utf-8' },
      }),
    ),
  );
});
