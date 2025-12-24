import 'dart:math';
import 'package:flutter/material.dart';

class OptimizerAlgorithms {

  // ==========================================================
  // 1. NUTRIENT OPTIMIZATION (ADE-PSO)
  // ==========================================================
  static ({List<double> position, double fitness}) runNutrientAlgo(
      Map<String, List<double>> bounds, String crop, String soil) {
    final random = Random();
    final problemBounds = bounds.values.toList();

    // Initialize with random valid positions
    List<double> bestPosition = List.generate(problemBounds.length, (i) {
      return problemBounds[i][0] + random.nextDouble() * (problemBounds[i][1] - problemBounds[i][0]);
    });

    // Run Optimization (50 Generations)
    for(int i=0; i<50; i++) {
      List<double> candidate = List.generate(problemBounds.length, (j) {
        double val = bestPosition[j] + (random.nextDouble() - 0.5) * 10;
        return val.clamp(problemBounds[j][0], problemBounds[j][1]);
      });
      if(_yieldFitness(candidate, crop, soil) > _yieldFitness(bestPosition, crop, soil)) {
        bestPosition = candidate;
      }
    }

    return (
    position: bestPosition,
    fitness: _yieldFitness(bestPosition, crop, soil)
    );
  }

  // Biological Fitness Model
  static double _yieldFitness(List<double> inputs, String crop, String soil) {
    double n = inputs[0], p = inputs[1], k = inputs[2], w = inputs[3], d = inputs[4];

    // Crop-Specific Ideal Constants
    Map<String, double> opt = {'n': 150, 'p': 60, 'k': 60, 'w': 600, 'd': 75000};
    if (crop == 'Wheat') opt = {'n': 180, 'p': 70, 'k': 50, 'w': 500, 'd': 85000};
    if (crop == 'Soybeans') opt = {'n': 60, 'p': 80, 'k': 90, 'w': 700, 'd': 65000};

    // Gaussian Decay Functions (Bell Curves)
    double nScore = exp(-pow((n - opt['n']!) / 50, 2));
    double pScore = exp(-pow((p - opt['p']!) / 25, 2));
    double kScore = exp(-pow((k - opt['k']!) / 25, 2));
    double wScore = exp(-pow((w - opt['w']!) / 150, 2));
    double dScore = exp(-pow((d - opt['d']!) / 10000, 2));

    double soilModifier = soil == 'Sandy' ? 0.9 : (soil == 'Clay' ? 1.05 : 1.0);
    double yieldVal = 2000 + 10000 * (nScore * pScore * kScore * wScore * dScore) * soilModifier;

    if (w < 300) yieldVal *= 0.6; // Drought penalty

    return yieldVal;
  }

