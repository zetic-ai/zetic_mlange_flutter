import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'dart:ui' as ui;

import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/services.dart';
import 'package:zetic_mlange_flutter/zetic_mlange_model.dart';
import 'package:zetic_mlange_flutter/yolov8.dart';

import 'package:camera/camera.dart';
import 'package:yaml/yaml.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late CameraController _cameraController;
  // Initialize with a completed future to avoid late initialization error
  Future<void> _initializeControllerFuture = Future.value();
  late YOLOv8 yolov8;
  late ZeticMLangeModel model;
  String _runLog = 'Initializing...';
  bool _cameraInitialized = false;
  List<YoloObject> _detectedObjects = [];
  List<String> classes = [];
  String cocoYaml = '''# Ultralytics YOLO 🚀, AGPL-3.0 license
# COCO 2017 dataset https://cocodataset.org by Microsoft
# Documentation: https://docs.ultralytics.com/datasets/detect/coco/
# Example usage: yolo train data=coco.yaml
# parent
# ├── ultralytics
# └── datasets
#     └── coco  ← downloads here (20.1 GB)

# Train/val/test sets as 1) dir: path/to/imgs, 2) file: path/to/imgs.txt, or 3) list: [path/to/imgs1, path/to/imgs2, ..]
path: ../datasets/coco # dataset root dir
train: train2017.txt # train images (relative to 'path') 118287 images
val: val2017.txt # val images (relative to 'path') 5000 images
test: test-dev2017.txt # 20288 of 40670 images, submit to https://competitions.codalab.org/competitions/20794

# Classes
names:
  0: person
  1: bicycle
  2: car
  3: motorcycle
  4: airplane
  5: bus
  6: train
  7: truck
  8: boat
  9: traffic light
  10: fire hydrant
  11: stop sign
  12: parking meter
  13: bench
  14: bird
  15: cat
  16: dog
  17: horse
  18: sheep
  19: cow
  20: elephant
  21: bear
  22: zebra
  23: giraffe
  24: backpack
  25: umbrella
  26: handbag
  27: tie
  28: suitcase
  29: frisbee
  30: skis
  31: snowboard
  32: sports ball
  33: kite
  34: baseball bat
  35: baseball glove
  36: skateboard
  37: surfboard
  38: tennis racket
  39: bottle
  40: wine glass
  41: cup
  42: fork
  43: knife
  44: spoon
  45: bowl
  46: banana
  47: apple
  48: sandwich
  49: orange
  50: broccoli
  51: carrot
  52: hot dog
  53: pizza
  54: donut
  55: cake
  56: chair
  57: couch
  58: potted plant
  59: bed
  60: dining table
  61: toilet
  62: tv
  63: laptop
  64: mouse
  65: remote
  66: keyboard
  67: cell phone
  68: microwave
  69: oven
  70: toaster
  71: sink
  72: refrigerator
  73: book
  74: clock
  75: vase
  76: scissors
  77: teddy bear
  78: hair drier
  79: toothbrush

# Download script/URL (optional)
download: |
  from ultralytics.utils.downloads import download
  from pathlib import Path

  # Download labels
  segments = True  # segment or box labels
  dir = Path(yaml['path'])  # dataset root dir
  url = 'https://github.com/ultralytics/assets/releases/download/v0.0.0/'
  urls = [url + ('coco2017labels-segments.zip' if segments else 'coco2017labels.zip')]  # labels
  download(urls, dir=dir.parent)
  # Download data
  urls = ['http://images.cocodataset.org/zips/train2017.zip',  # 19G, 118k images
          'http://images.cocodataset.org/zips/val2017.zip',  # 1G, 5k images
          'http://images.cocodataset.org/zips/test2017.zip']  # 7G, 41k images (optional)
  download(urls, dir=dir / 'images', threads=3)''';

  @override
  void initState() {
    super.initState();
    _setupApp();
  }

  Future<void> _setupApp() async {
    // Wrap all initialization in a single function for better error handling
    try {
      await initModel();
      await initYOLOv8();
      await _initCamera();
    } catch (e, st) {
      setState(() {
        _runLog = 'Setup error: $e\n$st';
      });
    }
  }

  Future<void> initYOLOv8() async {
    try {
      setState(() {
        _runLog = 'Initializing YOLOv8...';
      });
      final path = await createFileAndGetPath();
      classes = parseYamlToClassList(cocoYaml);
      yolov8 = await YOLOv8.create(path);
      setState(() {
        _runLog = 'YOLOv8 initialized successfully';
      });
    } on PlatformException catch (e) {
      setState(() {
        _runLog = 'Error during yolov8 init/run: ${e.message}';
      });
    } catch (e, st) {
      setState(() {
        _runLog = 'YOLOv8 error: $e\n$st';
      });
    }
  }

  Future<void> initModel() async {
    try {
      setState(() {
        _runLog = 'Initializing Model...';
      });
      model = await ZeticMLangeModel.create(
        'ztp_97aT0F0HtHQ5Q3dasRCIAoxKH0O0YKJUyvOB',
        'b9f5d74e6f644288a32c50174ded828e',
      );
      setState(() {
        _runLog = 'Model initialized successfully';
      });
    } on PlatformException catch (e) {
      setState(() {
        _runLog = 'Error during model init/run: ${e.message}';
      });
    } catch (e, st) {
      setState(() {
        _runLog = 'Model error: $e\n$st';
      });
    }
  }

  Future<void> _initCamera() async {
    try {
      setState(() {
        _runLog = 'Initializing camera...';
      });

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _runLog = 'No cameras available';
        });
        return;
      }

      final camera = cameras.first;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      // Assign future before awaiting to avoid the late initialization error
      _initializeControllerFuture = _cameraController.initialize();
      await _initializeControllerFuture;

      setState(() {
        _cameraInitialized = true;
        _runLog = 'Camera initialized, starting stream...';
      });

      _cameraController.startImageStream((CameraImage image) async {
        try {
          final data = await _preprocess(image);
          await model.run([data]);
          final modelOutput = await model.getOutputDataArray();
          final yoloOutput = await _postprocess(modelOutput[0]);

          if (mounted) {
            // Format YoloObject list in a more readable way
            final detections = yoloOutput.value;
            String formattedLog = '';

            if (detections.isEmpty) {
              formattedLog = 'No objects detected';
            } else {
              for (int i = 0; i < detections.length; i++) {
                final detection = detections[i];
                formattedLog +=
                    '${i + 1}. ${classes[detection.classId]} (${(detection.confidence * 100).toStringAsFixed(1)}%) - ${detection.boundingBox}\n';
              }
            }

            setState(() {
              _runLog = formattedLog;
              _detectedObjects = detections;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _runLog = 'Stream processing error: $e';
            });
          }
        }
      });
    } catch (e, st) {
      setState(() {
        _runLog = 'Camera initialization error: $e\n$st';
      });
    }
  }

  /// CameraImage -> byte array + format code
  Future<Uint8List> _preprocess(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final planeCount = image.planes.length;

    late Uint8List bytes;
    late int formatCode;
    if (Theme.of(context).platform == TargetPlatform.android) {
      if (planeCount == 1 || planeCount == 2) {
        bytes = _concatenateNV21(image);
        formatCode = 0;
      } else if (planeCount == 3) {
        bytes = _assembleYUV420toI420(image);
        formatCode = 1;
      } else {
        throw Exception('Unsupported plane count: $planeCount');
      }
    } else {
      if (planeCount == 2) {
        bytes = _concatenateNV12(image);
        formatCode = 2;
      } else if (planeCount == 1) {
        // bgra8888
        bytes = image.planes[0].bytes;
        formatCode = 3;
      } else {
        throw Exception('Unsupported plane count: $planeCount');
      }
    }

    return yolov8.preprocess(
      bytes,
      width,
      height,
      formatCode, // 0=NV21, 1=I420, 2=NV12
    );
  }

  Future<YoloResult> _postprocess(Uint8List modelOutput) {
    return yolov8.postprocess(modelOutput);
  }

  Uint8List convertNV12ToRGB(Uint8List nv12Data, int width, int height) {
    final rgbSize = width * height * 3;
    final rgbBytes = Uint8List(rgbSize);

    final uvStart = width * height;

    const double c1 = 1.164;
    const double c2 = 1.596;
    const double c3 = -0.813;
    const double c4 = -0.392;
    const double c5 = 2.017;
    const double yShift = 16.0;
    const double uvShift = 128.0;

    int rgbIndex = 0;

    for (int row = 0; row < height; row++) {
      final uvRow = (row >> 1);

      for (int col = 0; col < width; col++) {
        final yIndex = row * width + col;
        final Y = nv12Data[yIndex];

        final uvIndex = uvStart + (uvRow * width) + (col & ~1);
        final U = nv12Data[uvIndex];
        final V = nv12Data[uvIndex + 1];

        double yVal = c1 * (Y - yShift);
        double rVal = yVal + c2 * (V - uvShift);
        double gVal = yVal + c3 * (V - uvShift) + c4 * (U - uvShift);
        double bVal = yVal + c5 * (U - uvShift);

        int r = rVal < 0 ? 0 : (rVal > 255 ? 255 : rVal.toInt());
        int g = gVal < 0 ? 0 : (gVal > 255 ? 255 : gVal.toInt());
        int b = bVal < 0 ? 0 : (bVal > 255 ? 255 : bVal.toInt());

        rgbBytes[rgbIndex] = r;
        rgbBytes[rgbIndex + 1] = g;
        rgbBytes[rgbIndex + 2] = b;

        rgbIndex += 3;
      }
    }

    return rgbBytes;
  }

  Uint8List _concatenateNV21(CameraImage image) {
    final allBytes = BytesBuilder();
    for (final plane in image.planes) {
      allBytes.add(plane.bytes);
    }
    return allBytes.toBytes();
  }

  Uint8List _assembleYUV420toI420(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final planeY = image.planes[0];
    final planeU = image.planes[1];
    final planeV = image.planes[2];

    // Calculate plane sizes
    final ySize = width * height;
    final uSize = width * height ~/ 4;
    final vSize = uSize;

    // Create properly sized I420 buffer
    final i420 = Uint8List(ySize + uSize + vSize);

    // Copy Y plane - taking stride into account
    int yOffset = 0;
    for (int row = 0; row < height; row++) {
      final rowStartY = row * planeY.bytesPerRow;
      final rowLength = width; // Only copy width bytes per row
      i420.setRange(yOffset, yOffset + rowLength, planeY.bytes, rowStartY);
      yOffset += width; // Move to next row in output (no padding)
    }

    // Copy U plane - handle stride and possibly subsampling
    int uOffset = ySize;
    final uHeight = height ~/ 2;
    final uWidth = width ~/ 2;
    for (int row = 0; row < uHeight; row++) {
      final rowStartU = row * planeU.bytesPerRow;
      final rowLength = uWidth; // Only copy uWidth bytes per row
      i420.setRange(uOffset, uOffset + rowLength, planeU.bytes, rowStartU);
      uOffset += uWidth; // Move to next row in output
    }

    // Copy V plane - handle stride and possibly subsampling
    int vOffset = ySize + uSize;
    final vHeight = height ~/ 2;
    final vWidth = width ~/ 2;
    for (int row = 0; row < vHeight; row++) {
      final rowStartV = row * planeV.bytesPerRow;
      final rowLength = vWidth; // Only copy vWidth bytes per row
      i420.setRange(vOffset, vOffset + rowLength, planeV.bytes, rowStartV);
      vOffset += vWidth; // Move to next row in output
    }

    return i420;
  }

  Uint8List _concatenateNV12(CameraImage image) {
    final planeY = image.planes[0];
    final planeUV = image.planes[1];
    final width = image.width;
    final height = image.height;

    final ySize = width * height;
    final uvSize = width * height ~/ 2;
    final nv12 = Uint8List(ySize + uvSize);

    int index = 0;
    for (int row = 0; row < height; row++) {
      final rowOffset = row * planeY.bytesPerRow;
      nv12.setRange(index, index + width, planeY.bytes, rowOffset);
      index += width;
    }

    // UV
    for (int row = 0; row < height ~/ 2; row++) {
      final rowOffset = row * planeUV.bytesPerRow;
      nv12.setRange(index, index + width, planeUV.bytes, rowOffset);
      index += width;
    }

    return nv12;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            // Camera preview or loading indicator
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    _cameraInitialized) {
                  final aspectRatio = _cameraController.value.aspectRatio;
                  return Align(
                    alignment:
                        Alignment
                            .topCenter, // Align the camera preview to the top
                    child: AspectRatio(
                      aspectRatio:
                          1 / aspectRatio, // Ensures correct aspect ratio
                      child: CameraPreview(_cameraController),
                    ),
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),

            // Bounding boxes overlay
            if (_detectedObjects.isNotEmpty && _cameraInitialized)
              CustomPaint(
                painter: BoundingBoxPainter(
                  detectedObjects: _detectedObjects,
                  aspectRatio: _cameraController.value.aspectRatio,
                  screenSize: MediaQuery.of(context).size,
                  classes: classes,
                ),
              ),

            // Log display overlay at the bottom of the screen
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12.0),
                color: Colors.black.withOpacity(0.7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Detection Results:",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _runLog,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      // Increase max lines to show more detection results
                      maxLines: 15,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up resources
    _cameraController.dispose();
    super.dispose();
  }

  List<String> parseYamlToClassList(String yamlString) {
    try {
      final yaml = loadYaml(yamlString);

      if (yaml is! YamlMap) {
        print('Warning: Root YAML element is not a map');
        return [];
      }

      final YamlMap yamlMap = yaml;

      // Check for YOLO-specific "names" key
      if (yamlMap.containsKey('names')) {
        final namesSection = yamlMap['names'];

        if (namesSection is YamlMap) {
          // Sort by key (which is the class ID) to maintain order
          final sortedKeys =
              namesSection.keys.toList()..sort((a, b) {
                // Convert keys to integers for proper numerical sorting
                int aInt = int.tryParse(a.toString()) ?? 0;
                int bInt = int.tryParse(b.toString()) ?? 0;
                return aInt.compareTo(bInt);
              });

          // Extract class names in order
          return sortedKeys.map((key) => namesSection[key].toString()).toList();
        }
      }

      // Fallback to generic extraction if not in YOLO format
      return [];
    } catch (e) {
      print('Error extracting YOLO classes from YAML: $e');
      return [];
    }
  }

  Future<String> createFileAndGetPath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      final filePath = '${directory.path}/coco.yaml';
      final file = File(filePath);

      await file.writeAsString(cocoYaml);

      return file.path;
    } catch (e) {
      print('Error creating file: $e');
      return '';
    }
  }
}

