import 'web_download_helper_stub.dart'
    if (dart.library.html) 'web_download_helper_web.dart';

Future<void> downloadPngOnWeb(List<int> pngBytes, String fileName) =>
    downloadPngOnWebImpl(pngBytes, fileName);
