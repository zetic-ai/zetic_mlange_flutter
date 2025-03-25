import 'dart:async';
import 'dart:ffi';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class YOLOv8 {
  static const MethodChannel _channel = MethodChannel('yolov8_plugin');
  final String _instanceId;

  YOLOv8._(this._instanceId);

  static Future<YOLOv8> create(
    String cocoYamlFilePath,
  ) async {
    final instanceId = const Uuid().v4();
    await _channel.invokeMethod('create', {
      'instanceId': instanceId,
      'cocoYamlFilePath': cocoYamlFilePath,
    });
    return YOLOv8._(instanceId);
  }

  Future<Uint8List> preprocess(Uint8List frameData, int width, int height, int formatCode) async {
    return await _channel.invokeMethod('preprocess', {
      'instanceId': _instanceId,
      'frameData': frameData,
      'width': width,
      'height': height,
      'formatCode': formatCode, // 0=NV21, 1=I420, 2=NV12
    });
  }

  Future<YoloResult> postprocess(Uint8List outputs) async {
    final result = await _channel.invokeMethod('postprocess', {
      'instanceId': _instanceId,
      'outputs': outputs
    });

    if (result == null) {
      throw Exception('No data received');
    }

    final map = Map<String, dynamic>.from(result);
    return YoloResult.fromMap(map);
  }

  Future<void> deinit() async {
    await _channel.invokeMethod('deinit', {
      'instanceId': _instanceId,
    });
  }
}

class YoloResult {
  final List<YoloObject> value;

  YoloResult({required this.value});

  factory YoloResult.fromMap(Map map) {
    final Map<String, dynamic> safeMap = map.cast<String, dynamic>();
    
    final List<dynamic> yoloList = safeMap['value'] ?? [];
    return YoloResult(
      value: yoloList
          .map((obj) => YoloObject.fromMap(
              (obj is Map) ? obj.cast<String, dynamic>() : {}
          ))
          .toList(),
    );
  }
}

class YoloObject {
  final int classId;
  final double confidence;
  final BoundingBox boundingBox;
  
  YoloObject({
    required this.classId,
    required this.confidence,
    required this.boundingBox,
  });

  factory YoloObject.fromMap(Map<String, dynamic> map) {
    return YoloObject(
      classId: (map['classId'] is num) ? (map['classId'] as num).toInt() : 0,
      confidence: (map['confidence'] is num) ? (map['confidence'] as num).toDouble() : 0.0,
      boundingBox: BoundingBox.fromMap(map['box'].cast<String, dynamic>() ?? {}),
    );
  }

  @override
  String toString() {
    return '$classId (${(confidence * 100).toStringAsFixed(1)}%)';
  }
}

class BoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;

  BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory BoundingBox.fromMap(Map<String, dynamic> map) {
    return BoundingBox(
      x: (map['x'] is num) ? (map['x'] as num).toDouble() : 0.0,
      y: (map['y'] is num) ? (map['y'] as num).toDouble() : 0.0,
      width: (map['width'] is num) ? (map['width'] as num).toDouble() : 0.0,
      height: (map['height'] is num) ? (map['height'] as num).toDouble() : 0.0,
    );
  }

  @override
  String toString() {
    return 'x:$x, y:$y, w:$width, h:$height';
  }
}