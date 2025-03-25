import Flutter
import UIKit
import ZeticMLange

public class YOLOv8WrapperFlutterPlugin: BaseFlutterPlugin {
    let instances = MultipleInstances<YOLOv8Wrapper>()
    
    public override func onMethodCall(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        switch call.method {
        case "create":
            guard
                let args = call.arguments as? [String: Any],
                let instanceId = args["instanceId"] as? String,
                let cocoYamlFilePath = args["cocoYamlFilePath"] as? String
            else {
                result(FlutterError(code: "ARGUMENT_ERROR", message: "Invalid arguments for create()", details: nil))
                return
            }
            create(instanceId: instanceId, cocoYamlFilePath: cocoYamlFilePath, result: result)
            
        case "preprocess":
            guard
                let args = call.arguments as? [String: Any],
                let instanceId = args["instanceId"] as? String,
                let frameData = args["frameData"] as? FlutterStandardTypedData,
                let width = args["width"] as? Int,
                let height = args["height"] as? Int,
                let formatCode = args["formatCode"] as? Int
            else {
                result(FlutterError(code: "ARGUMENT_ERROR", message: "Invalid arguments for preprocess()", details: nil))
                return
            }
            preprocess(instanceId: instanceId, bytes: frameData, width: width, height: height, formatCode: formatCode, result: result)
            
        case "postprocess":
            guard
                let args = call.arguments as? [String: Any],
                let instanceId = args["instanceId"] as? String,
                let outputs = args["outputs"] as? FlutterStandardTypedData
            else {
                result(FlutterError(code: "ARGUMENT_ERROR",
                                    message: "Invalid arguments for postprocess()",
                                    details: nil))
                return
            }
            postprocess(instanceId: instanceId, outputs: outputs, result: result)
            
        case "deinit":
            guard
                let args = call.arguments as? [String: Any],
                let instanceId = args["instanceId"] as? String
            else {
                result(FlutterError(code: "ARGUMENT_ERROR", message: "Invalid arguments for deinit()", details: nil))
                return
            }
            deinitInstance(instanceId: instanceId, result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func create(instanceId: String, cocoYamlFilePath: String, result: FlutterResult) {
        do {
            let wrapper = YOLOv8Wrapper(cocoYamlFilePath)
            instances.createInstance(instanceId: instanceId, instance: wrapper)
            result(nil)
        } catch {
            result(
                FlutterError(
                    code: "CREATE_FAIL",
                    message: "Failed to create YOLOv8Wrapper: \(error.localizedDescription)",
                    details: nil
                )
            )
        }
    }

    private func preprocess(instanceId: String, bytes: FlutterStandardTypedData, width: Int, height: Int, formatCode: Int, result: FlutterResult) {
        let wrapper = instances.getInstance(instanceId: instanceId, result: result)
        
        var data = bytes.data
        
        data.withUnsafeMutableBytes { rawBufferPointer in
            guard let baseAddress = rawBufferPointer.assumingMemoryBound(to: UInt8.self).baseAddress else {
                result(
                    FlutterError(
                        code: "POST_PROCESS_ERROR",
                        message: "Failed to get pointer from outputs data.",
                        details: nil
                    )
                )
                return
            }
            
            let preprocessResult = wrapper.featurePreprocessWithFrame(baseAddress, width, height, formatCode)
            result(preprocessResult)
        }
    }
    
    private func postprocess(instanceId: String, outputs: FlutterStandardTypedData, result: FlutterResult) {
        let wrapper = instances.getInstance(instanceId: instanceId, result: result)

        var data = outputs.data
        
        data.withUnsafeMutableBytes { bufferPtr in
            guard let baseAddress = bufferPtr.assumingMemoryBound(to: UInt8.self).baseAddress else {
                result(
                    FlutterError(
                        code: "POST_PROCESS_ERROR",
                        message: "Failed to get pointer from outputs data.",
                        details: nil
                    )
                )
                return
            }
            
            let results = wrapper.featurePostprocess(baseAddress)
            
            if results.count > 0 {

                print(results[0].classId)
                print(results[0].confidence)
            }

            let mappedResults = YOLOv8ResultMapper.toMap(results)
            result(mappedResults)
        }
    }

    private func deinitInstance(instanceId: String, result: FlutterResult) {
        if let wrapper = instances.removeInstance(instanceId: instanceId) {
        }
        result(nil)
    }
}
