package com.zeticai.zetic_mlange_flutter.wrapper.core.model

import android.content.Context
import com.zeticai.mlange.core.error.ZeticMLangeException
import com.zeticai.mlange.core.model.ZeticMLangeModel
import com.zeticai.zetic_mlange_flutter.core.BaseFlutterPlugin

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import java.nio.ByteBuffer

class ZeticMLangeModelFlutterPlugin(
    flutterPluginBinding: FlutterPlugin.FlutterPluginBinding,
    channelStr: String,
    private val context: Context = flutterPluginBinding.applicationContext
) : BaseFlutterPlugin<ZeticMLangeModel>(flutterPluginBinding, channelStr) {
    private fun create(instanceId: String, tokenKey: String, modelKey: String, result: Result) {
        Thread {
            try {
                val model = ZeticMLangeModel(context, tokenKey, modelKey)
                createInstance(instanceId, model)
                result.success(null)
            } catch (e: Exception) {
                result.error(
                    "CREATE_FAIL",
                    "Failed to create ZeticMLangeModel: ${e.message}",
                    null
                )
            }
        }.start()
    }

    private fun run(instanceId: String, inputs: List<ByteArray>, result: Result) {
        val model = getInstance(instanceId, result)

        try {
            val byteBuffers = inputs.map { ByteBuffer.wrap(it) }.toTypedArray()
            model.run(byteBuffers)
            result.success(null)
        } catch (e: ZeticMLangeException) {
            result.error(
                "RUN_ERROR",
                e.message,
                null
            )
        }
    }

    private fun getOutputDataArray(instanceId: String, result: Result) {
        val model = getInstance(instanceId, result)

        val outputBuffers = model.getOutputBuffers()
        val outputList = outputBuffers.map {
            val byteArray = ByteArray(it.remaining())
            it.get(byteArray)
            byteArray
        }

        result.success(outputList)
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
        result.success(null)
    }
}