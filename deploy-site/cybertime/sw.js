const CACHE = 'cybertime-assets-v3';
const ASSETS = ['./index.js', './index.wasm', './index.pck'];

self.addEventListener('install', (event) => {
	event.waitUntil(
		caches.open(CACHE).then((cache) => cache.addAll(ASSETS)).then(() => self.skipWaiting()).catch(() => self.skipWaiting())
	);
});

self.addEventListener('activate', (event) => {
	event.waitUntil(
		caches.keys().then((keys) =>
			Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
		).then(() => self.clients.claim())
	);
});

self.addEventListener('fetch', (event) => {
	const req = event.request;
	if (req.method !== 'GET') return;
	const url = new URL(req.url);
	if (!url.pathname.includes('/cybertime/')) return;
	event.respondWith((async () => {
		const cache = await caches.open(CACHE);
		const cached = await cache.match(req);
		if (cached) return cached;
		const res = await fetch(req);
		if (res && res.ok && /\.(wasm|pck|js)$/.test(url.pathname)) {
			cache.put(req, res.clone());
		}
		return res;
	})());
});
