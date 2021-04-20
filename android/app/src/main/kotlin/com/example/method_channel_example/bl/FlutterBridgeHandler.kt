package com.example.method_channel_example.bl

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger

interface FlutterBridgeHandler {
    fun getBinaryMessenger(): BinaryMessenger?
    fun getContext(): Context?
}