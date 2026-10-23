/// Hands bytes to the browser as a download, from ../app.
///
/// `file_picker` 8 has no save dialog on the web, so there a saved file is
/// downloaded the way any web page does. Off the web this is never called.
library;

export 'web_download_stub.dart'
    if (dart.library.js_interop) 'web_download_web.dart';
