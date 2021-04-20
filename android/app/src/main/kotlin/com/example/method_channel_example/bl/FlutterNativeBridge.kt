package com.example.method_channel_example.bl

import android.util.Log
import com.example.method_channel_example.common.ChannelCallback
import com.example.method_channel_example.common.Constants
import com.example.method_channel_example.dl.Repository
import com.example.method_channel_example.utils.AppLogger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class FlutterNativeBridge(): MethodChannel.MethodCallHandler {
    private var _repo: Repository? = null
    private val repository: Repository get () {
        if (_repo == null) {
            _repo = Repository(flutterBridgeHandler.getContext()!!.applicationContext)
        }

        return _repo!!
    }

    @Suppress("NO_REFLECTION_IN_CLASS_PATH")
    private val TAG: String = FlutterNativeBridge::class.simpleName.toString()
    private val CHANNEL_NAME: String = "com.example.MethodChannelDemo/native_channel"

    private lateinit var flutterBridgeHandler: FlutterBridgeHandler
    private lateinit var methodChannel: MethodChannel
    constructor(flutterBridgeHandler: FlutterBridgeHandler) : this() {
        this.flutterBridgeHandler = flutterBridgeHandler
        flutterBridgeHandler.getBinaryMessenger()?.let {
            methodChannel = MethodChannel(it, CHANNEL_NAME)
        }
        // [Android] method channel works now in both directions
        methodChannel.setMethodCallHandler { call, result ->
            onMethodCall(call, result)
        }
    }

    fun callFlutter(methodName: String, args: Any? = null, callback: ChannelCallback? = null) {
        callback?.let {
            methodChannel.invokeMethod(methodName, args, it)
        } ?: run {
            methodChannel.invokeMethod(methodName, args)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        //TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
//        AppLogger.log(this, "called native bridge: ${call.method}(${call.arguments})")

        // Nullify in case the result will be called asynchronously
        var nativeChannelResult: Any? = Constants.Keys.FlutterMethodChannel.FAILURE_RESULT

        when (call.method) {
            "save_in_secured_storage" -> {
                nativeChannelResult = Constants.Keys.FlutterMethodChannel.FAILURE_RESULT
                //call.argument<String>("your custom key")
                nativeChannelResult = if (call.arguments is HashMap<*, *>) {
                    val args: HashMap<*, *> = call.arguments as HashMap<*, *>
                    securelySaveAllKeysAndValues(args)
                    Constants.Keys.FlutterMethodChannel.SUCCESS_RESULT
                } else {
                    Constants.Keys.FlutterMethodChannel.FAILURE_RESULT
                    AppLogger.error(TAG, "Missing call arguments in ${call.method}!")
                }
            }

            "load_from_secured_storage" -> {
                nativeChannelResult = Constants.Keys.FlutterMethodChannel.FAILURE_RESULT
//                val keyString = call.argument<String>(Constants.Keys.FlutterMethodChannel.DATA_KEY) ?: ""
//                val defaultValue = call.argument<String>(Constants.Keys.FlutterMethodChannel.DATA_VALUE)

//                if (keyString.isEmpty()) {
//                    nativeChannelResult = "" // Strings.empty ?
//                } else {
                call.arguments?.let { args ->
                    if (args is HashMap<*, *>) {
                        val keyString = args.entries.firstOrNull()?.key?.toString() ?: ""
                        val defaultValue = args.entries.firstOrNull()?.value?.toString() ?: ""
                        val loadedValue = repository.loadSecuredString(keyString, defaultValue)

                        nativeChannelResult = loadedValue
                    }
                } ?: run {
//                    AppLogger.error(TAG, "Missing call arguments in ${call.method}!")
                }
//                }
            }
            else -> {
                //AppLogger.error(TAG, "Missing handling for method channel named: " + call.method)
                nativeChannelResult = Constants.Keys.FlutterMethodChannel.FAILURE_RESULT
            }
        }

        nativeChannelResult?.let {
            result.success(nativeChannelResult)
        } // Otherwise it will be on the callback's responsibility
    }

    /**
     * Save all keys and values to Android's shared preferences
     */
    private fun securelySaveAllKeysAndValues(valuesToSave: HashMap<*, *>) {
        valuesToSave.entries.forEach { entry ->
            repository.storeSecuredString(entry.key.toString(), entry.value.toString())
        }
    }

}