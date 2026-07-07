class SeekUBuildInfo {
  const SeekUBuildInfo._();

  static const version = 'v0.1.0snapshot3';
  static const gitHash = String.fromEnvironment(
    'SEEKU_GIT_HASH',
    defaultValue: 'd10bf6d',
  );

  static const displayVersion = '$version/$gitHash';
}
