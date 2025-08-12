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
  bool _snapBands = true;
  double _bassBoost = 0.0;
  double _trebleBoost = 0.0;

  // Frequency bands as shown in the image
  final List<String> _frequencies = [
    '31Hz',
    '63Hz',
    '125Hz',
    '250Hz',
    '500Hz',
    '1kHz',
    '2kHz',
    '4kHz',
    '8kHz',
    '16kHz',
  ];

  @override
  void initState() {
    super.initState();
    final audioProvider = context.read<AudioProvider>();
    _customSettings = List.from(audioProvider.equalizerSettings);
    _bassBoost = audioProvider.bassBoost;
    _trebleBoost = audioProvider.trebleBoost;
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
            // Check if equalizer is available
            Consumer<AudioProvider>(
              builder: (context, audioProvider, child) {
                if (!audioProvider.equalizerEnabled) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange[800]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Audio enhancement is not available on this device.',
                            style: TextStyle(color: Colors.orange[800]),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink(); // Don't show anything if equalizer is available
              },
            ),
            const SizedBox(height: 16),
            _buildPresetSelector(),
            const SizedBox(height: 32),
            _buildCustomEqualizer(),
            const SizedBox(height: 32),
            _buildBassTrebleControls(),
            const Spacer(),
            _buildControls(),
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
        Container(
          height: 250,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              // Frequency labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _frequencies.map((freq) {
                  return Text(
                    freq,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),
              // Sliders
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(10, (index) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // dB value display
                        Text(
                          '${_customSettings[index].toInt()}dB',
                          style: TextStyle(
                            fontSize: 10,
                            color: _customSettings[index] == 0
                                ? Colors.grey
                                : Theme.of(context).primaryColor,
                          ),
                        ),
                        // Slider
                        SizedBox(
                          height: 150,
                          width: 30,
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 12,
                                ),
                                thumbColor: Theme.of(context).primaryColor,
                                activeTrackColor: Theme.of(
                                  context,
                                ).primaryColor,
                                inactiveTrackColor: Colors.grey.withOpacity(
                                  0.3,
                                ),
                              ),
                              child: Slider(
                                value: _customSettings[index],
                                min: -20.0,
                                max: 20.0,
                                onChanged: (value) {
                                  setState(() {
                                    _customSettings[index] = _snapBands
                                        ? value.roundToDouble()
                                        : value;
                                    _selectedPreset = '';
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBassTrebleControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bass & Treble',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // Bass control
        Row(
          children: [
            const Icon(Icons.graphic_eq, size: 24),
            const SizedBox(width: 10),
            const Text('Bass'),
            const SizedBox(width: 10),
            Expanded(
              child: Slider(
                value: _bassBoost,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: '${(_bassBoost * 100).round()}%',
                onChanged: (value) {
                  setState(() {
                    _bassBoost = value;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Treble control
        Row(
          children: [
            const Icon(Icons.graphic_eq, size: 24),
            const SizedBox(width: 10),
            const Text('Treble'),
            const SizedBox(width: 10),
            Expanded(
              child: Slider(
                value: _trebleBoost,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: '${(_trebleBoost * 100).round()}%',
                onChanged: (value) {
                  setState(() {
                    _trebleBoost = value;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: _resetSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black,
              minimumSize: const Size(100, 40),
            ),
            child: const Text('RESET'),
          ),
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 40),
            ),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _applyPreset(String preset) {
    // Apply preset values based on selection
    switch (preset) {
      case 'Classical':
        _customSettings = [
          4.0,
          4.0,
          2.0,
          0.0,
          0.0,
          0.0,
          -2.0,
          -4.0,
          -4.0,
          -4.0,
        ];
        _bassBoost = 0.3;
        _trebleBoost = 0.2;
        break;
      case 'Dance':
        _customSettings = [6.0, 4.0, 0.0, 0.0, 0.0, -4.0, -6.0, -2.0, 2.0, 4.0];
        _bassBoost = 0.8;
        _trebleBoost = 0.6;
        break;
      case 'Flat':
        _customSettings = List.filled(10, 0.0);
        _bassBoost = 0.0;
        _trebleBoost = 0.0;
        break;
      case 'Folk':
        _customSettings = [3.0, 2.0, 0.0, 0.0, 0.0, 0.0, 0.0, -2.0, -2.0, -3.0];
        _bassBoost = 0.2;
        _trebleBoost = 0.1;
        break;
      case 'Heavy Metal':
        _customSettings = [
          5.0,
          4.0,
          4.0,
          2.0,
          0.0,
          -2.0,
          -4.0,
          -6.0,
          -6.0,
          -6.0,
        ];
        _bassBoost = 0.9;
        _trebleBoost = 0.7;
        break;
      case 'Hip Hop':
        _customSettings = [
          5.0,
          4.0,
          0.0,
          -2.0,
          -4.0,
          -4.0,
          -2.0,
          0.0,
          2.0,
          4.0,
        ];
        _bassBoost = 0.7;
        _trebleBoost = 0.5;
        break;
      case 'Jazz':
        _customSettings = [4.0, 2.0, 0.0, -2.0, -4.0, -2.0, 0.0, 2.0, 4.0, 4.0];
        _bassBoost = 0.4;
        _trebleBoost = 0.6;
        break;
      case 'Pop':
        _customSettings = [
          -1.0,
          -1.0,
          0.0,
          2.0,
          4.0,
          4.0,
          2.0,
          0.0,
          -1.0,
          -1.0,
        ];
        _bassBoost = 0.3;
        _trebleBoost = 0.4;
        break;
      case 'Rock':
        _customSettings = [4.0, 2.0, 0.0, -2.0, -4.0, -2.0, 0.0, 2.0, 4.0, 4.0];
        _bassBoost = 0.6;
        _trebleBoost = 0.5;
        break;
      default: // Normal
        _customSettings = List.filled(10, 0.0);
        _bassBoost = 0.0;
        _trebleBoost = 0.0;
    }
    setState(() {});
  }

  void _resetSettings() {
    setState(() {
      _customSettings = List.filled(10, 0.0);
      _bassBoost = 0.0;
      _trebleBoost = 0.0;
      _selectedPreset = 'Normal';
    });
  }

  void _saveSettings() {
    final audioProvider = context.read<AudioProvider>();
    audioProvider.setEqualizerSettings(_customSettings);
    audioProvider.setBassBoost(_bassBoost);
    audioProvider.setTrebleBoost(_trebleBoost);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Equalizer settings applied')));
  }
}