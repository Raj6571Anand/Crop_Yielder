// import 'package:flutter/material.dart';
// import 'field_painter.dart';
//
// class ResultsView extends StatelessWidget {
//   final Map<String, dynamic> optimizationResult;
//   final double calculatedAreaHectares;
//   final int userSensorCount;
//   final String fieldShape;
//   final List<Offset> manualVertices;
//   final VoidCallback onReset;
//
//   const ResultsView({
//     super.key,
//     required this.optimizationResult,
//     required this.calculatedAreaHectares,
//     required this.userSensorCount,
//     required this.fieldShape,
//     required this.manualVertices,
//     required this.onReset,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(children: [
//         _buildTotalsCard(context),
//         _buildNutrientStrategyCard(context),
//         _buildSensorStrategyCard(context),
//         _buildOptimizationAdviceCard(context),
//         Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: OutlinedButton.icon(
//                 style: OutlinedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//                   side: BorderSide(color: Theme.of(context).colorScheme.primary),
//                   shape: const StadiumBorder()
//                 ),
//                 icon: const Icon(Icons.refresh),
//                 label: const Text('Reset Analysis'),
//                 onPressed: onReset)),
//       ]),
//     );
//   }
//
//   Widget _buildTotalsCard(BuildContext context) {
//     final totals = optimizationResult['totals'] as Map<String, double>;
//     return Card(
//         clipBehavior: Clip.antiAlias,
//         child: Column(children: [
//           Container(
//             padding: const EdgeInsets.all(16),
//             color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text('Total Application Plan',
//                     style: Theme.of(context).textTheme.titleLarge),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                   decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
//                   child: Text('${calculatedAreaHectares.toStringAsFixed(2)} ha', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
//                 )
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: totals.entries.map((e) {
//                 final name = e.key.split(' ')[0];
//                 final unit = e.key.split(' ')[1].replaceAll(RegExp(r'[()]'), '');
//                 return Padding(
//                   padding: const EdgeInsets.only(bottom: 12.0),
//                   child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 16)),
//                     RichText(
//                       text: TextSpan(
//                         children: [
//                           TextSpan(text: e.value.toStringAsFixed(1), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
//                           TextSpan(text: " $unit", style: TextStyle(color: Colors.grey.shade500, fontSize: 12))
//                         ]
//                       )
//                     )
//                   ],
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//           Container(
//             margin: const EdgeInsets.all(12),
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(colors: [
//                 Theme.of(context).colorScheme.secondary,
//                 Theme.of(context).colorScheme.secondary.withOpacity(0.7)
//               ]),
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(color: Theme.of(context).colorScheme.secondary.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))
//               ]
//             ),
//             child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//               const Text('Estimated Yield', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
//               Text("${(optimizationResult['yield'] as double).toStringAsFixed(0)} kg/ha",
//                   style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.white)),
//             ]),
//           ),
//         ]));
//   }
//
//   Widget _buildSensorStrategyCard(BuildContext context) {
//     final details = optimizationResult['sensor_details'] as List<Map<String, dynamic>>;
//     return Card(
//         clipBehavior: Clip.antiAlias,
//         child: Column(children: [
//           ListTile(
//             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             tileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
//               leading: Icon(Icons.radar, color: Theme.of(context).colorScheme.primary),
//               title: Text('Sensor Layout',
//                   style: Theme.of(context).textTheme.titleLarge),
//               subtitle: Text("Optimal placement for $userSensorCount devices")),
//
//           Container(
//               margin: const EdgeInsets.all(16),
//               height: 250,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: Colors.grey.shade100),
//                 boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(16),
//                 child: CustomPaint(
//                     painter: FieldPainter(
//                         shape: fieldShape,
//                         sensorDetails: details,
//                         manualVertices: manualVertices,
//                         context: context),
//                     child: const Center()),
//               )),
//           ExpansionTile(
//             title: const Text("Coordinates List", style: TextStyle(fontWeight: FontWeight.w600)),
//             shape: const Border(),
//             children: details.map((d) => ListTile(
//                 dense: true,
//                 leading: Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary.withOpacity(0.1), shape: BoxShape.circle),
//                   child: Icon(d['icon'] as IconData, size: 16, color: Theme.of(context).colorScheme.secondary)),
//                 title: Text(d['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
//                 trailing: Text(d['location_string'] as String, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)))).toList(),
//           ),
//         ]));
//   }
//
//   Widget _buildNutrientStrategyCard(BuildContext context) {
//     final schedule = optimizationResult['application_schedule'] as List<Map<String, dynamic>>;
//     return Card(
//       clipBehavior: Clip.antiAlias,
//       child: Column(
//       children: [
//         ListTile(
//           tileColor: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.2),
//           leading: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.tertiary),
//           title: Text("Nutrient Schedule", style: Theme.of(context).textTheme.titleLarge)
//         ),
//         ...schedule.map((e) => Theme(
//           data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
//           child: ExpansionTile(
//             leading: CircleAvatar(
//               backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
//               child: Text(e['week'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
//             ),
//             title: Text(e['stage'], style: const TextStyle(fontWeight: FontWeight.w700)),
//             children: [
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(16.0),
//                 color: Colors.grey.shade50,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Icon(Icons.arrow_right_alt, size: 20, color: Colors.grey),
//                         const SizedBox(width: 8),
//                         Expanded(child: Text(e['action'], style: const TextStyle(fontWeight: FontWeight.w600, height: 1.3))),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Text("Rationale: ${e['rationale']}", style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic, fontSize: 13)),
//                     const SizedBox(height: 4),
//                     Chip(label: Text(e['method']), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact, backgroundColor: Colors.white, side: BorderSide(color: Colors.grey.shade300),),
//                   ],
//                 ),
//               )
//             ],
//           ),
//         ))
//       ],
//     ));
//   }
//
//   Widget _buildOptimizationAdviceCard(BuildContext context) {
//     final adviceList = optimizationResult['optimization_advice'] as List<Map<String, dynamic>>;
//     if (adviceList.isEmpty) return const SizedBox.shrink();
//     return Card(
//       color: Colors.white,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.amber.withOpacity(0.5))),
//       child: Column(
//       children: [
//         ListTile(leading: const Icon(Icons.lightbulb_outline, color: Colors.amber), title: Text("AI Insights", style: Theme.of(context).textTheme.titleLarge)),
//         ...adviceList.map((a) {
//           final isWarning = a['type'] == 'warning';
//           final color = isWarning ? Colors.orange : Colors.blue;
//           return ListTile(
//             leading: Icon(a['icon'], color: color),
//             title: Text(a['title'], style: TextStyle(color: color, fontWeight: FontWeight.bold)),
//             subtitle: Text(a['message']),
//           );
//         })
//       ],
//     ));
//   }
// }

import 'package:flutter/material.dart';
import 'field_painter.dart';

class ResultsView extends StatelessWidget {
  final Map<String, dynamic> optimizationResult;
  final double calculatedAreaHectares;
  final int userSensorCount;
  final String fieldShape;
  final List<Offset> manualVertices;
  final VoidCallback onReset;

  const ResultsView({
    super.key,
    required this.optimizationResult,
    required this.calculatedAreaHectares,
    required this.userSensorCount,
    required this.fieldShape,
    required this.manualVertices,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(children: [
        _buildTotalsCard(context),
        _buildNutrientStrategyCard(context),
        _buildSensorStrategyCard(context),
        _buildOptimizationAdviceCard(context),
        Padding(
            padding: const EdgeInsets.all(24.0),
            child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    shape: const StadiumBorder()
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Analysis'),
                onPressed: onReset)),
      ]),
    );
  }

  // Totals Card (Same as before, visual tweaks)
  Widget _buildTotalsCard(BuildContext context) {
    final totals = optimizationResult['totals'] as Map<String, double>;
    return Card(
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Resource Plan', style: Theme.of(context).textTheme.titleLarge),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: Text('${calculatedAreaHectares.toStringAsFixed(2)} ha', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: totals.entries.map((e) {
                final name = e.key.split(' ')[0];
                final unit = e.key.split(' ')[1].replaceAll(RegExp(r'[()]'), '');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 16)),
                      RichText(
                          text: TextSpan(
                              children: [
                                TextSpan(text: e.value.toStringAsFixed(1), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                                TextSpan(text: " $unit", style: TextStyle(color: Colors.grey.shade500, fontSize: 12))
                              ]
                          )
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Theme.of(context).colorScheme.secondary,
                  Theme.of(context).colorScheme.secondary.withOpacity(0.7)
                ]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Theme.of(context).colorScheme.secondary.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))
                ]
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Projected Yield', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
              Text("${(optimizationResult['yield'] as double).toStringAsFixed(0)} kg/ha",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.white)),
            ]),
          ),
        ]));
  }

  // --- UPDATED NUTRIENT STRATEGY CARD ---
  Widget _buildNutrientStrategyCard(BuildContext context) {
    final schedule = optimizationResult['application_schedule'] as List<Map<String, dynamic>>;
    return Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            ListTile(
                tileColor: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.2),
                leading: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.tertiary),
                title: Text("Detailed Schedule", style: Theme.of(context).textTheme.titleLarge)
            ),
            ...schedule.map((e) => Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: true,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Text(e['week'].split(' ')[1], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                ),
                title: Text(e['stage'], style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(e['action'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(top: BorderSide(color: Colors.grey.shade200))
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dosage List
                        ... (e['details'] as List<dynamic>).map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_circle_outline, size: 16, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(child: Text(d, style: const TextStyle(fontWeight: FontWeight.w600))),
                            ],
                          ),
                        )),
                        const SizedBox(height: 12),

                        // Timing & Method
                        _buildInfoRow(context, Icons.access_time, "Best Time:", e['timing']),
                        const SizedBox(height: 6),
                        _buildInfoRow(context, Icons.engineering, "Method:", e['method']),
                        const SizedBox(height: 6),
                        _buildInfoRow(context, Icons.water_drop_outlined, "Watering:", e['water_advice']),
                      ],
                    ),
                  )
                ],
              ),
            ))
          ],
        ));
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800, fontSize: 12)),
        const SizedBox(width: 4),
        Expanded(child: Text(value, style: TextStyle(color: Colors.grey.shade700, fontSize: 12))),
      ],
    );
  }

  // --- SENSOR CARD (Unchanged) ---
  Widget _buildSensorStrategyCard(BuildContext context) {
    final details = optimizationResult['sensor_details'] as List<Map<String, dynamic>>;
    return Card(
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              tileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              leading: Icon(Icons.radar, color: Theme.of(context).colorScheme.primary),
              title: Text('Sensor Layout', style: Theme.of(context).textTheme.titleLarge),
              subtitle: Text("Optimal coverage for $userSensorCount nodes")),

          Container(
              margin: const EdgeInsets.all(16),
              height: 250,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomPaint(
                    painter: FieldPainter(
                        shape: fieldShape,
                        sensorDetails: details,
                        manualVertices: manualVertices,
                        context: context),
                    child: const Center()),
              )),
        ]));
  }

  // --- UPDATED ADVICE CARD ---
  Widget _buildOptimizationAdviceCard(BuildContext context) {
    final adviceList = optimizationResult['optimization_advice'] as List<Map<String, dynamic>>;
    if (adviceList.isEmpty) return const SizedBox.shrink();
    return Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.amber.withOpacity(0.5))),
        child: Column(
          children: [
            ListTile(leading: const Icon(Icons.lightbulb_outline, color: Colors.amber), title: Text("Expert Insights", style: Theme.of(context).textTheme.titleLarge)),
            ...adviceList.map((a) {
              final isWarning = a['type'] == 'warning';
              final color = isWarning ? Colors.orange.shade800 : Colors.blue.shade800;
              final bg = isWarning ? Colors.orange.shade50 : Colors.blue.shade50;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(a['icon'], color: color),
                  title: Text(a['title'], style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  subtitle: Text(a['message'], style: TextStyle(color: color.withOpacity(0.8))),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ));
  }
}