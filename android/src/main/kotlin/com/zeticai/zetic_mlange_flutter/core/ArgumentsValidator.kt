package com.zeticai.zetic_mlange_flutter.core

import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import kotlin.reflect.KClass
import kotlin.reflect.KParameter
import kotlin.reflect.full.memberFunctions

class ArgumentsValidator(pluginClass: KClass<*>) {
    // method name to KParameters
    private val parameters: Map<String, List<KParameter>> = pluginClass.memberFunctions.associate { function ->
        function.name to function.parameters.filter { it.name != null }
    }

    fun validate(call: MethodCall, result: Result): List<Any> {
        val args = call.arguments as? Map<String, Any>
        if (args == null) {
            result.error(
                "INVALID_ARGS",
                "Arguments are not provided properly ${call.arguments}",
                null
            )
            throw IllegalArgumentException("Arguments are not provided properly")
        }

        if (call.method !in parameters) {
            result.error(
                "INVALID_ARGS",
                "Invalid method: ${call.method}",
                null
            )
            throw IllegalArgumentException("Invalid method: ${call.method}")
        }

        return parameters[call.method]!!.mapNotNull { parameter ->
            if (parameter.name == "instance")
                null
            else if (parameter.type.classifier == Result::class)
                result
            else if (args[parameter.name] == null) {
                result.error(
                    "INVALID_ARGS",
                    "Missing argument: ${parameter.name}",
                    null
                )
                throw IllegalArgumentException("Invalid argument: ${parameter.name}")
            }
            else
                args[parameter.name]!!
        }
    }
}