  // ==========================================================
  // 2. SENSOR PLACEMENT (STRICT BOUNDARY ENFORCEMENT)
  // ==========================================================
  static List<Map<String, dynamic>> runSensorOptimization(
      int sensorCount, String shape, Map<String, double> dim, List<Offset> vertices) {
    final random = Random();
    int dimensions = sensorCount * 2;

    // Calculate Polygon Bounds for Normalization
    double minX = 0, minY = 0, w = 0, h = 0;
    if (shape == 'Manual Polygon' && vertices.isNotEmpty) {
      minX = vertices.map((p) => p.dx).reduce(min);
      minY = vertices.map((p) => p.dy).reduce(min);
      w = vertices.map((p) => p.dx).reduce(max) - minX;
      h = vertices.map((p) => p.dy).reduce(max) - minY;
      if(w==0) w=1; if(h==0) h=1;
    }

    // --- STEP 1: INITIALIZATION WITH REJECTION SAMPLING ---
    // This forces the initial random guess to be INSIDE the field.
    List<List<double>> population = [];
    int popSize = 30;

    for (int i = 0; i < popSize; i++) {
      List<double> individual = [];
      for(int s = 0; s < sensorCount; s++) {
        double rx, ry;
        int attempts = 0;
        do {
          rx = random.nextDouble();
          ry = random.nextDouble();
          attempts++;
          // Force break if shape is weird to prevent infinite loop
        } while (!_isValidPosition(rx, ry, shape, vertices, minX, minY, w, h) && attempts < 100);
        individual.add(rx);
        individual.add(ry);
      }
      population.add(individual);
    }

    List<double> globalBestPosition = List.from(population[0]);
    double globalBestFitness = -double.infinity;

    // --- STEP 2: EVOLUTION LOOP ---
    int generations = 50;
    for (int g = 0; g < generations; g++) {
      for (int i = 0; i < popSize; i++) {
        double fitness = _sensorFitness(population[i], sensorCount, shape, vertices, minX, minY, w, h);

        if (fitness > globalBestFitness) {
          globalBestFitness = fitness;
          globalBestPosition = List.from(population[i]);
        }

        // Mutation (DE Strategy)
        int r1 = random.nextInt(popSize);
        int r2 = random.nextInt(popSize);
        int r3 = random.nextInt(popSize);
        List<double> mutant = List.generate(dimensions, (j) {
          double val = population[r1][j] + 0.5 * (population[r2][j] - population[r3][j]);
          return val.clamp(0.0, 1.0);
        });

        if (_sensorFitness(mutant, sensorCount, shape, vertices, minX, minY, w, h) > fitness) {
          population[i] = mutant;
        }
      }
    }

    // --- STEP 3: CONVERT TO REAL COORDINATES ---
    List<Map<String, dynamic>> results = [];
    for (int i = 0; i < sensorCount; i++) {
      double normX = globalBestPosition[i * 2];
      double normY = globalBestPosition[i * 2 + 1];

      // Safety clamp to ensure 100% inside 0.0-1.0
      normX = normX.clamp(0.001, 0.999);
      normY = normY.clamp(0.001, 0.999);

      String locStr = "";
      // For the painter, we pass the normalized offset directly
      Offset painterOffset = Offset(normX, normY);

      if (shape == 'Rectangle') {
        double realX = normX * dim['width']!;
        double realY = normY * dim['length']!;
        locStr = "X: ${realX.toStringAsFixed(1)}m, Y: ${realY.toStringAsFixed(1)}m";
      } else if (shape == 'Circle') {
        double r = dim['radius']!;
        double dx = (normX - 0.5) * 2 * r;
        double dy = (normY - 0.5) * 2 * r;
        locStr = "${dx.abs().toStringAsFixed(1)}m ${dx>0?'E':'W'}, ${dy.abs().toStringAsFixed(1)}m ${dy>0?'S':'N'}";
      } else {
        double realX = minX + normX * w;
        double realY = minY + normY * h;
        locStr = "X: ${realX.toStringAsFixed(1)}m, Y: ${realY.toStringAsFixed(1)}m";
      }

      results.add({
        'name': 'Sensor ${i + 1}',
        'icon': Icons.sensors,
        'offset': painterOffset,
        'location_string': locStr
      });
    }
    return results;
  }

  // Helper: Strictly checks if a normalized point (0-1) translates to a valid spot
  static bool _isValidPosition(double nx, double ny, String shape, List<Offset> vertices, double minX, double minY, double w, double h) {
    if (shape == 'Circle') {
      double dist = (Offset(nx, ny) - const Offset(0.5, 0.5)).distance;
      return dist <= 0.5;
    } else if (shape == 'Manual Polygon') {
      double realX = minX + nx * w;
      double realY = minY + ny * h;
      return _isPointInPolygon(Offset(realX, realY), vertices);
    }
    return true; // Rectangle is always true if 0-1
  }

