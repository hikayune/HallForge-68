import 'package:flutter/material.dart';
import 'package:hallforge68/win_hid.dart';

void main() {
  runApp(const HallForgeApp());
}

class HallForgeApp extends StatefulWidget {
  const HallForgeApp({super.key});

  @override
  State<HallForgeApp> createState() => _HallForgeAppState();
}

class _HallForgeAppState extends State<HallForgeApp> {
  final WinHidBridge _hidBridge = const WinHidBridge();
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme(bool useDarkTheme) {
    setState(() {
      _themeMode = useDarkTheme ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HallForge 68',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: HallForgeShell(
        hidBridge: _hidBridge,
        themeMode: _themeMode,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  const lightBackground = Color(0xFFF6F7F9);
  const lightSurface = Color(0xFFFFFFFF);
  const lightBorder = Color(0xFFDADDE3);
  const lightText = Color(0xFF1F2328);
  const lightSecondaryText = Color(0xFF6B7280);
  const lightPrimary = Color(0xFF2563EB);

  const darkBackground = Color(0xFF101114);
  const darkSurface = Color(0xFF181A1F);
  const darkBorder = Color(0xFF2A2D34);
  const darkText = Color(0xFFF3F4F6);
  const darkSecondaryText = Color(0xFFA1A1AA);
  const darkPrimary = Color(0xFF60A5FA);

  final background = isDark ? darkBackground : lightBackground;
  final surface = isDark ? darkSurface : lightSurface;
  final border = isDark ? darkBorder : lightBorder;
  final text = isDark ? darkText : lightText;
  final secondaryText = isDark ? darkSecondaryText : lightSecondaryText;
  final primary = isDark ? darkPrimary : lightPrimary;

  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: brightness,
  ).copyWith(
    primary: primary,
    onPrimary: isDark ? darkBackground : Colors.white,
    secondary: primary,
    onSecondary: isDark ? darkBackground : Colors.white,
    surface: surface,
    onSurface: text,
    onSurfaceVariant: secondaryText,
    outline: border,
    outlineVariant: border,
    shadow: Colors.black.withValues(alpha: isDark ? 0.32 : 0.06),
    scrim: Colors.black54,
    inverseSurface: isDark ? const Color(0xFFF3F4F6) : const Color(0xFF1F2328),
    onInverseSurface: isDark ? darkBackground : lightBackground,
    inversePrimary: isDark ? lightPrimary : darkPrimary,
    tertiary: primary,
    onTertiary: isDark ? darkBackground : Colors.white,
    tertiaryContainer: isDark ? const Color(0xFF163C73) : const Color(0xFFDCE8FF),
    onTertiaryContainer: text,
    primaryContainer: isDark ? const Color(0xFF163C73) : const Color(0xFFDCE8FF),
    onPrimaryContainer: text,
    secondaryContainer: isDark ? const Color(0xFF1B2435) : const Color(0xFFE8EEF9),
    onSecondaryContainer: text,
    error: const Color(0xFFDC2626),
    onError: Colors.white,
    errorContainer: isDark ? const Color(0xFF4B1D1D) : const Color(0xFFFEE2E2),
    onErrorContainer: text,
    surfaceTint: primary,
  );

  final baseTextTheme = Typography.material2021().black.apply(
        bodyColor: text,
        displayColor: text,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    canvasColor: background,
    dividerColor: border,
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: text,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: secondaryText,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: text,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: border),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: surface,
      indicatorColor: primary.withValues(alpha: isDark ? 0.20 : 0.12),
      selectedIconTheme: IconThemeData(color: primary),
      selectedLabelTextStyle: TextStyle(
        color: text,
        fontWeight: FontWeight.w600,
      ),
      unselectedIconTheme: IconThemeData(color: secondaryText),
      unselectedLabelTextStyle: TextStyle(color: secondaryText),
      groupAlignment: -1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: isDark ? darkBackground : Colors.white,
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: text,
        side: BorderSide(color: border),
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary),
      ),
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 4,
      activeTrackColor: primary,
      inactiveTrackColor: border,
      thumbColor: primary,
      overlayColor: primary.withValues(alpha: 0.12),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return isDark ? darkBackground : Colors.white;
        }
        return secondaryText;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary;
        }
        return border;
      }),
    ),
  );
}

enum AppSection {
  device('Device', Icons.usb_rounded),
  keys('Keys', Icons.keyboard_rounded),
  actuation('Actuation', Icons.tune_rounded),
  rapidTrigger('Rapid Trigger', Icons.flash_on_rounded),
  lighting('Lighting', Icons.lightbulb_outline_rounded),
  profiles('Profiles', Icons.layers_outlined),
  settings('Settings', Icons.settings_outlined);

  const AppSection(this.label, this.icon);

  final String label;
  final IconData icon;
}

