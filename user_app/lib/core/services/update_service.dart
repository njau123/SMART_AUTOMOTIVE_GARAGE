// Conditional export — web uses real implementation,
// non-web uses no-op stub.
export 'update_stub.dart' if (dart.library.html) 'update_web.dart';
