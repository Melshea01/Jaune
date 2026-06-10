import 'package:flutter/material.dart';
import '../controllers/citron_animation_controller.dart';
import '../models/animation_layer_state.dart';

/// A simple debug panel to visually test animations.
/// - Choose a special preset
/// - Trigger one-shot events
/// - Set an individual layer state
class CitronDebugPanel extends StatefulWidget {
  final CitronAnimationController controller;

  const CitronDebugPanel({super.key, required this.controller});

  @override
  State<CitronDebugPanel> createState() => _CitronDebugPanelState();
}

class _CitronDebugPanelState extends State<CitronDebugPanel> {
  // Available special animations (must match SpecialAnimationMap.getAnimation)
  final List<String> _specials = [
    'tipsy',
    'drunk',
    'wasted',
    'hungover',
    'recovery',
    'dehydrated',
    'zen',
    'asleep',
    'pulse',
    'loading',
    'bored',
    'digest',
    'secretDance',
    'greeting',
    'walking',
    'sprinting',
    'panic',
    'workout',
    'freezing',
    'overheating',
    'levitation',
  ];

  // Available events (must match AnimationEvents.getEvent)
  final List<String> _events = [
    'jump_joy',
    'double_jump',
    'mega_jump',
    'badge_proud',
    'shiver',
    'scared',
    'craquage',
    'hiccup',
    'encourage',
    'curious',
    'willpower',
    'craving',
    'coin_spin',
    'drink_beer',
  ];

  String? _selectedSpecial;
  String? _selectedLayer;
  String? _selectedLayerState;
  double _localSpeed = 0.35;

  @override
  void initState() {
    super.initState();
    _selectedSpecial = _specials.first;
    _selectedLayer = layerStates.keys.first;
    _selectedLayerState = layerStates[_selectedLayer]!.keys.first;
    _localSpeed = widget.controller.speedFactor;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Special Presets',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedSpecial,
                  isExpanded: true,
                  items:
                      _specials
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _selectedSpecial = v),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_selectedSpecial != null) {
                    widget.controller.playSpecialAnimation(_selectedSpecial!);
                  }
                },
                child: const Text('Apply'),
              ),
            ],
          ),

          const Divider(height: 24),

          const Text(
            'One-shot Events',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _events
                    .map(
                      (e) => ElevatedButton(
                        onPressed: () {
                          final ev = widget.controller.triggerEvent(e);
                          if (ev != null) {
                            // For now, just notify — the CitronCharacter reads AnimationEvents itself
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Event triggered: $e')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Unknown event: $e')),
                            );
                          }
                        },
                        child: Text(e),
                      ),
                    )
                    .toList(),
          ),

          const Divider(height: 24),

          const Text(
            'Layer Manual Control',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedLayer,
                  isExpanded: true,
                  items:
                      layerStates.keys
                          .map(
                            (k) => DropdownMenuItem(value: k, child: Text(k)),
                          )
                          .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedLayer = v;
                      _selectedLayerState = layerStates[v]!.keys.first;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_selectedLayer != null)
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedLayerState,
                    isExpanded: true,
                    items:
                        layerStates[_selectedLayer]!.keys
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _selectedLayerState = v),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedLayer != null && _selectedLayerState != null) {
                      widget.controller.setAnimation({
                        _selectedLayer!: _selectedLayerState!,
                      });
                    }
                  },
                  child: const Text('Set'),
                ),
              ],
            ),

          const SizedBox(height: 16),
          const Text(
            'Global Speed',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _localSpeed,
                  min: 0.05,
                  max: 1.5,
                  divisions: 29,
                  label: _localSpeed.toStringAsFixed(2),
                  onChanged: (v) {
                    setState(() {
                      _localSpeed = v;
                      widget.controller.setSpeedFactor(v);
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: Text(
                  _localSpeed.toStringAsFixed(2),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _localSpeed = 0.2;
                    widget.controller.setSpeedFactor(_localSpeed);
                  });
                },
                child: const Text('Slow'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _localSpeed = 0.6;
                    widget.controller.setSpeedFactor(_localSpeed);
                  });
                },
                child: const Text('Normal'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _localSpeed = 1.0;
                    widget.controller.setSpeedFactor(_localSpeed);
                  });
                },
                child: const Text('Fast'),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Reset all layers to defaults
              widget.controller.setAnimation({
                'global': 'idle',
                'milieu': 'idle',
                'jambes': 'idle',
                'bras_D': 'idle',
                'bras_G': 'idle',
                'plante': 'idle',
                'yeux': 'open',
                'bouche': 'smile',
                'joues': 'visible',
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset to defaults'),
          ),
        ],
      ),
    );
  }
}
