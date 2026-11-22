{{flutter_js}}
{{flutter_build_config}}

// Start the app without Flutter's deprecated service worker: it unregisters
// itself and would replace ZankoSwap's own sw.js (needed for installing).
_flutter.loader.load();
