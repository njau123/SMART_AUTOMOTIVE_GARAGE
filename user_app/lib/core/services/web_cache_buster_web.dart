import 'dart:js_interop';
import 'dart:js_interop_unsafe';

Future<void> clearWebCache() async {
  try {
    // 1. Unregister service workers
    final nav = globalContext['navigator'];
    if (nav != null) {
      final sw = (nav as JSObject)['serviceWorker'];
      if (sw != null) {
        final swObj = sw as JSObject;
        final regsPromise = swObj.callMethod<JSAny?>('getRegistrations'.toJS);
        if (regsPromise != null) {
          final regs = await (regsPromise as JSPromise).toDart;
          if (regs != null) {
            final regsArr = regs as JSArray;
            final len = regsArr.length;
            for (int i = 0; i < len; i++) {
              final reg = regsArr[i];
              (reg as JSObject).callMethod<JSAny?>('unregister'.toJS);
            }
          }
        }
      }
    }

    // 2. Delete caches
    final caches = globalContext['caches'];
    if (caches != null) {
      final cachesObj = caches as JSObject;
      final keysPromise = cachesObj.callMethod<JSAny?>('keys'.toJS);
      if (keysPromise != null) {
        final keys = await (keysPromise as JSPromise).toDart;
        if (keys != null) {
          final keysArr = keys as JSArray;
          final len = keysArr.length;
          for (int i = 0; i < len; i++) {
            final key = keysArr[i];
            cachesObj.callMethod<JSAny?>('delete'.toJS, key);
          }
        }
      }
    }
  } catch (_) {}
}
