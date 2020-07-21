const bool kReleaseMode =
    bool.fromEnvironment('dart.vm.product', defaultValue: false);

const bool kProfileMode =
    bool.fromEnvironment('dart.vm.profile', defaultValue: false);

const bool kDebugMode = !kReleaseMode && !kProfileMode;

const double precisionErrorTolerance = 1e-10;

const bool kIsWeb = identical(0, 0.0);
