'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"icons/favicon.svg": "f8b449c767f70b06725a7a7227832272",
"icons/apple-touch-icon.png": "1c21e7fa9c77092060bb521956aab32b",
"icons/favicon.ico": "0cd454d8b26731b5dd9958c8ed62e4c4",
"icons/web-app-manifest-512x512.png": "d7ba07cb107181e97566eb3f2a8f31b2",
"icons/Icon-96.png": "fd9e4f159f9587882c2fcd450d69db1a",
"icons/web-app-manifest-192x192%20(Copy).png": "0e36686474012864d7120d45d82685e7",
"icons/Icon-maskable-192.png": "cec670660acdbd70f811ce811ccd6fb4",
"icons/Icon-192.png": "0e36686474012864d7120d45d82685e7",
"icons/Icon-maskable-512.png": "3549287025cbc4e70bdd88b003adffc2",
"icons/Icon-512.png": "d7ba07cb107181e97566eb3f2a8f31b2",
"assets/fonts/MaterialIcons-Regular.otf": "7d7d26fbc2d92e6aec043c6fca009b6e",
"assets/AssetManifest.bin.json": "df1a071651766e3b9f56b3c3fb989016",
"assets/AssetManifest.bin": "340907ec8ad2867845660463bfb1017a",
"assets/AssetManifest.json": "6986fde41a3a0029826873942d915d78",
"assets/assets/fonts/Vazirmatn.ttf": "63d2e128b5b911ac9455e5204f36d45f",
"assets/assets/fonts/CourierPrime.ttf": "fba4686ed1d1b4ef05ab14db78805dbe",
"assets/assets/fonts/Quicksand.ttf": "eb9ba45f2351c34b9aba487db9ce5762",
"assets/assets/fonts/SF-Pro.ttf": "b00758ffdb3216ea93c6fc6957aa2cfa",
"assets/assets/fonts/Onest.ttf": "3e0047e3acfa2e68f3349c3787b54863",
"assets/assets/config/priority_assets.json": "9d915e29a74acfa1e88884c10262a67b",
"assets/assets/config/terms_en.json": "85b0ad932e95e0b964b874c597cf8f78",
"assets/assets/config/terms_fa.json": "c875797346030cecfeac7427430afbaa",
"assets/assets/config/app_config.json": "b5fd584906bb3ab44742122964224eb1",
"assets/assets/icons/flags/tr.svg": "dc2756ac973c1731744b845fcab9f786",
"assets/assets/icons/flags/sa.svg": "6a6a776e6eafd7894a15b59489d256e0",
"assets/assets/icons/flags/jp.svg": "be04fd894b0d6e13a16ec1bb874b74e2",
"assets/assets/icons/flags/us.svg": "a1454bbb5b13a30a70af5851b3aaa8a4",
"assets/assets/icons/flags/om.svg": "957fa2cc624a8264e6335f7fb2d94dad",
"assets/assets/icons/flags/ru.svg": "083dca98f3cebfd6bcc2471c60e2748a",
"assets/assets/icons/flags/eu.svg": "871ae2e7221011c886ebe7ea36787943",
"assets/assets/icons/flags/pk.svg": "8e1b819cec9ac503c212583bcfdbbb0b",
"assets/assets/icons/flags/ca.svg": "42c61d70587393fa5270d4addab566a6",
"assets/assets/icons/flags/se.svg": "01887b79a05dc88a4c59f3dc8ce2bf97",
"assets/assets/icons/flags/my.svg": "af3c3e9b290175550cb7a19b7721ccb5",
"assets/assets/icons/flags/kw.svg": "f236070f2b656334445a684af35fa9be",
"assets/assets/icons/flags/au.svg": "b966d328a46774f56be26905f9eb9684",
"assets/assets/icons/flags/af.svg": "5ce6cd72be6763228940e78d13e2cac4",
"assets/assets/icons/flags/qa.svg": "97b9b44e33ccbbe459a0e3fda97d9f18",
"assets/assets/icons/flags/ch.svg": "f45a7dbf12930ac8ef8e9db2123feda5",
"assets/assets/icons/flags/uk.svg": "c2c3cadcc5b107aaaee8df05b7811921",
"assets/assets/icons/flags/iq.svg": "0885ff7d2ac292fcd7cdd5dacef7f4e4",
"assets/assets/icons/flags/am.svg": "3367445df6aacf4268a867f54b2aa012",
"assets/assets/icons/flags/th.svg": "f213dbbef7b45a13ca72862af6e662d3",
"assets/assets/icons/flags/ae.svg": "dfeb0f940880884d11f30ebceef464be",
"assets/assets/icons/flags/az.svg": "93d4994bf0c2670aea991618878b0688",
"assets/assets/icons/flags/cn.svg": "daa4b5a7e549d7f7897e5101f6dc5131",
"assets/assets/icons/flags/ge.svg": "d2a986b5d09e6315c142fe360bb676e4",
"assets/assets/icons/flags/in.svg": "51112aca8b3e19c68fce3bc46f67f19d",
"assets/assets/icons/flags/gb.svg": "c2c3cadcc5b107aaaee8df05b7811921",
"assets/assets/icons/flags/bh.svg": "4bc0dacd5d4dc23475bb441fd603bdd4",
"assets/assets/icons/flags/sy.svg": "460a6e6f3f9f5c380b449015b446d324",
"assets/assets/icons/crypto/Namecoin%2520(NMC).svg": "6eec040106ffc3eec0854ab94c4898e1",
"assets/assets/icons/crypto/Qtum%2520(QTUM).svg": "a4de7c1d47a1196979d0e86eac5e682d",
"assets/assets/icons/crypto/Primecoin%2520(XPM).svg": "5677038976902183c4fd59c1d41e4926",
"assets/assets/icons/crypto/Peercoin%2520(PPC).svg": "deecba46cdb6e1540182d56d2ec1fa38",
"assets/assets/icons/crypto/Power%2520Ledger%2520(POWR).svg": "86caa9cc4774488c2d22faa1cbf8c8ac",
"assets/assets/icons/crypto/zec.svg": "6b7477abd8f380e1bdb3f68cebadfea8",
"assets/assets/icons/crypto/CloakCoin%2520(CLOAK).svg": "bf42079644db9c737007a8ad28a6960b",
"assets/assets/icons/crypto/Tether.svg": "dea1590a2a2f78c99a92f3f809cbdb7e",
"assets/assets/icons/crypto/Basic%2520Attention%2520Token.svg": "6b43371afa3d3dbc1baca43c8447aec2",
"assets/assets/icons/crypto/Bitcoin%2520Cash.svg": "6f79da6494ef983059466509aa141206",
"assets/assets/icons/crypto/Baelf%2520(ELF).svg": "3b439f058567dbb067a2f0810dd2cf3a",
"assets/assets/icons/crypto/Counterparty%2520(XCP).svg": "9c7eea2ddc349b34729ff1ace26475bd",
"assets/assets/icons/crypto/EOS.svg": "e5e47600c7117692032a344a67d80b2e",
"assets/assets/icons/crypto/Zilliqa%2520(ZIL).svg": "e3e27e5f1b289c6e892f3f99199505f3",
"assets/assets/icons/crypto/Callisto%2520Network%2520(CLO).svg": "f58b279bf6a680f416bdeb4463763aeb",
"assets/assets/icons/crypto/XTRABYTES%2520(XBY).svg": "6cb3de9c9b5d9f780a14564eec10be44",
"assets/assets/icons/crypto/Nimiq%2520(NIM).svg": "559d0268595d86ce5620c2e4b5d9b1ea",
"assets/assets/icons/crypto/PIVX%2520(PIVX).svg": "0983f9202ba6b4ab752856a799ad6c35",
"assets/assets/icons/crypto/Dogecoin%2520(DOGE).svg": "fd3048515d876b633daeee0d2cf7b84f",
"assets/assets/icons/crypto/ripple.svg": "66f051a9bba0253f6c39deba09c00160",
"assets/assets/icons/crypto/Crown%2520(CRW).svg": "cf28eafd632cec3d433b48ff20f1a392",
"assets/assets/icons/crypto/ZClassic%2520(ZCL).svg": "902c38738a511bcfedb5abf53231740f",
"assets/assets/icons/crypto/Verge%2520(XVG).svg": "dce476655282792cf6a618c735806814",
"assets/assets/icons/crypto/btc.svg": "1d11b5f60f587fc444c8b785136ba79c",
"assets/assets/icons/crypto/Steem%2520Dollars%2520(SBD).svg": "c4d7316486cc82e28e18d3cb7c14b5a9",
"assets/assets/icons/crypto/Ethereum%2520Classic%2520(ETH).svg": "60f138e1409e392e29887191f9beb2f6",
"assets/assets/icons/crypto/Vertcoin%2520(VTC).svg": "c92b71a23aed65294ba4947a5235960d",
"assets/assets/icons/crypto/Ontology%2520(ONT).svg": "9db79bbcddd894494d7e6e8b893827b1",
"assets/assets/icons/crypto/Golem%2520(GNT).svg": "ea1b5fd104b78b7d5e6d4a6d5d65f983",
"assets/assets/icons/crypto/nano%2520(NANO).svg": "7fa002028202a791287e943b47e146a3",
"assets/assets/icons/crypto/NEM%2520(XEM).svg": "4249b0bbc44b1d8b3ea43dccba2a4e98",
"assets/assets/icons/crypto/Binance%2520Coin%2520(BNB).svg": "648de067a8ac2c24ad016f142d6f215e",
"assets/assets/icons/crypto/Syscoin%2520(SYS).svg": "122b3b9ac589f9bf0747c32e04ee45ac",
"assets/assets/icons/crypto/dash.svg": "616748960c59b4dccfd660de360e190e",
"assets/assets/icons/crypto/Litecoin%2520Cash%2520(LCC).svg": "709ffa0817312bc09d175b3bebd1b5cf",
"assets/assets/icons/crypto/Decred%2520(DCR).svg": "fb050ab37da95a908412048dfa8c9bd3",
"assets/assets/icons/crypto/Dero%2520(DERO).svg": "06d1c7da009d6437a1d25a632841e15c",
"assets/assets/icons/crypto/Waves%2520(WAVES).svg": "5b5b3678a7a6fa794d4a1c0295a59fad",
"assets/assets/icons/crypto/NEO.svg": "885b26d73bfc2cdb64fb97e4e9ae429f",
"assets/assets/icons/crypto/MonaCoin%2520(MONA).svg": "9252ac1e573ae094d3852e4090944c0e",
"assets/assets/icons/crypto/Nuls%2520(NULS).svg": "0298de8cd13c161526a9e172e0a599dd",
"assets/assets/icons/crypto/Steem%2520(STEEM).svg": "2456380d86efe244bb716e0f852a0704",
"assets/assets/icons/crypto/Lisk%2520(LSK).svg": "8fcee04ef6625088635421417f52cd77",
"assets/assets/icons/crypto/SmartCash%2520(SMART).svg": "581d01d2b72e805ea959700779bf7c09",
"assets/assets/icons/crypto/Tezos%2520(XTZ).svg": "efb42781ff5a428ebfb251c539b72408",
"assets/assets/icons/crypto/QuarkChain%2520(QKC).svg": "60efc2d4e871ca5ee04b0d62406083a5",
"assets/assets/icons/crypto/Cardano.svg": "fc9d01c83fe553e7347c652e29dc7e10",
"assets/assets/icons/crypto/Siacoin%2520(SC).svg": "f2e9679330b551f331fb59bad523371b",
"assets/assets/icons/crypto/GameCredits%2520(GAME).svg": "5a9b0046e5b3252f151b0e2f9bd93218",
"assets/assets/icons/crypto/Monero.svg": "f661839c820935e4ecf03dd334e6548f",
"assets/assets/icons/crypto/Stellar.svg": "78dc1b9f42d517f6f0239b43186899ff",
"assets/assets/icons/crypto/ColossusXT%2520(COLX).svg": "04ad933b9e2147a0a9c3eff87d76d742",
"assets/assets/icons/crypto/PRIZM%2520(PZM).svg": "7d05baa2f19502f33ab5e19b80791cd9",
"assets/assets/icons/crypto/WhiteCoin%2520(XWC).svg": "11da4b9b7c29a422bb5a2ab6610f8eff",
"assets/assets/icons/crypto/Ethereum.svg": "61a3f99277f28ce4bc04e237a93b4711",
"assets/assets/icons/crypto/Horizen%2520(ZEN).svg": "84e20175ce797b7bdbba6f6ff5260df6",
"assets/assets/icons/crypto/DigiByte%2520(DGB).svg": "fb88f88fb00a56453c9edb424ec7eb77",
"assets/assets/icons/crypto/Particl%2520(PART).svg": "8f493d914c18ebab8014ea2a01dadcc8",
"assets/assets/icons/crypto/OmiseGO%2520(OMG).svg": "197ff35be41b1903412db514bba66e4d",
"assets/assets/icons/crypto/usd.svg": "0c03dce37bffbe89812eabf49b16c1b7",
"assets/assets/icons/crypto/Bytecoin%2520(BCN).svg": "b89965ad2ef472a6474142f89da3cafe",
"assets/assets/icons/crypto/Dent%2520(DENT).svg": "e62ca54c0748e9c974fbcd4a0b143a05",
"assets/assets/icons/crypto/lite.svg": "3315573991c32f4e62c1ff6d4dbe2557",
"assets/assets/icons/crypto/TrueUSD%2520(TUSD).svg": "447c5af8c8f93464b496defe44acb1db",
"assets/assets/icons/crypto/Pascal%2520Coin%2520(PASC).svg": "7270eee1506a100978988f3efa750b0e",
"assets/assets/icons/crypto/Komodo%2520(KMD).svg": "63d841789f4742dd847f79fcad18c763",
"assets/assets/icons/crypto/Electroneum%2520(ETN).svg": "1b84bcd9e101db7b8c376698fe6a1a27",
"assets/assets/icons/crypto/Wanchain.svg": "40c1fc15f6d36f056cc0d0fe58d959b4",
"assets/assets/icons/crypto/VeChain%2520(VET).svg": "d042a2a325a41ce4b968a26ed47d2c19",
"assets/assets/icons/crypto/LBRY%2520Credits%2520(LBC).svg": "ca28d34ed677a6e348c772b64efa225b",
"assets/assets/icons/crypto/Enjin%2520Coin%2520(ENJ).svg": "dd134179b5c9f0c74c40336ad9c541ae",
"assets/assets/icons/commodity/blank.png": "80e022432423c472a7db1b241ec777e1",
"assets/assets/icons/commodity/element.png": "cce416de8dfe3ab3fecb683923035039",
"assets/assets/icons/commodity/oil.png": "971cc75023c0ab2e3d0d632f276d2fb0",
"assets/assets/icons/commodity/emami.png": "db80ad8097f9b689d6ded6ba2cc656ee",
"assets/assets/icons/commodity/melted.png": "1da9af099093635045a3b3424a13cfd5",
"assets/assets/icons/commodity/gold_ounce.png": "8cde0c6c5754817ca14a1ed1467cf0ce",
"assets/assets/icons/commodity/18_carat.png": "1da9af099093635045a3b3424a13cfd5",
"assets/assets/icons/commodity/gas_oil.png": "507f32fc934db1f46784fe0640861ceb",
"assets/assets/icons/commodity/bahar.png": "4dc62a6ab89c5a0e47e6367558d53006",
"assets/assets/icons/commodity/quarter.png": "1da9af099093635045a3b3424a13cfd5",
"assets/assets/icons/commodity/silver_ounce.png": "da21b492a4178655e188d66da98f27a2",
"assets/assets/icons/commodity/gas.png": "6dc2312926ba6b30ed495ca48b863c1b",
"assets/assets/icons/commodity/p_ounce.png": "da21b492a4178655e188d66da98f27a2",
"assets/assets/icons/commodity/1g.png": "1da9af099093635045a3b3424a13cfd5",
"assets/assets/icons/commodity/24_carat.png": "1da9af099093635045a3b3424a13cfd5",
"assets/assets/icons/commodity/half.png": "1da9af099093635045a3b3424a13cfd5",
"assets/assets/images/riyales-light.png": "c8416bee10c63bd23b9a177e73ded60e",
"assets/assets/images/riyales.png": "949a9c72c10e8b4a53cdc1b9fe849d85",
"assets/assets/images/splash-screen-dark.svg": "3c9cfa7bd7a6b6aad32942e917548014",
"assets/assets/images/riyales-fade.png": "513040b2bc19d9fb73bee517bfb6ef84",
"assets/assets/images/splash-screen-light.svg": "bab6312c4da7c3f2adfbb21e2a978cad",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "c4dca0e2b96f6bcf836c335044bc273b",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/FontManifest.json": "db8abed3fa2f2c0ec91ce1a8890001c5",
"assets/NOTICES": "2ac5e17496119548cc9e0b862ecf573b",
"main.dart.js": "583db3b3fb55058bfc89e2b20eaa0318",
"manifest.json": "0a8ba43f30613654354669e808dd76b4",
"version.json": "230f307fed05159b39dde01709897dff",
"canvaskit/skwasm.js.symbols": "96263e00e3c9bd9cd878ead867c04f3c",
"canvaskit/canvaskit.js": "26eef3024dbc64886b7f48e1b6fb05cf",
"canvaskit/skwasm.wasm": "828c26a0b1cc8eb1adacbdd0c5e8bcfa",
"canvaskit/canvaskit.wasm": "e7602c687313cfac5f495c5eac2fb324",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c",
"canvaskit/canvaskit.js.symbols": "efc2cd87d1ff6c586b7d4c7083063a40",
"canvaskit/skwasm.js": "ac0f73826b925320a1e9b0d3fd7da61c",
"canvaskit/chromium/canvaskit.js": "b7ba6d908089f706772b2007c37e6da4",
"canvaskit/chromium/canvaskit.wasm": "ea5ab288728f7200f398f60089048b48",
"canvaskit/chromium/canvaskit.js.symbols": "e115ddcfad5f5b98a90e389433606502",
"flutter_bootstrap.js": "53cf5e8fda90a8e9249c9a27fe93ce7a",
"favicon.png": "d7ba07cb107181e97566eb3f2a8f31b2",
"index.html": "e5147ebf3d85201470ba0a93ed50f768",
"/": "e5147ebf3d85201470ba0a93ed50f768",
"flutter.js": "4b2350e14c6650ba82871f60906437ea"};
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
