import 'package:flutter/material.dart';

import 'tile.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.light(),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  late TextEditingController _scale;
  late TextEditingController _size;
  late TextEditingController _zoom;
  late TextEditingController _xOffset;
  late TextEditingController _yOffset;
  late TextEditingController _clipOffsetX;
  late TextEditingController _clipOffsetY;
  late TextEditingController _clipSize;
  TileOptions options = TileOptions(
      size: const Size(512, 512),
      scale: 1.0,
      zoom: 15,
      xOffset: 0,
      yOffset: 0,
      clipOffsetX: 0,
      clipOffsetY: 0,
      clipSize: 0,
      renderMode: RenderMode.shader);

  @override
  void initState() {
    super.initState();
    _scale = TextEditingController(text: '${options.scale}');
    _size = TextEditingController(text: '${options.size.width}');
    _zoom = TextEditingController(text: '${options.zoom.toInt()}');
    _xOffset = TextEditingController(text: '${options.xOffset.toInt()}');
    _yOffset = TextEditingController(text: '${options.yOffset.toInt()}');
    _clipOffsetX =
        TextEditingController(text: '${options.clipOffsetX.toInt()}');
    _clipOffsetY =
        TextEditingController(text: '${options.clipOffsetY.toInt()}');
    _clipSize = TextEditingController(text: '${options.clipSize.toInt()}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Vector Tile Example"),
        ),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.all(10),
              child: Wrap(children: [
                _doubleTextField(_scale, 'Scale',
                    (value) => options.withValues(scale: value)),
                _doubleTextField(_size, 'Size',
                    (value) => options.withValues(size: Size(value, value))),
                _doubleTextField(_xOffset, 'X Offset',
                    (value) => options.withValues(xOffset: value)),
                _doubleTextField(_yOffset, 'Y Offset',
                    (value) => options.withValues(yOffset: value)),
                _doubleTextField(_clipOffsetY, 'Clip Offset X',
                    (value) => options.withValues(clipOffsetX: value)),
                _doubleTextField(_clipOffsetX, 'Clip Offset Y',
                    (value) => options.withValues(clipOffsetY: value)),
                _doubleTextField(_clipSize, 'Clip Size',
                    (value) => options.withValues(clipSize: value)),
                _doubleTextField(
                    _zoom, 'Zoom', (value) => options.withValues(zoom: value)),
              ])),
          _radio('Rendering', RenderMode.values, () => options.renderMode,
              (v) => options.withValues(renderMode: v)),
          Expanded(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [MapTile(options: options)]))
        ]));
  }

  Widget _doubleTextField(TextEditingController controller, String label,
      TileOptions Function(double) applyer) {
    return _textField(controller, label, (value) {
      final d = double.tryParse(value);
      if (d != null) {
        return applyer(d);
      }
      return null;
    });
  }

  Widget _textField(TextEditingController controller, String label,
          TileOptions? Function(String) applyer) =>
      Padding(
          padding: const EdgeInsets.only(right: 5.0),
          child: SizedBox(
              width: 100,
              child: TextField(
                  controller: controller,
                  onChanged: (value) {
                    final newOptions = applyer(value);
                    if (newOptions != null) {
                      setState(() {
                        options = newOptions;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: label,
                  ))));

  Widget _radio<T extends Enum>(String label, List<T> values,
      T Function() currentValue, TileOptions Function(T value) applyer) {
    return RadioGroup<T>(
      groupValue: currentValue(),
      onChanged: (T? value) {
        if (value != null) {
          setState(() {
            options = applyer(value);
          });
        }
      },
      child: Wrap(
          children: values
              .map((v) => SizedBox(
                  width: 150,
                  child: ListTile(
                    title: Text(v.name),
                    leading: Radio<T>(
                      value: v,
                    ),
                  )))
              .toList()),
    );
  }
}
