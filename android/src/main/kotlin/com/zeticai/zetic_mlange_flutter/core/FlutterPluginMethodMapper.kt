package com.zeticai.zetic_mlange_flutter.core

import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result;
import kotlin.reflect.KClass
import kotlin.reflect.KFunction
import kotlin.reflect.full.declaredFunctions
import kotlin.reflect.full.declaredMemberFunctions
import kotlin.reflect.full.functions
import kotlin.reflect.full.memberFunctions
import kotlin.reflect.jvm.isAccessible

open class FlutterPluginMethodMapper(
    pluginClass: KClass<*>,
) {
    private val validator = ArgumentsValidator(pluginClass)
    private val methods: Map<String, KFunction<*>> = pluginClass.memberFunctions.associate {
        it.name to it.apply {
            it.isAccessible = true
        }
    }

    fun <T> call(caller: T, call: MethodCall, result: Result) {
        val method = methods[call.method]
        if (method == null) {
            Log.d("FlutterPluginMethodMapper", "Method not found: ${call.method}")
            result.notImplemented()
            return
        }
        val args = validator.validate(call, result)

        method.call(caller, *args.toTypedArray())
    }
}