  static double _sensorFitness(
      List<double> genome,
      int count,
      String shape,
      List<Offset> vertices,
      double minX, double minY, double w, double h) {

    double minDistance = double.infinity;
    List<Offset> points = [];

    for (int i = 0; i < count; i++) {
      double nx = genome[i * 2];
      double ny = genome[i * 2 + 1];

      // HARD PENALTY if outside boundaries
      if (!_isValidPosition(nx, ny, shape, vertices, minX, minY, w, h)) {
        return -1.0e9; // -1 Billion penalty (Effectively Impossible)
      }
      points.add(Offset(nx, ny));
    }

    // Maximize Distance Spread
    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        double d = (points[i] - points[j]).distance;
        if (d < minDistance) minDistance = d;
      }
    }
    return minDistance;
  }

  // Ray-Casting Algorithm for Point-in-Polygon
  static bool _isPointInPolygon(Offset point, List<Offset> polygon) {
    if (polygon.length < 3) return false;
    int i, j = polygon.length - 1;
    bool oddNodes = false;

    for (i = 0; i < polygon.length; i++) {
      if ((polygon[i].dy < point.dy && polygon[j].dy >= point.dy ||
          polygon[j].dy < point.dy && polygon[i].dy >= point.dy) &&
          (polygon[i].dx <= point.dx || polygon[j].dx <= point.dx)) {
        if (polygon[i].dx +
            (point.dy - polygon[i].dy) /
                (polygon[j].dy - polygon[i].dy) *
                (polygon[j].dx - polygon[i].dx) <
            point.dx) {
          oddNodes = !oddNodes;
        }
      }
      j = i;
    }
    return oddNodes;
  }

  static double calculatePolygonArea(List<Offset> vertices) {
    if (vertices.length < 3) return 0.0;
    double area = 0.0;
    for (int i = 0; i < vertices.length; i++) {
      Offset p1 = vertices[i];
      Offset p2 = vertices[(i + 1) % vertices.length];
      area += (p1.dx * p2.dy) - (p2.dx * p1.dy);
    }
    return (area.abs() / 2.0);
  }

  // ==========================================================
  // 3. DETAILED EXPERT SCHEDULE GENERATOR
  // ==========================================================
  static List<Map<String, dynamic>> generateApplicationSchedule(
      String crop, Map<String, double> rates, double ha) {

    double totalN = rates['Nitrogen']! * ha;
    double totalP = rates['Phosphorus']! * ha;
    double totalK = rates['Potassium']! * ha;

    // Formatting helper
    String qty(double val) => val.toStringAsFixed(1);

    if (crop == 'Corn') {
      return [
        {
          'week': 'Week 0 (Pre-Planting)',
          'stage': 'Soil Preparation',
          'action': 'Basal Application',
          'details': [
            'Phosphorus: Apply ${qty(totalP)} kg (100% of Total)',
            'Potassium: Apply ${qty(totalK * 0.5)} kg (50% of Total)',
            'Nitrogen: Apply ${qty(totalN * 0.2)} kg (Starter Dose)'
          ],
          'timing': '3 days before sowing. Apply in late afternoon.',
          'method': 'Broadcast uniformly and rotovate into top 10cm of soil.',
          'water_advice': 'Pre-irrigate with 20mm water to activate granules.'
        },
        {
          'week': 'Week 4 (V6 Stage)',
          'stage': 'Rapid Vegetative Growth',
          'action': 'Side Dressing',
          'details': [
            'Nitrogen: Apply ${qty(totalN * 0.5)} kg (50% of Total)',
            'Potassium: Apply ${qty(totalK * 0.5)} kg (50% of Total)'
          ],
          'timing': 'Early morning (6:00 AM - 9:00 AM) after dew dries.',
          'method': 'Band placement: 5cm deep, 8cm away from root zone.',
          'water_advice': 'Irrigate immediately after application to dissolve nutrients.'
        },
        {
          'week': 'Week 9 (Tasseling)',
          'stage': 'Reproductive Phase',
          'action': 'Final Nitrogen Boost',
          'details': [
            'Nitrogen: Apply ${qty(totalN * 0.3)} kg (30% of Total)'
          ],
          'timing': 'Late afternoon (4:00 PM - 6:00 PM) to reduce volatilization.',
          'method': 'Fertigation (Drip) or careful inter-row banding.',
          'water_advice': 'Critical! Maintain soil moisture at 80% capacity.'
        }
      ];
    }
    else if (crop == 'Soybeans') {
      return [
        {
          'week': 'Week 0 (Sowing)',
          'stage': 'Planting',
          'action': 'Inoculation & Starter',
          'details': [
            'Phosphorus: Apply ${qty(totalP)} kg (100%)',
            'Potassium: Apply ${qty(totalK)} kg (100%)',
            'Inoculate seeds with Rhizobium japonicum.'
          ],
          'timing': 'At time of planting.',
          'method': 'Side-band fertilizer 5cm below and 5cm to the side of seed.',
          'water_advice': 'Ensure seedbed is moist but not saturated.'
        },
        {
          'week': 'Week 6 (R1 Bloom)',
          'stage': 'Flowering',
          'action': 'Nutrient Rescue',
          'details': [
            'Inspect leaves for yellowing (Nitrogen deficiency).',
            'If pale, apply ${qty(totalN * 0.2)} kg Nitrogen as rescue.'
          ],
          'timing': 'Cooler part of the day.',
          'method': 'Foliar spray (1-2% Urea solution) or side dress.',
          'water_advice': 'Avoid water stress. Flowers will abort if dry.'
        }
      ];
    }
    else { // Wheat
      return [
        {
          'week': 'Week 0',
          'stage': 'Sowing (Basal)',
          'action': 'Foundation Dose',
          'details': [
            'Nitrogen: Apply ${qty(totalN * 0.5)} kg (50%)',
            'Phosphorus: Apply ${qty(totalP)} kg (100%)',
            'Potassium: Apply ${qty(totalK)} kg (100%)'
          ],
          'timing': 'At sowing.',
          'method': 'Drill placement below seed level.',
          'water_advice': 'Light irrigation for germination.'
        },
        {
          'week': 'Week 3 (CRI Stage)',
          'stage': 'Crown Root Initiation',
          'action': 'First Top Dress',
          'details': [
            'Nitrogen: Apply ${qty(totalN * 0.25)} kg (25%)'
          ],
          'timing': 'Morning, just before irrigation.',
          'method': 'Broadcast evenly.',
          'water_advice': 'Most Critical Irrigation Stage for Wheat.'
        },
        {
          'week': 'Week 7 (Jointing)',
          'stage': 'Stem Elongation',
          'action': 'Final Top Dress',
          'details': [
            'Nitrogen: Apply ${qty(totalN * 0.25)} kg (25%)'
          ],
          'timing': 'Afternoon.',
          'method': 'Broadcast.',
          'water_advice': 'Moderate irrigation required.'
        }
      ];
    }
  }

  // ==========================================================
  // 4. DETAILED ADVICE GENERATOR
  // ==========================================================
  static List<Map<String, dynamic>> generateOptimizationAdvice(
      Map<String, List<double>> bounds, Map<String, double> rates) {
    List<Map<String, dynamic>> advice = [];

    // Water Strategy
    if(rates['Water']! < 400) {
      advice.add({
        'type': 'warning',
        'icon': Icons.water_drop,
        'title': 'Drought Risk Detected',
        'message': 'Optimized water level is low (${rates['Water']!.toStringAsFixed(0)} mm). Apply mulch to retain soil moisture. Irrigate at night/evening to reduce evaporation.'
      });
    } else {
      advice.add({
        'type': 'info',
        'icon': Icons.water,
        'title': 'High Water Demand',
        'message': 'Crop needs high water volume. Avoid flooding. Use split applications every 4-5 days to prevent nutrient leaching.'
      });
    }

    // Nitrogen Strategy
    if(rates['Nitrogen']! > 180) {
      advice.add({
        'type': 'warning',
        'icon': Icons.science,
        'title': 'Nitrogen Volatilization Risk',
        'message': 'High N rate (${rates['Nitrogen']!.toStringAsFixed(0)} kg/ha). Use Urease Inhibitors if broadcasting urea. Split application is mandatory.'
      });
    }

    // Density Strategy
    if(rates['Seed Density']! > 80000) {
      advice.add({
        'type': 'info',
        'icon': Icons.grass,
        'title': 'Canopy Management',
        'message': 'High density planting. Monitor specifically for fungal diseases (Rust/Blight) due to reduced airflow. Orient rows North-South.'
      });
    }

    return advice;
  }
}