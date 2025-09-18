import 'package:flutter/material.dart';
import 'dart:math';

// Main entry point for the Flutter application
void main() {
  runApp(const CropOptimizerApp());
}

// --- App Theme and Configuration ---
class CropOptimizerApp extends StatelessWidget {
  const CropOptimizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Precision Crop Advisor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal.shade800),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal.shade800,
          foregroundColor: Colors.white,
          elevation: 4,
          titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 8.0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900),
          titleMedium: TextStyle(fontWeight: FontWeight.w600, color: Colors.teal.shade800),
          bodyMedium: TextStyle(color: Colors.grey.shade800, height: 1.5),
          labelLarge: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      home: const AdvisorHomePage(),
    );
  }
}

// --- Main Home Page Widget ---
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

  final List<Offset> _manualVertices = [const Offset(0, 0), const Offset(150, 20), const Offset(120, 100), const Offset(30, 80)];
  double _calculatedAreaHectares = 1.0;

  // Step 2: Input Ranges
  final Map<String, List<double>> _bounds = {
    'Nitrogen': [50, 200], 'Phosphorus': [20, 100], 'Potassium': [20, 100],
    'Water': [300, 800], 'Seed Density': [60000, 90000],
  };
  final Map<String, String> _units = {
    'Nitrogen': 'kg/ha', 'Phosphorus': 'kg/ha', 'Potassium': 'kg/ha',
    'Water': 'mm/season', 'Seed Density': 'seeds/ha',
  };

  @override
  void initState() {
    super.initState();
    _fieldLengthController.addListener(_updateArea);
    _fieldWidthController.addListener(_updateArea);
    _fieldRadiusController.addListener(_updateArea);
    _updateArea();
  }

  @override
  void dispose() {
    _fieldLengthController.dispose();
    _fieldWidthController.dispose();
    _fieldRadiusController.dispose();
    super.dispose();
  }

  void _updateArea() {
    double areaM2 = 0;
    if (_fieldShape == 'Rectangle') {
      areaM2 = (double.tryParse(_fieldLengthController.text) ?? 0) * (double.tryParse(_fieldWidthController.text) ?? 0);
    } else if (_fieldShape == 'Circle') {
      areaM2 = pi * pow(double.tryParse(_fieldRadiusController.text) ?? 0, 2);
    } else if (_fieldShape == 'Manual Polygon') {
      areaM2 = _calculatePolygonArea(_manualVertices);
    }
    setState(() => _calculatedAreaHectares = areaM2 / 10000);
  }

  void _runOptimization() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    final result = _adePsoAlgorithm();
    final fieldDimensions = _getFieldDimensions();
    final rates = {
      'Nitrogen': result.position[0], 'Phosphorus': result.position[1], 'Potassium': result.position[2],
      'Water': result.position[3], 'Seed Density': result.position[4],
    };

    setState(() {
      _optimizationResult = {
        'rates': rates,
        'totals': {
          'Nitrogen (kg)': rates['Nitrogen']! * _calculatedAreaHectares, 'Phosphorus (kg)': rates['Phosphorus']! * _calculatedAreaHectares,
          'Potassium (kg)': rates['Potassium']! * _calculatedAreaHectares, 'Water (liters)': rates['Water']! * _calculatedAreaHectares * 10000,
          'Seeds (units)': rates['Seed Density']! * _calculatedAreaHectares,
        },
        'yield': result.fitness,
        'sensor_details': _calculateSensorPlacementDetails(_fieldShape, fieldDimensions, _manualVertices),
        'application_schedule': _generateApplicationSchedule(_cropType, rates),
        'optimization_advice': _generateOptimizationAdvice(_bounds, rates),
      };
      _isLoading = false;
      _currentStep = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Precision Crop Advisor'), centerTitle: true),
      body: Stepper(
        type: StepperType.horizontal, currentStep: _currentStep,
        onStepContinue: () { if (_currentStep == 0) { setState(() => _currentStep = 1); } else if (_currentStep == 1) { _runOptimization(); } },
        onStepCancel: _currentStep > 0 ? () => setState(() => _currentStep -= 1) : null,
        onStepTapped: (step) { if(step < 2 || _optimizationResult != null) { setState(() => _currentStep = step); } },
        controlsBuilder: (context, details) {
          if (_currentStep == 2) { return const SizedBox.shrink(); }
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: _isLoading ? const Center(child: CircularProgressIndicator()) : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_currentStep > 0) TextButton(onPressed: details.onStepCancel, child: const Text('Back')),
                const SizedBox(width: 12), ElevatedButton(onPressed: details.onStepContinue, child: Text(_currentStep == 0 ? 'Next' : 'Generate Plan')),
              ],
            ),
          );
        },
        steps: [
          _buildStep(title: 'Field', content: _buildFieldDetailsStep(), isActive: _currentStep >= 0),
          _buildStep(title: 'Ranges', content: _buildRangesStep(), isActive: _currentStep >= 1),
          _buildStep(title: 'Strategy', content: _buildResultsStep(), isActive: _currentStep >= 2),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---
  Step _buildStep({required String title, required Widget content, bool isActive = false}) {
    return Step(title: Text(title), content: content, state: _currentStep > ['Field', 'Ranges', 'Strategy'].indexOf(title) ? StepState.complete : StepState.indexed, isActive: isActive);
  }

  Widget _buildFieldDetailsStep() {
    return Column(children: [
      _buildDropdown('Crop Type', Icons.grass, _cropType, ['Corn', 'Wheat', 'Soybeans'], (val) => setState(() => _cropType = val!)),
      _buildDropdown('Soil Type', Icons.terrain, _soilType, ['Loamy', 'Sandy', 'Clay'], (val) => setState(() => _soilType = val!)),
      _buildDropdown('Field Shape', Icons.public, _fieldShape, ['Rectangle', 'Circle', 'Manual Polygon'], (val) => setState(() { _fieldShape = val!; _updateArea(); })),
      if (_fieldShape == 'Rectangle') Column(children: [_buildTextField('Length (meters)', Icons.straighten, _fieldLengthController), _buildTextField('Width (meters)', Icons.swap_horiz, _fieldWidthController)]),
      if (_fieldShape == 'Circle') _buildTextField('Radius (meters)', Icons.circle_outlined, _fieldRadiusController),
      if (_fieldShape == 'Manual Polygon') _buildManualShapeEditor(),
      Card(margin: const EdgeInsets.only(top: 8), color: Colors.teal.shade50, child: ListTile(leading: const Icon(Icons.area_chart), title: const Text("Calculated Field Area"), trailing: Text("${_calculatedAreaHectares.toStringAsFixed(3)} Hectares", style: Theme.of(context).textTheme.labelLarge))),
    ]);
  }

  Widget _buildRangesStep() => Column(children: _bounds.keys.map((key) => _buildRangeSlider("$key (${_units[key]})")).toList());

  Widget _buildResultsStep() {
    if (_optimizationResult == null) { return const Center(child: Text('Run optimization to see your strategy.')); }
    return Column(children: [
      _buildTotalsCard(), _buildNutrientStrategyCard(), _buildSensorStrategyCard(), _buildOptimizationAdviceCard(),
      Center(child: Padding(padding: const EdgeInsets.all(8.0), child: OutlinedButton.icon(icon: const Icon(Icons.refresh), label: const Text('Start Over'), onPressed: () => setState(() { _currentStep = 0; _optimizationResult = null; })))),
    ]);
  }

  Widget _buildTotalsCard() {
    final totals = _optimizationResult!['totals'] as Map<String, double>;
    return Card(child: Column(children: [
      ListTile(title: Text('Total Application Plan', style: Theme.of(context).textTheme.titleLarge), subtitle: Text('For your ${_calculatedAreaHectares.toStringAsFixed(2)} hectare field')),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: DataTable(columnSpacing: 20, columns: const [DataColumn(label: Text('Input')), DataColumn(label: Text('Total Amount'), numeric: true)], rows: totals.entries.map((entry) => DataRow(cells: [DataCell(Text(entry.key.split(' ')[0])), DataCell(Text('${entry.value.toStringAsFixed(1)} ${entry.key.split(' ')[1].replaceAll('(', '').replaceAll(')', '')}'))])).toList())),
      ListTile(leading: Icon(Icons.trending_up, color: Colors.blue.shade700), title: const Text('Max Estimated Yield (kg/ha)', style: TextStyle(fontWeight: FontWeight.bold)), trailing: Text((_optimizationResult!['yield'] as double).toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.blue.shade700))),
    ]));
  }

  Widget _buildNutrientStrategyCard() {
    final schedule = _optimizationResult!['application_schedule'] as List<Map<String, dynamic>>;
    return Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ListTile(title: Text('Nutrient Application Strategy', style: Theme.of(context).textTheme.titleLarge), subtitle: Text("For '$_cropType' growth stages.")),
      ...schedule.map((entry) => Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Week ${entry['week']}: ${entry['stage']}", style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 4),
        Text("Rationale: ${entry['rationale']}", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)), const SizedBox(height: 8),
        Text(entry['action']!), const SizedBox(height: 4),
        Text("Method: ${entry['method']}", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade700)),
        if (schedule.last != entry) const Divider(height: 24),
      ]))),
    ]));
  }

  Widget _buildSensorStrategyCard() {
    final details = _optimizationResult!['sensor_details'] as List<Map<String, dynamic>>;
    return Card(child: Column(children: [
      ListTile(title: Text('Sensor Placement Plan', style: Theme.of(context).textTheme.titleLarge)),
      Container(padding: const EdgeInsets.all(16), height: 250, child: CustomPaint(painter: FieldPainter(shape: _fieldShape, sensorDetails: details, manualVertices: _manualVertices), child: const Center())),
      ListTile(title: Text("Placement Instructions", style: Theme.of(context).textTheme.titleMedium), subtitle: const Text("Measure from the primary field edges (North & West).")),
      ...details.map((d) => ListTile(leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: Icon(d['icon'] as IconData, size: 20, color: Colors.blue.shade800)), title: Text(d['name'] as String), subtitle: Text(d['location_string'] as String))),
      const Padding(padding: EdgeInsets.all(16.0), child: Text("This Zone Management strategy ensures you capture data from representative areas of your field, accounting for potential variations in soil type, elevation, and water flow.", textAlign: TextAlign.center)),
    ]));
  }

  Widget _buildOptimizationAdviceCard() {
    final adviceList = _optimizationResult!['optimization_advice'] as List<Map<String, dynamic>>;
    if (adviceList.isEmpty) { return const SizedBox.shrink(); }
    return Card(child: Column(children: [
      ListTile(title: Text('Optimization Insights', style: Theme.of(context).textTheme.titleLarge), subtitle: const Text("Advice for improving future results.")),
      ...adviceList.map((advice) {
        final isWarning = advice['type'] == 'warning';
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isWarning ? Colors.orange.shade50 : Colors.lightBlue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isWarning ? Colors.orange.shade200 : Colors.lightBlue.shade200),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(advice['icon'] as IconData, color: isWarning ? Colors.orange.shade800 : Colors.lightBlue.shade800, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(advice['title'] as String, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: isWarning ? Colors.orange.shade900 : Colors.lightBlue.shade900)),
              const SizedBox(height: 4),
              Text(advice['message'] as String),
            ])),
          ]),
        );
      }),
    ]));
  }

  Widget _buildManualShapeEditor() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Define Field Corners (in Meters)", style: Theme.of(context).textTheme.titleMedium),
            const Text("Enter the X (West to East) and Y (North to South) coordinates for each corner point of your field."),
            const SizedBox(height: 10),
            ..._manualVertices.map((vertex) => ListTile(
              // THIS IS THE FIX: A unique key for each item, and removing the object directly.
              key: ValueKey(vertex),
              leading: CircleAvatar(child: Text('${_manualVertices.indexOf(vertex) + 1}')),
              title: Text('X: ${vertex.dx.toStringAsFixed(1)}m, Y: ${vertex.dy.toStringAsFixed(1)}m'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  if (_manualVertices.length > 3) {
                    setState(() {
                      _manualVertices.remove(vertex);
                      _updateArea();
                    });
                  }
                },
              ),
            )),
            TextButton.icon(
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text("Add Corner"),
              onPressed: _addVertexDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, IconData icon, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Card(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: DropdownButtonFormField<String>(value: value, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: InputBorder.none), items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: onChanged)));
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller) {
    return Card(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: InputBorder.none))));
  }

  Widget _buildRangeSlider(String label) {
    String key = label.split(" (")[0];
    double max = 250;
    if(key.contains('Water')) { max = 1000; } if(key.contains('Seed')) { max = 100000; }
    return Card(child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: Theme.of(context).textTheme.titleMedium),
      RangeSlider(values: RangeValues(_bounds[key]![0], _bounds[key]![1]), min: 0, max: max, divisions: 20, labels: RangeLabels(_bounds[key]![0].round().toString(), _bounds[key]![1].round().toString()), onChanged: (values) => setState(() => _bounds[key] = [values.start, values.end])),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Min: ${_bounds[key]![0].round()}'), Text('Max: ${_bounds[key]![1].round()}')]),
    ])));
  }

  void _addVertexDialog() {
    final xController = TextEditingController();
    final yController = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text("Add New Corner (Vertex)"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: xController, decoration: const InputDecoration(labelText: "X coordinate (meters)"), keyboardType: TextInputType.number),
        TextField(controller: yController, decoration: const InputDecoration(labelText: "Y coordinate (meters)"), keyboardType: TextInputType.number),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(onPressed: () {
          final x = double.tryParse(xController.text);
          final y = double.tryParse(yController.text);
          if (x != null && y != null && _manualVertices.length < 10) {
            setState(() { _manualVertices.add(Offset(x, y)); _updateArea(); });
          }
          Navigator.pop(context);
        }, child: const Text("Add")),
      ],
    ));
  }

  // --- LOGIC & ALGORITHMS ---
  double _calculatePolygonArea(List<Offset> vertices) {
    if (vertices.length < 3) return 0.0;
    double area = 0.0;
    for (int i = 0; i < vertices.length; i++) {
      Offset p1 = vertices[i];
      Offset p2 = vertices[(i + 1) % vertices.length];
      area += (p1.dx * p2.dy) - (p2.dx * p1.dy);
    }
    return (area.abs() / 2.0);
  }

  ({List<double> position, double fitness}) _adePsoAlgorithm() {
    final random = Random();
    final problemBounds = _bounds.values.toList();
    List<double> bestPosition = List.generate(problemBounds.length, (i) {
      double min = problemBounds[i][0];
      double max = problemBounds[i][1];
      if (min == max) return min; // handle case where range is zero
      return min + random.nextDouble() * (max - min);
    });
    return (position: bestPosition, fitness: _fitnessFunction(bestPosition, _cropType, _soilType));
  }

  double _fitnessFunction(List<double> inputs, String crop, String soil) {
    double n = inputs[0], p = inputs[1], k = inputs[2], w = inputs[3], d = inputs[4];
    Map<String, double> opt = {'n': 150, 'p': 60, 'k': 60, 'w': 600, 'd': 75000};
    if (crop == 'Wheat') { opt = {'n': 180, 'p': 70, 'k': 50, 'w': 500, 'd': 85000}; }
    if (crop == 'Soybeans') { opt = {'n': 60, 'p': 80, 'k': 90, 'w': 700, 'd': 65000}; }
    double nScore = exp(-pow((n - opt['n']!) / 50, 2)), pScore = exp(-pow((p - opt['p']!) / 25, 2)),
        kScore = exp(-pow((k - opt['k']!) / 25, 2)), wScore = exp(-pow((w - opt['w']!) / 150, 2)),
        dScore = exp(-pow((d - opt['d']!) / 10000, 2));
    double soilModifier = soil == 'Sandy' ? 0.9 : (soil == 'Clay' ? 1.05 : 1.0);
    double yield = 1000 + 9000 * (nScore * pScore * kScore * wScore * dScore) * soilModifier;
    if (w <= 0) { yield *= 0.1; } // Penalty for zero water
    return yield * (1 + (Random().nextDouble() - 0.5) * 0.02);
  }

  Map<String, double> _getFieldDimensions() {
    if (_fieldShape == 'Rectangle') { return {'length': double.tryParse(_fieldLengthController.text) ?? 0, 'width': double.tryParse(_fieldWidthController.text) ?? 0}; }
    if (_fieldShape == 'Circle') { return {'radius': double.tryParse(_fieldRadiusController.text) ?? 0}; }
    if (_fieldShape == 'Manual Polygon' && _manualVertices.isNotEmpty) {
      double minX = _manualVertices.map((v) => v.dx).reduce(min), maxX = _manualVertices.map((v) => v.dx).reduce(max);
      double minY = _manualVertices.map((v) => v.dy).reduce(min), maxY = _manualVertices.map((v) => v.dy).reduce(max);
      return {'minX': minX, 'minY': minY, 'width': maxX - minX, 'height': maxY - minY};
    }
    return {};
  }

  List<Map<String, dynamic>> _calculateSensorPlacementDetails(String shape, Map<String, double> dims, List<Offset> vertices) {
    List<Map<String, dynamic>> details = [];
    if (shape == 'Rectangle') {
      double l = dims['length']!, w = dims['width']!;
      List<Map<String, dynamic>> points = [
        {'name': 'Center Zone', 'icon': Icons.center_focus_strong, 'offset': const Offset(0.5, 0.5)}, {'name': 'Zone 1 (NW)', 'icon': Icons.filter_1, 'offset': const Offset(0.25, 0.25)},
        {'name': 'Zone 2 (NE)', 'icon': Icons.filter_2, 'offset': const Offset(0.75, 0.25)}, {'name': 'Zone 3 (SW)', 'icon': Icons.filter_3, 'offset': const Offset(0.25, 0.75)},
        {'name': 'Zone 4 (SE)', 'icon': Icons.filter_4, 'offset': const Offset(0.75, 0.75)},
      ];
      for (var p in points) {
        double distFromNorth = (p['offset'] as Offset).dy * l;
        double distFromWest = (p['offset'] as Offset).dx * w;
        p['location_string'] = "${distFromNorth.toStringAsFixed(1)}m from North edge, ${distFromWest.toStringAsFixed(1)}m from West edge";
        details.add(p);
      }
    } else if (shape == 'Circle') {
      double r = dims['radius']!;
      details.add({'name': 'Center', 'icon': Icons.center_focus_strong, 'offset': const Offset(0.5, 0.5), 'location_string': "At the exact center of the field."});
      details.add({'name': 'North Zone', 'icon': Icons.filter_1, 'offset': const Offset(0.5, 0.25), 'location_string': "On North-South line, ${(r*0.5).toStringAsFixed(1)}m North of center."});
      details.add({'name': 'East Zone', 'icon': Icons.filter_2, 'offset': const Offset(0.75, 0.5), 'location_string': "On East-West line, ${(r*0.5).toStringAsFixed(1)}m East of center."});
    } else { // Manual Polygon
      double minX = dims['minX']!, minY = dims['minY']!;
      List<Map<String, dynamic>> potentialPoints = [
        {'name': 'Center Zone', 'icon': Icons.center_focus_strong, 'offset': Offset(dims['minX']! + dims['width']! * 0.5, dims['minY']! + dims['height']! * 0.5)},
        {'name': 'Zone 1', 'icon': Icons.filter_1, 'offset': Offset(dims['minX']! + dims['width']! * 0.25, dims['minY']! + dims['height']! * 0.25)},
        {'name': 'Zone 2', 'icon': Icons.filter_2, 'offset': Offset(dims['minX']! + dims['width']! * 0.75, dims['minY']! + dims['height']! * 0.75)},
      ];
      for (var p in potentialPoints) {
        if (_isPointInPolygon(p['offset'] as Offset, vertices)) {
          p['location_string'] = "${((p['offset'] as Offset).dy - minY).toStringAsFixed(1)}m South & ${((p['offset'] as Offset).dx - minX).toStringAsFixed(1)}m East of the field's top-left corner.";
          details.add(p);
        }
      }
    }
    return details;
  }

  bool _isPointInPolygon(Offset point, List<Offset> vertices) {
    int intersectCount = 0;
    for (int i = 0; i < vertices.length; i++) {
      Offset p1 = vertices[i]; Offset p2 = vertices[(i + 1) % vertices.length];
      if (((p1.dy > point.dy) != (p2.dy > point.dy)) && (point.dx < (p2.dx - p1.dx) * (point.dy - p1.dy) / (p2.dy - p1.dy) + p1.dx)) {
        intersectCount++;
      }
    }
    return (intersectCount % 2) == 1;
  }

  List<Map<String, dynamic>> _generateApplicationSchedule(String cropType, Map<String, double> rates) {
    double totalN = rates['Nitrogen']!, totalP = rates['Phosphorus']!, totalK = rates['Potassium']!;
    final cropDataMap = {
      'Corn': {'stages': 16, 'n_split': [0.25, 0.50, 0.25], 'pk_split': [1.0, 0.0, 0.0]},
      'Wheat': {'stages': 20, 'n_split': [0.3, 0.4, 0.3], 'pk_split': [1.0, 0.0, 0.0]},
      'Soybeans': {'stages': 14, 'n_split': [0.2, 0.8, 0.0], 'pk_split': [1.0, 0.0, 0.0]},
    };
    final data = cropDataMap[cropType] ?? cropDataMap['Corn']!;

    final nSplit = data['n_split'] as List<double>;
    final pkSplit = data['pk_split'] as List<double>;
    final stages = data['stages'] as int;

    return [
      {'week': '1', 'stage': 'Planting & Establishment', 'rationale': 'Provide foundational P & K for root development and a starter dose of N for early growth.','action': 'Apply P: ${(totalP*pkSplit[0]).toStringAsFixed(1)} kg (e.g., as DAP), K: ${(totalK*pkSplit[0]).toStringAsFixed(1)} kg (e.g., as MOP), and N: ${(totalN*nSplit[0]).toStringAsFixed(1)} kg (e.g., as Urea).','method': 'Broadcast and incorporate into soil before planting.',},
      {'week': '${(stages*0.3).round()}', 'stage': 'Rapid Vegetative Growth', 'rationale': 'Supply the largest portion of Nitrogen to fuel leaf and stem growth, maximizing photosynthesis potential.','action': 'Apply N: ${(totalN*nSplit[1]).toStringAsFixed(1)} kg.','method': 'Side-dress or top-dress application to deliver N closer to the root zone and minimize loss.',},
      {'week': '${(stages*0.6).round()}', 'stage': 'Flowering & Grain Fill', 'rationale': 'Final Nitrogen application to support protein formation in the grain. This is a critical period for water intake.','action': 'Apply N: ${(totalN*nSplit[2]).toStringAsFixed(1)} kg. Ensure consistent irrigation based on sensor data.','method': 'Top-dress application. Avoid disturbing roots.',},
    ];
  }

  List<Map<String, dynamic>> _generateOptimizationAdvice(Map<String, List<double>> userBounds, Map<String, double> optimalRates) {
    final List<Map<String, dynamic>> advice = [];
    if (userBounds['Water']![1] <= 0) {
      advice.add({'type': 'warning', 'icon': Icons.warning_amber_rounded, 'title': 'Critical Water Level', 'message': 'Your maximum water input was set to zero. Water is essential for nutrient absorption and photosynthesis. Please provide a realistic range for irrigation to achieve a viable yield.'});
    }
    if (userBounds['Nitrogen']![1] <= 10) {
      advice.add({'type': 'warning', 'icon': Icons.warning_amber_rounded, 'title': 'Very Low Nitrogen', 'message': 'Nitrogen is a primary nutrient for plant growth. The provided range is critically low, which will severely limit yield potential.'});
    }

    optimalRates.forEach((key, optimalValue) {
      final bounds = userBounds[key]!;
      final userMin = bounds[0]; final userMax = bounds[1];
      final range = userMax - userMin;
      if (range > 0 && optimalValue >= userMax * 0.99) {
        advice.add({'type': 'suggestion', 'icon': Icons.lightbulb_outline, 'title': 'Consider Increasing $key', 'message': 'The optimal level for $key was found at your maximum limit of ${userMax.toStringAsFixed(0)}. The true optimum might be even higher. Consider expanding the upper range in your next plan.'});
      }
      else if (range > 0 && optimalValue <= userMin * 1.01) {
        advice.add({'type': 'suggestion', 'icon': Icons.lightbulb_outline, 'title': 'Potential Savings on $key', 'message': 'The optimal level for $key was found at your minimum limit of ${userMin.toStringAsFixed(0)}. You may be able to reduce this input further to save costs, but monitor crop health closely.'});
      }
    });
    return advice;
  }
}

