package com.daira.circles

import android.content.Context
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Country of the mobile network (or SIM) to suggest the currency. No permission needed.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "daira/device").setMethodCallHandler { call, result ->
            if (call.method == "country") {
                val telephony = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
                val iso = listOf(telephony?.networkCountryIso, telephony?.simCountryIso)
                    .firstOrNull { it != null && it.length == 2 }
                result.success(iso?.uppercase())
            } else {
                result.notImplemented()
            }
        }
    }
}
