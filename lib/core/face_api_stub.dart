Future<void> loadFaceApiModels() async {}

Future<bool> isFaceApiReady() async => false;

/// Stub — face camera not available on non-web.
({String viewType, Object video}) createFaceCameraView() =>
    (viewType: 'stub', video: Object());

Future<void> startCamera(Object video) async {}

void stopCamera(Object video) {}

/// Stub — always returns null on non-web.
Future<List<double>?> detectFaceDescriptor(Object videoElement) async => null;

double euclideanFaceDistance(List<double> a, List<double> b) => 1.0;
