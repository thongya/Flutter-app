// lib/screens/equalizer_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../constants/app_constants.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  String _selectedPreset = 'Normal';
  List<double> _customSettings = List.filled(10, 0.0);

  @override
  void initState() {
    super.initState();
    final audioProvider = context.read<AudioProvider>();
    _customSettings = List.from(audioProvider.equalizerSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equalizer'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPresetSelector(),
            const SizedBox(height: 32),
            _buildCustomEqualizer(),
            const Spacer(),
            _buildApplyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Presets',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.equalizerPresets.map((preset) {
            return FilterChip(
              label: Text(preset),
              selected: _selectedPreset == preset,
              onSelected: (selected) {
                setState(() {
                  _selectedPreset = selected ? preset : 'Normal';
                  _applyPreset(preset);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomEqualizer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Custom Equalizer',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(10, (index) {
            return Column(
              children: [
                RotatedBox(
                  quarterTurns: 3,
                  child: SizedBox(
                    height: 150,
                    child: Slider(
                      value: _customSettings[index],
                      min: -15.0,
                      max: 15.0,
                      onChanged: (value) {
                        setState(() {
                          _customSettings[index] = value;
                          _selectedPreset = '';
                        });
                      },
                    ),
                  ),
                ),
                Text('${index * 2}K'),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          context.read<AudioProvider>().setEqualizerSettings(_customSettings);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Equalizer settings applied')),
          );
        },
        child: const Text('Apply Settings'),
      ),
    );
  }

  void _applyPreset(String preset) {
    // Apply preset values based on selection
    switch (preset) {
      case 'Classical':
        _customSettings = [4.0, 4.0, 2.0, 0.0, 0.0, 0.0, -2.0, -4.0, -4.0, -4.0];
        break;
      case 'Dance':
        _customSettings = [6.0, 4.0, 0.0, 0.0, 0.0, -4.0, -6.0, -2.0, 2.0, 4.0];
        break;
      case 'Flat':
        _customSettings = List.filled(10, 0.0);
        break;
      case 'Folk':
        _customSettings = [3.0, 2.0, 0.0, 0.0, 0.0, 0.0, 0.0, -2.0, -2.0, -3.0];
        break;
      case 'Heavy Metal':
        _customSettings = [5.0, 4.0, 4.0, 2.0, 0.0, -2.0, -4.0, -6.0, -6.0, -6.0];
        break;
      case 'Hip Hop':
        _customSettings = [5.0, 4.0, 0.0, -2.0, -4.0, -4.0, -2.0, 0.0, 2.0, 4.0];
        break;
      case 'Jazz':
        _customSettings = [4.0, 2.0, 0.0, -2.0, -4.0, -2.0, 0.0, 2.0, 4.0, 4.0];
        break;
      case 'Pop':
        _customSettings = [-1.0, -1.0, 0.0, 2.0, 4.0, 4.0, 2.0, 0.0, -1.0, -1.0];
        break;
      case 'Rock':
        _customSettings = [4.0, 2.0, 0.0, -2.0, -4.0, -2.0, 0.0, 2.0, 4.0, 4.0];
        break;
      default: // Normal
        _customSettings = List.filled(10, 0.0);
    }
    setState(() {});
  }
}