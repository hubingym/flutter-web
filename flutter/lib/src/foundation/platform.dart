enum TargetPlatform {
  android,

  fuchsia,

  iOS,
}

TargetPlatform get defaultTargetPlatform {
  if (debugDefaultTargetPlatformOverride != null)
    return debugDefaultTargetPlatformOverride;
  return TargetPlatform.android;
}

TargetPlatform debugDefaultTargetPlatformOverride;
