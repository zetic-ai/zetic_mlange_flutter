import Flutter

open class MultipleInstances<T> {
    private var instances = [String: T]()

    open func createInstance(instanceId: String, instance: T) {
        instances[instanceId] = instance
    }

    open func removeInstance(instanceId: String) -> T? {
        return instances.removeValue(forKey: instanceId)
    }

    open func getInstance(instanceId: String, result: FlutterResult) -> T {
        guard let instance = instances[instanceId] else {
            result(
                FlutterError(
                    code: "NO_INSTANCE",
                    message: "Instance not created yet",
                    details: nil
                )
            )
            fatalError("Instance not created yet")
        }
        return instance
    }
}
