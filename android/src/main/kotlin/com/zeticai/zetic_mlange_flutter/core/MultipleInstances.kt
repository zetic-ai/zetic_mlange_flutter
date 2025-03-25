package com.zeticai.zetic_mlange_flutter.core

import io.flutter.plugin.common.MethodChannel.Result

abstract class MultipleInstances<T> {
    private val instances: MutableMap<String, T> = mutableMapOf()

    protected fun createInstance(instanceId: String, instance: T) {
        instances[instanceId] = instance
    }

    protected fun removeInstance(instanceId: String): T? {
        return instances.remove(instanceId)
    }

    protected fun getInstance(instanceId: String, result: Result): T {
        val instance = instances[instanceId]
        if (instance == null) {
            result.error(
                "NO_INSTANCE",
                "Instance not created yet",
                null
            )
            throw IllegalArgumentException("Instance not created yet")
        }
        return instance
    }
}