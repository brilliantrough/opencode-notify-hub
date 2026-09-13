enum PluginShell { bash, powershell }

String pluginEnvironment({
  required String gateway,
  required String credential,
  required String machine,
  PluginShell shell = PluginShell.bash,
}) {
  String quote(String value) => shell == PluginShell.bash
      ? "'${value.replaceAll("'", "'\"'\"'")}'"
      : "'${value.replaceAll("'", "''")}'";
  final variables = {
    'NOTIFY_GATEWAY_URL': gateway,
    'NOTIFY_INGEST_KEY': credential,
    'NOTIFY_MACHINE': machine.trim().isEmpty
        ? 'YOUR_MACHINE_NAME'
        : machine.trim(),
  };
  return variables.entries
      .map(
        (entry) => shell == PluginShell.bash
            ? 'export ${entry.key}=${quote(entry.value)}'
            : '\$env:${entry.key} = ${quote(entry.value)}',
      )
      .join('\n');
}
