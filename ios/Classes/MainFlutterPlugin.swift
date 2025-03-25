import Flutter
import UIKit

public class MainFlutterPlugin: NSObject, FlutterPlugin {
    private var plugins: [BaseFlutterPlugin] = []
    static var instance: MainFlutterPlugin?

    public static func register(with registrar: FlutterPluginRegistrar) {
        instance = MainFlutterPlugin()
        instance?.onAttachedToEngine(registrar: registrar)
    }

    private func onAttachedToEngine(registrar: FlutterPluginRegistrar) {
        plugins = [
            ZeticMLangeModelFlutterPlugin(
                registrar: registrar,
                channelName: "zetic_mlange_model_plugin"
            ),

            YOLOv8WrapperFlutterPlugin(
                registrar: registrar,
                channelName: "yolov8_plugin"
            )
        ]
    }

    deinit {
        for plugin in plugins {
            plugin.channel.setMethodCallHandler(nil)
        }
    }
}