// Custom painter for drawing bounding boxes
class BoundingBoxPainter extends CustomPainter {
  final List<YoloObject> detectedObjects;
  final double aspectRatio; // Use aspectRatio instead of previewSize
  final Size screenSize;
  final List<String> classes;

  BoundingBoxPainter({
    required this.detectedObjects,
    required this.aspectRatio, // Add aspectRatio as a parameter
    required this.screenSize,
    required this.classes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = screenSize.width;
    final double scaleY = screenSize.width / aspectRatio;

    for (final object in detectedObjects) {
      // Only draw boxes for objects with confidence > 0.5
      if (object.confidence < 0.5) continue;

      // Get colors based on class
      final color = Color(0xFF000000);

      // Calculate scaled coordinates
      final rect = ui.Rect.fromLTWH(
        object.boundingBox.x / aspectRatio,
        object.boundingBox.y / aspectRatio,
        object.boundingBox.width / aspectRatio,
        object.boundingBox.height / aspectRatio,
      );

      // Draw rectangle
      final paint =
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;

      canvas.drawRect(rect, paint);

      // Draw label background
      final textSpan = TextSpan(
        text:
            ' ${classes[object.classId]} ${(object.confidence * 100).toStringAsFixed(0)}% ',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final backgroundRect = ui.Rect.fromLTWH(
        rect.left,
        rect.top - textPainter.height,
        textPainter.width,
        textPainter.height,
      );

      final backgroundPaint =
          Paint()
            ..color = color
            ..style = PaintingStyle.fill;

      canvas.drawRect(backgroundRect, backgroundPaint);

      // Draw label text
      textPainter.paint(
        canvas,
        Offset(rect.left, rect.top - textPainter.height),
      );
    }
  }

  @override
  bool shouldRepaint(BoundingBoxPainter oldDelegate) {
    return oldDelegate.detectedObjects != detectedObjects;
  }
}
