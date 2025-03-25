import Flutter
import UIKit
import ZeticMLange

public class ZeticMLangeModelFlutterPlugin: BaseFlutterPlugin {
    let instances = MultipleInstances<ZeticMLangeModel>()
    
    public override func onMethodCall(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        switch call.method {
        case "create":
            guard
                let args = call.arguments as? [String: Any],
                let instanceId = args["instanceId"] as? String,
                let tokenKey = args["tokenKey"] as? String,
                let modelKey = args["modelKey"] as? String
            else {
                result(FlutterError(code: "ARGUMENT_ERROR", message: "Invalid arguments for create", details: nil))
                return
            }
            create(instanceId: instanceId, tokenKey: tokenKey, modelKey: modelKey, result: result)
            
        case "run":
            guard
                let args = call.arguments as? [String: Any],
                let instanceId = args["instanceId"] as? String,
                let inputData = args["inputs"] as? [FlutterStandardTypedData]
            else {
                result(FlutterError(code: "ARGUMENT_ERROR", message: "Invalid arguments for run", details: nil))
                return
            }
            run(instanceId: instanceId, inputs: inputData, result: result)

        case "getOutputDataArray":
            guard
                let args = call.arguments as? [String: Any],
                let instanceId = args["instanceId"] as? String
            else {
                result(FlutterError(code: "ARGUMENT_ERROR", message: "Invalid arguments for getOutputDataArray", details: nil))
                return
            }
            getOutputDataArray(instanceId: instanceId, result: result)
            
        case "deinit":
            guard
                let args = call.arguments as? [String: Any],
                let instanceId = args["instanceId"] as? String
            else {
                result(FlutterError(code: "ARGUMENT_ERROR", message: "Invalid arguments for deinit", details: nil))
                return
            }
            _deinit(instanceId: instanceId, result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func create(instanceId: String, tokenKey: String, modelKey: String, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .background).async {
            do {
                let model = try ZeticMLangeModel(throws: tokenKey, throws: modelKey)
                
                self.instances.createInstance(instanceId: instanceId, instance: model)
                
                DispatchQueue.main.async {
                    result(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    result(
                        FlutterError(
                            code: "CREATE_FAIL",
                            message: "Failed to create ZeticMLangeModel: \(error.localizedDescription)",
                            details: nil
                        )
                    )
                }
            }
        }
    }

    func run(instanceId: String, inputs: [FlutterStandardTypedData], result: @escaping FlutterResult) {
        let model = instances.getInstance(instanceId: instanceId, result: result)
        do {
            let dataInputs = inputs.map { $0.data }
            try model.run(dataInputs)
            result(nil)
        } catch let e as ZeticMLangeError {
            result(FlutterError(
                code: "RUN_ERROR",
                message: e.localizedDescription,
                details: nil
            ))
        } catch {
            result(FlutterError(
                code: "RUN_ERROR",
                message: error.localizedDescription,
                details: nil
            ))
        }
    }

    func getOutputDataArray(instanceId: String, result: @escaping FlutterResult) {
        let model = instances.getInstance(instanceId: instanceId, result: result)
        let outputBuffers: [Data] = model.getOutputDataArray()
        let outputList: [FlutterStandardTypedData] = outputBuffers.map { FlutterStandardTypedData(bytes: $0) }
    
        result(outputList)
    }

    func _deinit(instanceId: String, result: @escaping FlutterResult) {
        instances.removeInstance(instanceId: instanceId)
        result(nil)
    }
}
