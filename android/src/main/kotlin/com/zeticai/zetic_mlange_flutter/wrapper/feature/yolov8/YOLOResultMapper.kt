package com.zeticai.zetic_mlange_flutter.wrapper.feature.yolov8

import com.zeticai.mlange.feature.entity.Box
import com.zeticai.mlange.feature.yolov8.YoloObject
import com.zeticai.mlange.feature.yolov8.YoloResult

object YOLOResultMapper {
    fun YoloResult.toMap(): Map<String, Any> {
        return mapOf(
            "value" to value.map { it.toMap() },
        )
    }

    fun YoloObject.toMap(): Map<String, Any> {
        return mapOf(
            "classId" to classId,
            "confidence" to confidence,
            "box" to box.toMap(),
        )
    }

    fun Box.toMap(): Map<String, Any> {
        return mapOf(
            "x" to xMin,
            "y" to yMin,
            "width" to (xMax - xMin),
            "height" to (yMax - yMin),
        )
    }
}
