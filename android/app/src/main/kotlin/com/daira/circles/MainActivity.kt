package com.daira.circles

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Channel used by the server for every push ("daira"); the person can mute it in system settings.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel("daira", getString(R.string.notification_channel), NotificationManager.IMPORTANCE_HIGH)
            getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
        }
    }

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
