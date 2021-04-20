package com.example.method_channel_example

import android.os.Bundle
import android.os.PersistableBundle
import com.example.method_channel_example.bl.FlutterBridgeHandler
import com.example.method_channel_example.bl.FlutterNativeBridge
import com.example.method_channel_example.common.ChannelCallback
import com.example.method_channel_example.utils.AppLogger
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.BinaryMessenger

class MainActivity: FlutterActivity(), FlutterBridgeHandler {
    private var methodHandler: FlutterNativeBridge? = null

    override fun onCreate(savedInstanceState: Bundle?, persistentState: PersistableBundle?) {
        super.onCreate(savedInstanceState, persistentState)
        onCreate()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        onCreate()
    }

    private fun onCreate() {
        methodHandler = FlutterNativeBridge(this)
    }

    override fun onResume() {
        super.onResume()

        callFlutter("flutter_is_presented", callback = object : ChannelCallback() {
            override fun onResult(result: Any?) {
                AppLogger.log(result)
            }
        })
    }
    fun callFlutter(methodName: String, args: Any? = null, callback: ChannelCallback) {
        methodHandler?.callFlutter(methodName, args, callback)
    }

    override fun getBinaryMessenger(): BinaryMessenger? {
        return flutterEngine?.dartExecutor?.binaryMessenger
    }
}