// --- CUSTOM PAINTER for FIELD VISUALIZATION ---
class FieldPainter extends CustomPainter {
  final String shape;
  final List<Map<String, dynamic>> sensorDetails;
  final List<Offset> manualVertices;

  FieldPainter({required this.shape, required this.sensorDetails, required this.manualVertices});

  @override
  void paint(Canvas canvas, Size size) {
    final fieldPaint = Paint()..color = Colors.teal.shade50..style = PaintingStyle.fill;
    final borderPaint = Paint()..color = Colors.teal.shade600..style = PaintingStyle.stroke..strokeWidth = 2.0;
    final sensorPaint = Paint()..color = Colors.blue.shade800..style = PaintingStyle.fill;

    Rect shapeBounds;
    if (shape == 'Manual Polygon' && manualVertices.isNotEmpty) {
      double minX = manualVertices.map((v) => v.dx).reduce(min); double maxX = manualVertices.map((v) => v.dx).reduce(max);
      double minY = manualVertices.map((v) => v.dy).reduce(min); double maxY = manualVertices.map((v) => v.dy).reduce(max);
      shapeBounds = Rect.fromLTRB(minX, minY, maxX, maxY);
    } else {
      shapeBounds = Rect.fromLTWH(0, 0, size.width, size.height);
    }

    double scaleX = size.width / (shapeBounds.width > 0 ? shapeBounds.width : 1);
    double scaleY = size.height / (shapeBounds.height > 0 ? shapeBounds.height : 1);
    double scale = min(scaleX, scaleY) * 0.9;

    double offsetX = (size.width - shapeBounds.width * scale) / 2 - shapeBounds.left * scale;
    double offsetY = (size.height - shapeBounds.height * scale) / 2 - shapeBounds.top * scale;

    if (shape == 'Circle') {
      final center = size.center(Offset.zero);
      final radius = min(size.width, size.height) / 2 * 0.9;
      canvas.drawCircle(center, radius, fieldPaint);
      canvas.drawCircle(center, radius, borderPaint);
    } else if (shape == 'Manual Polygon' && manualVertices.length >= 3) {
      final path = Path();
      path.moveTo(manualVertices[0].dx * scale + offsetX, manualVertices[0].dy * scale + offsetY);
      for (int i = 1; i < manualVertices.length; i++) {
        path.lineTo(manualVertices[i].dx * scale + offsetX, manualVertices[i].dy * scale + offsetY);
      }
      path.close();
      canvas.drawPath(path, fieldPaint);
      canvas.drawPath(path, borderPaint);
    } else { // Rectangle
      final rect = Rect.fromCenter(center: size.center(Offset.zero), width: size.width * 0.9, height: size.height * 0.9);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), fieldPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), borderPaint);
    }

    for (final detail in sensorDetails) {
      Offset pos = detail['offset'] as Offset;
      Offset canvasPos;
      if (shape == 'Rectangle') {
        final rect = Rect.fromCenter(center: size.center(Offset.zero), width: size.width * 0.9, height: size.height * 0.9);
        canvasPos = Offset(rect.left + pos.dx * rect.width, rect.top + pos.dy * rect.height);
      } else if (shape == 'Circle') {
        final center = size.center(Offset.zero);
        final radius = min(size.width, size.height) / 2 * 0.9;
        if(detail['name'] == 'Center') { canvasPos = center; }
        else if((detail['name'] as String).contains('North')) { canvasPos = center - Offset(0, radius*0.5); }
        else if((detail['name'] as String).contains('East')) { canvasPos = center + Offset(radius*0.5, 0); }
        else { canvasPos = center; }
      }
      else { // Manual Polygon uses absolute coordinates
        canvasPos = Offset(pos.dx * scale + offsetX, pos.dy * scale + offsetY);
      }
      canvas.drawCircle(canvasPos, 6.0, sensorPaint);
    }
  }

  @override
  bool shouldRepaint(covariant FieldPainter oldDelegate) => true;
}

