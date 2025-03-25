package com.zeticai.zetic_mlange_flutter.wrapper.feature.yolov8

import android.content.Context
import com.zeticai.mlange.core.error.ZeticMLangeException
import com.zeticai.mlange.feature.yolov8.Yolov8Wrapper
import com.zeticai.zetic_mlange_flutter.core.BaseFlutterPlugin
import com.zeticai.zetic_mlange_flutter.wrapper.feature.yolov8.YOLOResultMapper.toMap

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel.Result

class YOLOv8WrapperFlutterPlugin(
    flutterPluginBinding: FlutterPlugin.FlutterPluginBinding,
    channelStr: String,
    private val context: Context = flutterPluginBinding.applicationContext
) : BaseFlutterPlugin<Yolov8Wrapper>(flutterPluginBinding, channelStr) {
    private fun create(instanceId: String, cocoYamlFilePath: String, result: Result) {
        try {
            val wrapper = Yolov8Wrapper(cocoYamlFilePath)
            createInstance(instanceId, wrapper)
            result.success(null)
        } catch (e: Exception) {
            result.error(
                "CREATE_FAIL",
                "Failed to create YOLOv8Wrapper: ${e.message}",
                null
            )
        }
    }

    private fun preprocess(instanceId: String, frameData: ByteArray, width: Int, height: Int, formatCode: Int, result: Result) {
        val wrapper = getInstance(instanceId, result)
        try {
            val preprocessResult = wrapper.preprocessWithFrame(frameData, width, height, formatCode)
            result.success(preprocessResult)
        } catch (e: Exception) {
            result.error(
                "PRE_PROCESS_ERROR",
                "Failed to create ZeticMLangeModel: ${e.message}",
                null
            )
        }
    }

    private fun postprocess(instanceId: String, outputs: ByteArray, result: Result) {
        val wrapper = getInstance(instanceId, result)

        try {
            val yoloResult = wrapper.postprocess(outputs)
            result.success(yoloResult.toMap())
        } catch (e: ZeticMLangeException) {
            result.error(
                "POST_PROCESS_ERROR",
                e.message,
                null
            )
        }
    }

    private fun deinit(instanceId: String, result: Result) {
        removeInstance(instanceId)?.let {
            try {
                it.deinit()
            } catch (e: Exception) {
                result.error(
                    "DEINIT_ERROR",
                    e.message,
                    null
                )
            }
        }
    }
}