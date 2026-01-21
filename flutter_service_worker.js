'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"icons/Icon-512.png": "fb823e0eb9298955b9ca24e804d1110b",
"icons/Icon-maskable-512.png": "fb823e0eb9298955b9ca24e804d1110b",
"icons/Icon-192.png": "5744477b3171887b63c3f59d0135e53d",
"icons/Icon-maskable-192.png": "5744477b3171887b63c3f59d0135e53d",
"manifest.json": "78e3a5c975f6a88a098084d1890b7482",
"index.html": "fc92a804446e6e1a6a205271c90cc43d",
"/": "fc92a804446e6e1a6a205271c90cc43d",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin.json": "31a95b59f880dfc2fe06ecc6b06fef9f",
"assets/assets/images/character_clean.png": "84cf706cab4e91b9cdf1c7d264483c46",
"assets/assets/images/chema_clean.png": "d0a3df83a0947d6f61855c767eaa8aa9",
"assets/assets/images/layer_1_sky_mexico.png": "83dd0918d275fdaf629604cbf4e38985",
"assets/assets/images/nakama_clean.png": "b8ef3ff2d50c9cfe7ebc7e56f09cc570",
"assets/assets/images/aura.png": "4d095d47756003f62f0469a36998a89d",
"assets/assets/images/intro_bg_checkerboard.png": "5c024aaf7d34349094f1ff8812653247",
"assets/assets/images/version_v5_retro.png": "da6cd11554689ceaf91fc7bc9e3105d5",
"assets/assets/images/cat_clean.png": "47cc5cb26ce43100fb49870aac8e4344",
"assets/assets/images/version_v4_retro.png": "507db6cbc9259ae6031cd2712871dd52",
"assets/assets/images/layer_3_ground_mexico.png": "cb4ffe64981059d5cc8a29346d510d6b",
"assets/assets/images/ability_button.png": "10b3078c0f22dd36de44702e7bce9f25",
"assets/assets/images/layer_3_ground.png": "3d16713caae3109b4c2c985b549bf208",
"assets/assets/images/icon.png": "c57b5084a39a656dff4b7f050c96e227",
"assets/assets/images/layer_1_sky.png": "1f15e292ac76a46de19b84fee4651955",
"assets/assets/images/conra_clean.png": "2d5d2033bc870a68deabac617a5cc2ec",
"assets/assets/images/cat.png": "be6073f32b7a52a4043762ba04b54550",
"assets/assets/images/parker_clean.png": "dc7458a98d69b99fc4c5bf71192ebf3d",
"assets/assets/images/tank_shield_icon.png": "260fe5f2ca3f4fea325913a8ddf99b07",
"assets/assets/images/character.png": "2b75cb5bbca9525b1f06d9fe4a56a28e",
"assets/assets/images/lightning_icon.png": "5182e39b2440c48bb59fef1602700067",
"assets/assets/images/jano_clean%2520copy.png": "84cf706cab4e91b9cdf1c7d264483c46",
"assets/assets/images/layer_3_ground_modern.png": "754793bdda49d308aebaa6ade10baba8",
"assets/assets/images/jano_clean.png": "84cf706cab4e91b9cdf1c7d264483c46",
"assets/assets/images/layer_1_sky_modern.png": "f1be335a4266cfe783abf94ba3b8ce7d",
"assets/assets/images/bullet.png": "b5fa186cede63d3701c2b47c41d46cfa",
"assets/assets/images/heart_indicator.png": "093440e1be9140361fa117ca9f928824",
"assets/assets/images/jano%2520copy.png": "84cf706cab4e91b9cdf1c7d264483c46",
"assets/assets/images/dog_clean.png": "86be679676f8aac96caa598ca28d5b8c",
"assets/assets/images/orb.png": "8ec969ebcde8ba0e19e7b537b7a53aaf",
"assets/assets/images/layer_2_background_mexico.png": "998d9a96a11bcd415026e8a0a9a418ae",
"assets/assets/images/dog.png": "667c9e1c2cd7e79561848dfe1bbbf94d",
"assets/assets/images/layer_2_city.png": "11c3c2fcde93266e57fc28338d906789",
"assets/assets/images/nanic_clean.png": "b238e23f127eb454a5e73ee5cafbbf1c",
"assets/assets/images/start_button_retro.png": "d67d3d06ea4fc8fb89e65f6ac49bc284",
"assets/assets/images/jano.png": "84cf706cab4e91b9cdf1c7d264483c46",
"assets/assets/images/title_retro.png": "6016ace63774d68e8f00a560b26ad3f4",
"assets/assets/images/layer_2_city_modern.png": "f661a40085d55e39acdedc96b4b2db2f",
"assets/assets/images/shyno_clean.png": "6f63d085b6c15e290589899df5759945",
"assets/assets/audio/LoopSong.wav": "951a3c2cf169884fec4d6797019ac27c",
"assets/assets/audio/LoopSong.ogg": "cf7e727ac037843041475888a988ab3f",
"assets/assets/audio/Jump.wav": "d0b8cae332417ac25b28b67288ff0d64",
"assets/assets/audio/Select.wav": "f0190dcf4553d61e707e93f816b85c77",
"assets/assets/audio/Hit.wav": "4b3734fd1435449887b3d87972a8b40f",
"assets/assets/audio/Shoot.wav": "edb699d1ac6e1c295d9a6cb4519b5f31",
"assets/assets/audio/Invisibility.wav": "5538cb056fc71e72cbdf92a1cb055ee9",
"assets/fonts/MaterialIcons-Regular.otf": "2902b56e4b535e6da56a69a50316702d",
"assets/NOTICES": "a073f4c667d07d537c0156d8c2d62d6f",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin": "7fa6ef3b7b1fed9d3a46bdc9869dd95b",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"favicon.png": "eb674ca4e57c5a72791778d30b69efec",
"flutter_bootstrap.js": "66edf93d7d48a7f7e825bbe2ed74a1fe",
"version.json": "c17df86ce45b060602689e93181d13b7",
"main.dart.js": "ecc8e410de7108e9c7924c10be2d78d7"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
