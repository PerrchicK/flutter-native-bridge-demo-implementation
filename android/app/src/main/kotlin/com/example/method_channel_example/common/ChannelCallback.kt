package com.example.method_channel_example.common

import com.example.method_channel_example.utils.AppLogger
import io.flutter.plugin.common.MethodChannel

abstract class ChannelCallback(/*var methodName: String*/) : MethodChannel.Result {
    abstract fun onResult(result: Any?)

    override fun success(status: Any?) {
        onResult(status)
    }

    override fun error(errorMessage: String, var2: String?, var3: Any?) {
        //AppLogger.error(this, "Error on method '$methodName' not implemented. Error message: $errorMessage")
        onResult(null)
    }

    override fun notImplemented() {
        //AppLogger.error(this, "Method '$methodName' not implemented")
        onResult(null)
    }
}
