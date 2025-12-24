import 'package:flutter/material.dart';
import 'dart:math';
import 'logic/algorithms.dart';
import 'widgets/manual_shape_editor.dart';
import 'widgets/results_view.dart';

class AdvisorHomePage extends StatefulWidget {
  const AdvisorHomePage({super.key});

  @override
  State<AdvisorHomePage> createState() => _AdvisorHomePageState();
}

class _AdvisorHomePageState extends State<AdvisorHomePage> {
  int _currentStep = 0;
  bool _isLoading = false;
  Map<String, dynamic>? _optimizationResult;

  // Step 1: Field Details
  String _cropType = 'Corn';
  String _soilType = 'Loamy';
  String _fieldShape = 'Rectangle';

  final _fieldLengthController = TextEditingController(text: "100");
  final _fieldWidthController = TextEditingController(text: "100");
  final _fieldRadiusController = TextEditingController(text: "56.4");

  // User Sensor Control
  double _userSensorCount = 3.0;
  double _recommendedSensorCount = 3.0;
  double _sliderMax = 20.0;

  final List<Offset> _manualVertices = [
    const Offset(0, 0),
    const Offset(100, 0),
    const Offset(100, 100),
    const Offset(0, 100),
  ];

  double _calculatedAreaHectares = 1.0;

  // Step 2: Input Ranges
  final Map<String, List<double>> _bounds = {
    'Nitrogen': [50, 200],
    'Phosphorus': [20, 100],
    'Potassium': [20, 100],
    'Water': [300, 800],
    'Seed Density': [60000, 90000],
  };
  final Map<String, String> _units = {
    'Nitrogen': 'kg/ha',
    'Phosphorus': 'kg/ha',
    'Potassium': 'kg/ha',
    'Water': 'mm/season',
    'Seed Density': 'seeds/ha',
  };

  @override
  void initState() {
    super.initState();
    _fieldLengthController.addListener(_updateArea);
    _fieldWidthController.addListener(_updateArea);
    _fieldRadiusController.addListener(_updateArea);
    _updateArea();
  }

  Map<String, double> _getFieldDimensions() {
    if (_fieldShape == 'Rectangle') {
      return {
        'length': double.tryParse(_fieldLengthController.text) ?? 100,
        'width': double.tryParse(_fieldWidthController.text) ?? 100
      };
    }
    if (_fieldShape == 'Circle') return {'radius': double.tryParse(_fieldRadiusController.text) ?? 50};
    return {};
  }

  void _updateArea() {
    double areaM2 = 0;
    if (_fieldShape == 'Rectangle') {
      areaM2 = (double.tryParse(_fieldLengthController.text) ?? 0) *
          (double.tryParse(_fieldWidthController.text) ?? 0);
    } else if (_fieldShape == 'Circle') {
      areaM2 = pi * pow(double.tryParse(_fieldRadiusController.text) ?? 0, 2);
    } else if (_fieldShape == 'Manual Polygon') {
      areaM2 = OptimizerAlgorithms.calculatePolygonArea(_manualVertices);
    }

    setState(() {
      _calculatedAreaHectares = areaM2 / 10000;
      double rec = max(3.0, (_calculatedAreaHectares * 2).ceilToDouble());
      _recommendedSensorCount = rec;
      _sliderMax = max(20.0, _recommendedSensorCount + 5);

      if (_userSensorCount > _sliderMax) {
        _userSensorCount = _sliderMax;
      }
    });
  }

  void _runOptimization() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    // Call static algorithms
    final nutrientResult = OptimizerAlgorithms.runNutrientAlgo(_bounds, _cropType, _soilType);
    final sensorPlacement = OptimizerAlgorithms.runSensorOptimization(
      _userSensorCount.round(), 
      _fieldShape, 
      _getFieldDimensions(), 
      _manualVertices
    );

    final rates = {
      'Nitrogen': nutrientResult.position[0],
      'Phosphorus': nutrientResult.position[1],
      'Potassium': nutrientResult.position[2],
      'Water': nutrientResult.position[3],
      'Seed Density': nutrientResult.position[4],
    };

