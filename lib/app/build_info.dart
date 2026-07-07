class SeekUBuildInfo {
  const SeekUBuildInfo._();

  static const version = 'v0.1.0-rc.1';
  static const gitHash = String.fromEnvironment(
    'SEEKU_GIT_HASH',
    defaultValue: '3d6ed30',
  );

  static const displayVersion = '$version/$gitHash';
}
