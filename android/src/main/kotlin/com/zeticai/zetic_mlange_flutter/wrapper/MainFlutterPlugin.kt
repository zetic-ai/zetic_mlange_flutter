package com.zeticai.zetic_mlange_flutter.wrapper

import android.content.Context
import com.zeticai.zetic_mlange_flutter.core.BaseFlutterPlugin
import com.zeticai.zetic_mlange_flutter.core.FlutterPluginMethodMapper
import com.zeticai.zetic_mlange_flutter.wrapper.core.model.ZeticMLangeModelFlutterPlugin
import com.zeticai.zetic_mlange_flutter.wrapper.feature.yolov8.YOLOv8WrapperFlutterPlugin

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class MainFlutterPlugin: FlutterPlugin {
    private var plugins: List<BaseFlutterPlugin<out Any>> = emptyList()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        plugins = listOf(
            ZeticMLangeModelFlutterPlugin(flutterPluginBinding, "zetic_mlange_model_plugin"),
            YOLOv8WrapperFlutterPlugin(flutterPluginBinding, "yolov8_plugin"),
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        plugins.forEach {
            it.channel.setMethodCallHandler(null)
        }
    }
}