    setState(() {
      _optimizationResult = {
        'rates': rates,
        'totals': {
          'Nitrogen (kg)': rates['Nitrogen']! * _calculatedAreaHectares,
          'Phosphorus (kg)': rates['Phosphorus']! * _calculatedAreaHectares,
          'Potassium (kg)': rates['Potassium']! * _calculatedAreaHectares,
          'Water (liters)': rates['Water']! * _calculatedAreaHectares * 10000,
          'Seeds (units)': rates['Seed Density']! * _calculatedAreaHectares,
        },
        'yield': nutrientResult.fitness,
        'sensor_details': sensorPlacement,
        'application_schedule': OptimizerAlgorithms.generateApplicationSchedule(_cropType, rates, _calculatedAreaHectares),
        'optimization_advice': OptimizerAlgorithms.generateOptimizationAdvice(_bounds, rates),
      };
      _isLoading = false;
      _currentStep = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const Text('AgriSense'),
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        flexibleSpace: ClipRect(
          child: Container(
            // Blur effect could go here
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.transparent,
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: Theme.of(context).colorScheme.primary,
                  )
                ),
                child: Stepper(
                  type: StepperType.horizontal,
                  elevation: 0,
                  currentStep: _currentStep,
                  onStepContinue: () {
                    if (_currentStep == 0) {
                      setState(() => _currentStep = 1);
                    } else if (_currentStep == 1) {
                      _runOptimization();
                    }
                  },
                  onStepCancel:
                  _currentStep > 0 ? () => setState(() => _currentStep -= 1) : null,
                  controlsBuilder: (context, details) {
                    if (_currentStep == 2) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 32.0, bottom: 24.0),
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.secondary,
                            ))
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_currentStep > 0)
                            TextButton(
                                onPressed: details.onStepCancel,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  foregroundColor: Colors.grey.shade700
                                ),
                                child: const Text('Back')),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                              icon: Icon(_currentStep == 1
                                  ? Icons.science_outlined
                                  : Icons.arrow_forward_rounded),
                              onPressed: details.onStepContinue,
                              label: Text(
                                  _currentStep == 0 ? 'Next Step' : 'Generate Plan')),
                        ],
                      ),
                    );
                  },
                  steps: [
                    _buildStep(
                        title: 'Field Data',
                        content: _buildFieldDetailsStep(),
                        isActive: _currentStep >= 0),
                    _buildStep(
                        title: 'Parameters',
                        content: _buildRangesStep(),
                        isActive: _currentStep >= 1),
                    _buildStep(
                        title: 'Strategy',
                        content: _optimizationResult == null 
                          ? const SizedBox.shrink() 
                          : ResultsView(
                              optimizationResult: _optimizationResult!,
                              calculatedAreaHectares: _calculatedAreaHectares,
                              userSensorCount: _userSensorCount.round(),
                              fieldShape: _fieldShape,
                              manualVertices: _manualVertices,
                              onReset: () => setState(() {
                                _currentStep = 0;
                                _optimizationResult = null;
                              }),
                            ),
                        isActive: _currentStep >= 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Step _buildStep(
      {required String title, required Widget content, bool isActive = false}) {
    return Step(
        title: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        content: content,
        state: _currentStep > ['Field Data', 'Parameters', 'Strategy'].indexOf(title)
            ? StepState.complete
            : StepState.indexed,
        isActive: isActive);
  }

  Widget _buildFieldDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildDropdown('Crop', Icons.eco_outlined, _cropType,
                      ['Corn', 'Wheat', 'Soybeans'], (val) => setState(() => _cropType = val!))),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildDropdown('Soil', Icons.landscape_outlined, _soilType,
                      ['Loamy', 'Sandy', 'Clay'], (val) => setState(() => _soilType = val!))),
            ],
          ),
          const SizedBox(height: 16),
          _buildDropdown('Field Geometry', Icons.format_shapes, _fieldShape,
              ['Rectangle', 'Circle', 'Manual Polygon'], (val) {
                setState(() {
                  _fieldShape = val!;
                  _updateArea();
                });
              }),
          const SizedBox(height: 16),
          
          // Geometry Input Section
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                if (_fieldShape == 'Rectangle')
                  Row(children: [
                    Expanded(child: _buildTextField('Length (m)', Icons.straighten, _fieldLengthController)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Width (m)', Icons.swap_horiz, _fieldWidthController)),
                  ]),
                if (_fieldShape == 'Circle')
                  _buildTextField('Radius (m)', Icons.circle_outlined, _fieldRadiusController),
                if (_fieldShape == 'Manual Polygon') 
                  ManualShapeEditor(
                    vertices: _manualVertices, 
                    onChanged: _updateArea // Callback to update area when points change
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Stats Card
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ]
            ),
            child: Column(
              children: [
                ListTile(
                    leading: const Icon(Icons.area_chart_outlined, color: Colors.white, size: 32),
                    title: const Text("Calculated Field Area",
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    trailing: Text(
                        "${_calculatedAreaHectares.toStringAsFixed(3)} ha",
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 24))),

                // --- USER SENSOR INPUT ---
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Sensor Inventory", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20)
                            ),
                            child: Text("${_userSensorCount.round()} Units", 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 8,
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Theme.of(context).colorScheme.secondary,
                        ),
                        child: Slider(
                          value: _userSensorCount,
                          min: 3,
                          max: _sliderMax,
                          divisions: (_sliderMax - 3).toInt(),
                          onChanged: (val) => setState(() => _userSensorCount = val),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.tips_and_updates, size: 16, color: Theme.of(context).colorScheme.secondary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                              "AI Recommended: ${_recommendedSensorCount.toInt()} sensors",
                              style: const TextStyle(color: Colors.white70, fontSize: 12)
                          )),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
      ]),
    );
  }

  Widget _buildRangesStep() => Column(
      children: _bounds.keys
          .map((key) => _buildRangeSlider("$key (${_units[key]})"))
          .toList());

  Widget _buildDropdown(String label, IconData icon, String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
        value: value,
        dropdownColor: Colors.white,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: onChanged);
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller) {
    return TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)));
  }

  Widget _buildRangeSlider(String label) {
    String key = label.split(" (")[0];
    double max = key.contains('Water') ? 1000 : (key.contains('Seed') ? 100000 : 250);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16), child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)
          ),
          child: Text('${_bounds[key]![0].round()} - ${_bounds[key]![1].round()} ${label.split("(")[1].replaceAll(")", "")}', 
            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 12)),
        )
      ]),
      const SizedBox(height: 12),
      RangeSlider(
          values: RangeValues(_bounds[key]![0], _bounds[key]![1]),
          min: 0, max: max, divisions: 50,
          onChanged: (v) => setState(() => _bounds[key] = [v.start, v.end]))
    ])));
  }
}