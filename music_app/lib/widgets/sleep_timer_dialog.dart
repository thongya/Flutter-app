// lib/widgets/sleep_timer_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../constants/app_constants.dart';

class SleepTimerDialog extends StatelessWidget {
  const SleepTimerDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();

    return AlertDialog(
      title: const Text('Sleep Timer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...AppConstants.sleepTimerPresets.map((minutes) => ListTile(
            title: Text('$minutes minutes'),
            onTap: () {
              audioProvider.setSleepTimer(minutes);
              Navigator.pop(context);
            },
          )),
          const Divider(),
          ListTile(
            title: const Text('Custom Time'),
            onTap: () => _showCustomTimeDialog(context),
          ),
          if (audioProvider.isSleepTimerActive)
            ListTile(
              title: const Text('Cancel Timer'),
              onTap: () {
                audioProvider.cancelSleepTimer();
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  void _showCustomTimeDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Time'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Minutes',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text) ?? 0;
              if (minutes > 0) {
                context.read<AudioProvider>().setSleepTimer(minutes);
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }
}