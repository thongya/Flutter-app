// lib/widgets/sleep_timer_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../constants/app_constants.dart';

class SleepTimerDialog extends StatefulWidget {
  const SleepTimerDialog({Key? key}) : super(key: key);

  @override
  State<SleepTimerDialog> createState() => _SleepTimerDialogState();
}

class _SleepTimerDialogState extends State<SleepTimerDialog> {
  int _selectedMinutes = 0;
  int _selectedHours = 0;
  int _selectedSeconds = 0;
  bool _isTimerActive = false;
  int _remainingTimeInSeconds = 0;

  @override
  void initState() {
    super.initState();
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    _isTimerActive = audioProvider.isSleepTimerActive;
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    return AlertDialog(
      title: const Text('Sleep Timer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Time display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeColumn('Hours', _selectedHours, 23, (value) {
                setState(() {
                  _selectedHours = value;
                });
              }),
              _buildTimeColumn('Minutes', _selectedMinutes, 59, (value) {
                setState(() {
                  _selectedMinutes = value;
                });
              }),
              _buildTimeColumn('Seconds', _selectedSeconds, 59, (value) {
                setState(() {
                  _selectedSeconds = value;
                });
              }),
            ],
          ),

          const SizedBox(height: 24),

          // Preset buttons
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildPresetButton('5 min', 5),
              _buildPresetButton('10 min', 10),
              _buildPresetButton('15 min', 15),
              _buildPresetButton('30 min', 30),
              _buildPresetButton('45 min', 45),
              _buildPresetButton('1 hour', 60),
            ],
          ),

          const SizedBox(height: 16),

          // Timer status
          if (_isTimerActive)
            Text(
              'Timer will stop in ${_formatDuration(Duration(seconds: _remainingTimeInSeconds))}',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('CANCEL'),
        ),

        // Reset button
        TextButton(
          onPressed: () {
            setState(() {
              _selectedHours = 0;
              _selectedMinutes = 0;
              _selectedSeconds = 0;
            });
          },
          child: const Text('RESET'),
        ),

        // Start/Stop button
        ElevatedButton(
          onPressed: () {
            final totalSeconds = _selectedHours * 3600 + _selectedMinutes * 60 + _selectedSeconds;

            if (totalSeconds > 0) {
              audioProvider.setSleepTimer(totalSeconds ~/ 60); // Convert to minutes
              Navigator.pop(context);
            } else if (_isTimerActive) {
              audioProvider.cancelSleepTimer();
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: Text(_isTimerActive ? 'STOP TIMER' : 'START'),
        ),
      ],
    );
  }

  Widget _buildTimeColumn(String label, int value, int maxValue, Function(int) onChanged) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Increment button
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (value < maxValue) {
                      onChanged(value + 1);
                    }
                  },
                  child: const Icon(Icons.keyboard_arrow_up),
                ),
              ),

              // Value display
              Text(
                value.toString().padLeft(2, '0'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              // Decrement button
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (value > 0) {
                      onChanged(value - 1);
                    }
                  },
                  child: const Icon(Icons.keyboard_arrow_down),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetButton(String label, int minutes) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedHours = minutes ~/ 60;
          _selectedMinutes = minutes % 60;
          _selectedSeconds = 0;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      child: Text(label),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }
}