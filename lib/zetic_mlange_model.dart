import 'dart:async';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class ZeticMLangeModel {
  static const MethodChannel _channel = MethodChannel('zetic_mlange_model_plugin');
  final String _instanceId;

  ZeticMLangeModel._(this._instanceId);

  static Future<ZeticMLangeModel> create(
    String tokenKey,
    String modelKey,
  ) async {
    final instanceId = const Uuid().v4();
    await _channel.invokeMethod('create', {
      'instanceId': instanceId,
      'tokenKey': tokenKey,
      'modelKey': modelKey,
    });
    return ZeticMLangeModel._(instanceId);
  }

  Future<void> run(List<Uint8List> inputs) async {
    await _channel.invokeMethod('run', {
      'instanceId': _instanceId,
      'inputs': inputs,
    });
  }

  Future<List<Uint8List>> getOutputDataArray() async {
    final result = await _channel.invokeMethod('getOutputDataArray', {
      'instanceId': _instanceId,
    });
    if (result is List) {
      return result.cast<Uint8List>();
    }
    return [];
  }

  Future<void> deinit() async {
    await _channel.invokeMethod('deinit', {
      'instanceId': _instanceId,
    });
  }
}
