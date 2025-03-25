package com.zeticai.zetic_mlange_flutter.core

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

open class BaseFlutterPlugin<T>(
    flutterPluginBinding: FlutterPlugin.FlutterPluginBinding,
    channelStr: String,
): MultipleInstances<T>() {
    val channel: MethodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, channelStr)
    private val methodMapper = FlutterPluginMethodMapper(this::class)

    init {
        channel.setMethodCallHandler { call, result ->
            onMethodCall(call, result)
        }
    }

    fun onMethodCall(call: MethodCall, result: Result) {
        methodMapper.call(this, call, result)
    }
}