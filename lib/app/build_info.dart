class SeekUBuildInfo {
  const SeekUBuildInfo._();

  static const version = 'v0.1.1-snapshot';
  static const gitHash = String.fromEnvironment(
    'SEEKU_GIT_HASH',
    defaultValue: '58a7cc5',
  );

  static const displayVersion = '$version/$gitHash';
}

