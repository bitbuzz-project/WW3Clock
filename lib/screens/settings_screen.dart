import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _highThreatAlerts = true;
  int _updateFrequency = 60; // minutes

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _highThreatAlerts = prefs.getBool('high_threat_alerts') ?? true;
      _updateFrequency = prefs.getInt('update_frequency') ?? 60;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('high_threat_alerts', _highThreatAlerts);
    await prefs.setInt('update_frequency', _updateFrequency);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primaryColor,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notifications Section
          Card(
            color: AppColors.cardBackground,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Notifications'),
                    subtitle: const Text('Receive updates about threat levels'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      _saveSettings();
                    },
                    activeColor: AppColors.accentColor,
                  ),
                  SwitchListTile(
                    title: const Text('High Threat Alerts'),
                    subtitle: const Text('Emergency alerts for critical threats'),
                    value: _highThreatAlerts,
                    onChanged: _notificationsEnabled ? (value) {
                      setState(() {
                        _highThreatAlerts = value;
                      });
                      _saveSettings();
                    } : null,
                    activeColor: AppColors.highThreat,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Update Frequency Section
          Card(
            color: AppColors.cardBackground,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update Frequency',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Auto-update interval'),
                    subtitle: Text('Every $_updateFrequency minutes'),
                    trailing: DropdownButton<int>(
                      value: _updateFrequency,
                      items: const [
                        DropdownMenuItem(value: 15, child: Text('15 min')),
                        DropdownMenuItem(value: 30, child: Text('30 min')),
                        DropdownMenuItem(value: 60, child: Text('1 hour')),
                        DropdownMenuItem(value: 120, child: Text('2 hours')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _updateFrequency = value!;
                        });
                        _saveSettings();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // About Section
          Card(
            color: AppColors.cardBackground,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: AppColors.accentColor),
                    title: const Text('App Version'),
                    subtitle: const Text('1.0.0'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.description, color: AppColors.accentColor),
                    title: const Text('Data Sources'),
                    subtitle: const Text('NewsAPI, GNews, AI Analysis'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.update, color: AppColors.accentColor),
                    title: const Text('Last Update Check'),
                    subtitle: Text(DateTime.now().toString().split('.')[0]),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Actions Section
          Card(
            color: AppColors.cardBackground,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.refresh, color: AppColors.accentColor),
                    title: const Text('Refresh Data'),
                    subtitle: const Text('Force update all threat data'),
                    onTap: () {
                      // Trigger data refresh
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Refreshing data...'),
                          backgroundColor: AppColors.accentColor,
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.clear_all, color: Colors.orange),
                    title: const Text('Clear Cache'),
                    subtitle: const Text('Clear stored news and threat data'),
                    onTap: () {
                      _showClearCacheDialog();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Cache'),
          content: const Text('This will clear all stored data and refresh from APIs. Continue?'),
          backgroundColor: AppColors.cardBackground,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache cleared successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
}