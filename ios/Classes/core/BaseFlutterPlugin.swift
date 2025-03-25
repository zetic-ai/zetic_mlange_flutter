import Flutter

open class BaseFlutterPlugin {
    public let channel: FlutterMethodChannel

    public init(registrar: FlutterPluginRegistrar, channelName: String) {
        self.channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        self.channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            self.onMethodCall(call, result)
        }
    }

    open func onMethodCall(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        result(FlutterMethodNotImplemented)
    }
}
