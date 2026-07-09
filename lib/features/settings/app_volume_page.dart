import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:aiaprtd_member/core/providers/settings_provider.dart';

class AppVolumePage extends StatefulWidget {
  const AppVolumePage({super.key});

  @override
  State<AppVolumePage> createState() => _AppVolumePageState();
}

class _AppVolumePageState extends State<AppVolumePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  bool _isLoadingBattery = true;

  @override
  void initState() {
    super.initState();
    _checkBattery();
  }

  Future<void> _checkBattery() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) {
        setState(() {
          _batteryLevel = level;
          _isLoadingBattery = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingBattery = false);
    }
  }

  void _testAudio(double volume) {
    _audioPlayer.setVolume(volume);
    _audioPlayer.play(AssetSource('sounds/intro.mp3')); // Using intro.mp3 as a test sound
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final settings = Provider.of<SettingsProvider>(context);

    if (!settings.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Audio & Alerts", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Volume Control Header
            _buildSection(
              context,
              "Master App Volume",
              [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    children: [
                      Icon(
                        settings.appVolume == 0 ? Icons.volume_off : Icons.volume_up,
                        size: 40,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "${(settings.appVolume * 100).toInt()}%",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                      Slider(
                        value: settings.appVolume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        onChanged: (val) {
                          settings.setAppVolume(val);
                        },
                        onChangeEnd: (val) {
                          _testAudio(val);
                        },
                        activeColor: Colors.blue,
                      ),
                      const Text(
                        "Controls the volume of new booking alerts and internal app sounds.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Battery Status & Settings
            _buildSection(
              context,
              "Device & Battery",
              [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(_batteryLevel > 20 ? Icons.battery_full : Icons.battery_alert, color: _batteryLevel > 20 ? Colors.green : Colors.red, size: 22),
                  ),
                  title: Text("Current Battery Level", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : Colors.black87)),
                  trailing: _isLoadingBattery 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : Text("$_batteryLevel%", style: TextStyle(fontSize: 14, color: _batteryLevel > 20 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: settings.enableBatteryWarning,
                  onChanged: (val) {
                    settings.setBatteryWarning(val);
                    if (val && _batteryLevel <= 20) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Warning: Battery is currently low!"), backgroundColor: Colors.red));
                    }
                  },
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
                  ),
                  title: Text("Low Battery Warning", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : Colors.black87)),
                  subtitle: const Text("Get an alert when battery drops below 20%", style: TextStyle(fontSize: 11)),
                  activeColor: Colors.blue,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Passenger Tools
            _buildSection(
              context,
              "Passenger Safety & Tools",
              [
                SwitchListTile(
                  value: settings.enableSeatbeltAudio,
                  onChanged: (val) {
                    settings.setSeatbeltAudio(val);
                  },
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.spatial_audio_off_rounded, color: Colors.teal, size: 22),
                  ),
                  title: Text("Seatbelt Audio Message", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : Colors.black87)),
                  subtitle: const Text("Play a safety reminder audio when you start a trip.", style: TextStyle(fontSize: 11)),
                  activeColor: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 8),
          child: Text(title.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDarkMode ? Colors.grey[400] : Colors.blueGrey, letterSpacing: 1.2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: isDarkMode ? Colors.black38 : Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}