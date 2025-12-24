import 'package:flutter/material.dart';

class ManualShapeEditor extends StatefulWidget {
  final List<Offset> vertices;
  final VoidCallback onChanged;

  const ManualShapeEditor({super.key, required this.vertices, required this.onChanged});

  @override
  State<ManualShapeEditor> createState() => _ManualShapeEditorState();
}

class _ManualShapeEditorState extends State<ManualShapeEditor> {
  
  void _addVertexDialog() {
    final xController = TextEditingController();
    final yController = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Add New Coordinate"),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: xController,
                decoration: const InputDecoration(labelText: "X Position (meters)"),
                keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            TextField(
                controller: yController,
                decoration: const InputDecoration(labelText: "Y Position (meters)"),
                keyboardType: TextInputType.number),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            FilledButton(
                onPressed: () {
                  double? x = double.tryParse(xController.text);
                  double? y = double.tryParse(yController.text);
                  if (x != null && y != null) {
                    widget.vertices.add(Offset(x, y));
                    widget.onChanged();
                    Navigator.pop(context);
                  }
                },
                child: const Text("Add Point"))
          ],
        ));
  }

  void _editVertexDialog(int index, Offset current) {
    final xController = TextEditingController(text: current.dx.toString());
    final yController = TextEditingController(text: current.dy.toString());
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Edit Point ${index + 1}"),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: xController,
                decoration: const InputDecoration(labelText: "X Position (meters)"),
                keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            TextField(
                controller: yController,
                decoration: const InputDecoration(labelText: "Y Position (meters)"),
                keyboardType: TextInputType.number),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            FilledButton(
                onPressed: () {
                  double? x = double.tryParse(xController.text);
                  double? y = double.tryParse(yController.text);
                  if (x != null && y != null) {
                    widget.vertices[index] = Offset(x, y);
                    widget.onChanged();
                    Navigator.pop(context);
                  }
                },
                child: const Text("Update"))
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Vertices",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
            TextButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text("Add Vertex"),
              onPressed: _addVertexDialog,
            )
          ],
        ),
        const SizedBox(height: 8),
        if (widget.vertices.isEmpty)
           const Padding(
              padding: EdgeInsets.all(32),
              child: Text("No coordinates added yet.",
                  textAlign: TextAlign.center))
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.vertices.asMap().entries.map((entry) {
                int index = entry.key;
                Offset vertex = entry.value;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200)
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Text("${index + 1}", style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary)),
                      ),
                      const SizedBox(height: 8),
                      Text("X: ${vertex.dx.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text("Y: ${vertex.dy.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => _editVertexDialog(index, vertex),
                            child: Icon(Icons.edit, size: 18, color: Colors.blueGrey.shade300),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                             onTap: () {
                              if (widget.vertices.length > 3) {
                                widget.vertices.removeAt(index);
                                widget.onChanged();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Polygon requires 3+ points"))
                                );
                              }
                            },
                            child: Icon(Icons.close, size: 18, color: Colors.red.shade300),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}