class HallForgeShell extends StatefulWidget {
  const HallForgeShell({
    super.key,
    required this.hidBridge,
    required this.themeMode,
    required this.onThemeChanged,
  });

  final WinHidBridge hidBridge;
  final ThemeMode themeMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<HallForgeShell> createState() => _HallForgeShellState();
}

class _HallForgeShellState extends State<HallForgeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final currentSection = AppSection.values[_selectedIndex];
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            Container(
              width: 272,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.keyboard_command_key_rounded,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HallForge 68',
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                'Desktop keyboard utility',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: NavigationRail(
                      selectedIndex: _selectedIndex,
                      useIndicator: true,
                      extended: true,
                      minExtendedWidth: 240,
                      leading: const SizedBox(height: 4),
                      destinations: [
                        for (final section in AppSection.values)
                          NavigationRailDestination(
                            icon: Icon(section.icon),
                            selectedIcon: Icon(section.icon),
                            label: Text(section.label),
                          ),
                      ],
                      onDestinationSelected: (index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dark mode',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Switch desktop theme',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: widget.themeMode == ThemeMode.dark ||
                              (widget.themeMode == ThemeMode.system && isDark),
                          onChanged: widget.onThemeChanged,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                child: Column(
                  children: [
                    _DesktopHeader(section: currentSection),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _SectionView(
                        section: currentSection,
                        hidBridge: widget.hidBridge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({required this.section});

  final AppSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.label,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  _sectionDescription(section),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 280,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search settings',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionView extends StatelessWidget {
  const _SectionView({
    required this.section,
    required this.hidBridge,
  });

  final AppSection section;
  final WinHidBridge hidBridge;

  @override
  Widget build(BuildContext context) {
    return switch (section) {
      AppSection.device => _DevicePage(hidBridge: hidBridge),
      AppSection.keys => const _KeysPage(),
      AppSection.actuation => const _ActuationPage(),
      AppSection.rapidTrigger => const _RapidTriggerPage(),
      AppSection.lighting => const _LightingPage(),
      AppSection.profiles => const _ProfilesPage(),
      AppSection.settings => const _SettingsPage(),
    };
  }
}

class _DevicePage extends StatefulWidget {
  const _DevicePage({required this.hidBridge});

  final WinHidBridge hidBridge;

  @override
  State<_DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<_DevicePage> {
  List<WinHidDeviceInfo> _devices = const [];
  WinHidDeviceInfo? _connectedDevice;
  String? _errorMessage;
  bool _isRefreshing = false;
  String? _busyDevicePath;

  @override
  void initState() {
    super.initState();
    _refreshDevices();
  }

  Future<void> _refreshDevices() async {
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      final devices = await widget.hidBridge.enumerateDevices(
        filter: kWin68HeHidFilter,
      );
      final connectedDevice = await widget.hidBridge.getConnectedDevice();
      final mergedDevices = List<WinHidDeviceInfo>.from(devices);
      if (connectedDevice != null &&
          mergedDevices.every((device) => device.path != connectedDevice.path)) {
        mergedDevices.insert(0, connectedDevice);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _devices = mergedDevices;
        _connectedDevice = connectedDevice;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _connectDevice(WinHidDeviceInfo device) async {
    setState(() {
      _busyDevicePath = device.path;
      _errorMessage = null;
    });

    try {
      final connectedDevice = await widget.hidBridge.connect(device.path);
      if (!mounted) {
        return;
      }

      setState(() {
        _connectedDevice = connectedDevice;
      });
      await _refreshDevices();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _busyDevicePath = null;
        });
      }
    }
  }

  Future<void> _disconnectDevice() async {
    final connectedPath = _connectedDevice?.path;
    setState(() {
      _busyDevicePath = connectedPath;
      _errorMessage = null;
    });

    try {
      await widget.hidBridge.disconnect();
      if (!mounted) {
        return;
      }

      setState(() {
        _connectedDevice = null;
      });
      await _refreshDevices();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _busyDevicePath = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectedDevice = _connectedDevice;
    final deviceCount = _devices.length;

    return _PanelGrid(
      children: [
        _InfoPanel(
          title: 'Connection',
          child: _DeviceConnectionPanel(
            connectedDevice: connectedDevice,
            deviceCount: deviceCount,
            isRefreshing: _isRefreshing,
            errorMessage: _errorMessage,
            onRefresh: _refreshDevices,
            onDisconnect: connectedDevice == null ? null : _disconnectDevice,
          ),
        ),
        const _InfoPanel(
          title: 'Transport',
          child: _StatusBlock(
            label: 'Protocol',
            value: 'WIN68HE HID',
            details: 'Report ID 1, 63-byte reports, vendor flow mapped from the web app.',
          ),
        ),
        _InfoPanel(
          title: 'Detected Devices',
          child: _DeviceListPanel(
            devices: _devices,
            connectedPath: connectedDevice?.path,
            busyPath: _busyDevicePath,
            isRefreshing: _isRefreshing,
            onConnect: _connectDevice,
          ),
        ),
        const _InfoPanel(
          title: 'Filter',
          child: _FilterPanel(),
        ),
      ],
    );
  }
}

class _KeysPage extends StatelessWidget {
  const _KeysPage();

  @override
  Widget build(BuildContext context) {
    return _PanelGrid(
      children: const [
        _InfoPanel(
          title: 'Layout',
          child: _SimpleList(
            items: [
              'WIN68HE sparse logical map loaded from vendor layout JSON',
              'Physical keys are drawn by logical index, not only by visible order',
              'Calibration highlights will map directly to device indices',
            ],
          ),
        ),
        _InfoPanel(
          title: 'Key Tools',
          child: _SimpleList(
            items: [
              'Remapping UI comes here',
              'Per-key calibration targeting can be added after HID validation',
              'Advanced key behavior stays separate from the actuation pages',
            ],
          ),
        ),
      ],
    );
  }
}

class _ActuationPage extends StatelessWidget {
  const _ActuationPage();

  @override
  Widget build(BuildContext context) {
    return _PanelGrid(
      children: const [
        _InfoPanel(
          title: 'Global Travel',
          child: _SliderBlock(
            label: 'Actuation point',
            valueLabel: '1.7 mm',
            value: 0.56,
          ),
        ),
        _InfoPanel(
          title: 'Deadband',
          child: _SliderBlock(
            label: 'Top deadband',
            valueLabel: '0.10 mm',
            value: 0.18,
          ),
        ),
      ],
    );
  }
}

class _RapidTriggerPage extends StatelessWidget {
  const _RapidTriggerPage();

  @override
  Widget build(BuildContext context) {
    return _PanelGrid(
      children: const [
        _InfoPanel(
          title: 'Rapid Trigger',
          child: _SimpleList(
            items: [
              'Per-key enable and release thresholds fit here',
              'Use neutral controls and compact tables',
              'Session live-preview should stay functional, not decorative',
            ],
          ),
        ),
      ],
    );
  }
}

class _LightingPage extends StatelessWidget {
  const _LightingPage();

  @override
  Widget build(BuildContext context) {
    return _PanelGrid(
      children: const [
        _InfoPanel(
          title: 'Lighting',
          child: _SliderBlock(
            label: 'Brightness',
            valueLabel: '72%',
            value: 0.72,
          ),
        ),
        _InfoPanel(
          title: 'Preview',
          child: _LightingPreview(),
        ),
      ],
    );
  }
}

class _ProfilesPage extends StatelessWidget {
  const _ProfilesPage();

  @override
  Widget build(BuildContext context) {
    return _PanelGrid(
      children: const [
        _InfoPanel(
          title: 'Profiles',
          child: _SimpleList(
            items: [
              'Profile slots should store keys, lighting and actuation state together',
              'Import and export can live behind compact dialogs',
              'The UI should stay closer to a settings utility than a gaming dashboard',
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return _PanelGrid(
      children: const [
        _InfoPanel(
          title: 'App Settings',
          child: _SimpleList(
            items: [
              'Theme and diagnostics live here',
              'HID logging should be opt-in',
              'Desktop-first spacing and layout stay the default',
            ],
          ),
        ),
      ],
    );
  }
}

class _PanelGrid extends StatelessWidget {
  const _PanelGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: children
            .map(
              (child) => SizedBox(
                width: 420,
                child: child,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatusBlock extends StatelessWidget {
  const _StatusBlock({
    required this.label,
    required this.value,
    required this.details,
  });

  final String label;
  final String value;
  final String details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(details, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _DeviceConnectionPanel extends StatelessWidget {
  const _DeviceConnectionPanel({
    required this.connectedDevice,
    required this.deviceCount,
    required this.isRefreshing,
    required this.errorMessage,
    required this.onRefresh,
    required this.onDisconnect,
  });

  final WinHidDeviceInfo? connectedDevice;
  final int deviceCount;
  final bool isRefreshing;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final Future<void> Function()? onDisconnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isConnected = connectedDevice != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusBlock(
          label: 'Keyboard',
          value: isConnected ? 'Connected' : 'Disconnected',
          details: isConnected
              ? 'Open HID session established through the Windows bridge.'
              : 'HID bridge is ready. Scan devices and open the keyboard session.',
        ),
        const SizedBox(height: 16),
        _PropertyRow(label: 'Matched devices', value: '$deviceCount'),
        _PropertyRow(
          label: 'Current device',
          value: connectedDevice?.productName.isNotEmpty == true
              ? connectedDevice!.productName
              : isConnected
                  ? 'Generic HID device'
                  : 'None',
        ),
        _PropertyRow(
          label: 'VID:PID',
          value: isConnected
              ? _formatVidPid(connectedDevice!)
              : '2E3C:----',
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onErrorContainer,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            FilledButton.icon(
              onPressed: isRefreshing ? null : onRefresh,
              icon: isRefreshing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(isRefreshing ? 'Scanning...' : 'Scan devices'),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: onDisconnect,
              icon: const Icon(Icons.link_off_rounded),
              label: const Text('Disconnect'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DeviceListPanel extends StatelessWidget {
  const _DeviceListPanel({
    required this.devices,
    required this.connectedPath,
    required this.busyPath,
    required this.isRefreshing,
    required this.onConnect,
  });

  final List<WinHidDeviceInfo> devices;
  final String? connectedPath;
  final String? busyPath;
  final bool isRefreshing;
  final ValueChanged<WinHidDeviceInfo> onConnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (devices.isEmpty) {
      return Text(
        isRefreshing
            ? 'Scanning for matching HID devices...'
            : 'No matching WIN68HE-class HID device was found yet.',
        style: theme.textTheme.bodySmall,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final device in devices) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: device.path == connectedPath
                    ? scheme.primary
                    : scheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        device.productName.isNotEmpty
                            ? device.productName
                            : 'Generic HID device',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (device.path == connectedPath)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Connected',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                _PropertyRow(
                  label: 'Manufacturer',
                  value: device.manufacturerName.isNotEmpty
                      ? device.manufacturerName
                      : 'Unknown',
                ),
                _PropertyRow(label: 'VID:PID', value: _formatVidPid(device)),
                _PropertyRow(
                  label: 'Usage',
                  value:
                      '${_formatHex(device.usagePage, width: 4)}:${_formatHex(device.usage, width: 2)}',
                ),
                _PropertyRow(
                  label: 'Reports',
                  value:
                      'IN ${device.inputReportByteLength} / OUT ${device.outputReportByteLength} / FEATURE ${device.featureReportByteLength}',
                ),
                _PropertyRow(label: 'Path', value: device.path),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: busyPath != null || device.path == connectedPath
                        ? null
                        : () => onConnect(device),
                    child: Text(
                      busyPath == device.path ? 'Connecting...' : 'Connect',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PropertyRow(label: 'Vendor filter', value: '0x2E3C'),
        _PropertyRow(label: 'Usage page', value: '0xFF1B'),
        _PropertyRow(label: 'Usage', value: '0x91'),
        SizedBox(height: 8),
        Text(
          'This keeps the first integration narrow: enumerate only the vendor HID interface used by the web app before we branch into broader device matching.',
        ),
      ],
    );
  }
}

class _PropertyRow extends StatelessWidget {
  const _PropertyRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

String _formatVidPid(WinHidDeviceInfo device) {
  return '${_formatHex(device.vendorId, width: 4)}:${_formatHex(device.productId, width: 4)}';
}

String _formatHex(int value, {required int width}) {
  return '0x${value.toRadixString(16).toUpperCase().padLeft(width, '0')}';
}

class _SimpleList extends StatelessWidget {
  const _SimpleList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Icon(
                  Icons.circle,
                  size: 7,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(item, style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SliderBlock extends StatelessWidget {
  const _SliderBlock({
    required this.label,
    required this.valueLabel,
    required this.value,
  });

  final String label;
  final String valueLabel;
  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            Text(valueLabel, style: theme.textTheme.bodySmall),
          ],
        ),
        Slider(
          value: value,
          onChanged: (_) {},
        ),
      ],
    );
  }
}

class _LightingPreview extends StatelessWidget {
  const _LightingPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const colors = [
      Color(0xFF60A5FA),
      Color(0xFF818CF8),
      Color(0xFF34D399),
      Color(0xFFF59E0B),
      Color(0xFFFB7185),
      Color(0xFFA78BFA),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RGB stays inside the preview only.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              24,
              (index) => Container(
                width: 34,
                height: 26,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors[index % colors.length],
                      colors[(index + 1) % colors.length],
                    ],
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _sectionDescription(AppSection section) {
  return switch (section) {
    AppSection.device => 'Connect the keyboard, inspect HID transport and manage sessions.',
    AppSection.keys => 'Work with layout, remaps and calibration-aware key tools.',
    AppSection.actuation => 'Tune travel, thresholds and precision values.',
    AppSection.rapidTrigger => 'Configure dynamic trigger behavior with compact controls.',
    AppSection.lighting => 'Preview lighting modes without turning the whole app into RGB.',
    AppSection.profiles => 'Save, load and organize keyboard profiles.',
    AppSection.settings => 'Theme, diagnostics and app-level preferences.',
  };
}
