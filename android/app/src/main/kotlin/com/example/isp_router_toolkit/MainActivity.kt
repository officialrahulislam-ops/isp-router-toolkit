package com.example.isp_router_toolkit

import android.content.Context
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Exposes signal strength, frequency and link speed of the current Wi-Fi
 * connection to Dart. network_info_plus does not provide these.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "isp_helper/wifi")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getWifiDetails" -> {
                        try {
                            val wifiManager =
                                applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                            @Suppress("DEPRECATION")
                            val info = wifiManager.connectionInfo
                            val map = HashMap<String, Any?>()
                            map["rssi"] = info.rssi
                            map["frequency"] = info.frequency
                            map["linkSpeed"] = info.linkSpeed
                            result.success(map)
                        } catch (e: Exception) {
                            result.error("WIFI_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
