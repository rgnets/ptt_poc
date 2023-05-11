package com.rgnets.pttoc_test

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.engine.FlutterEngineCache


const val XCOVER_PTT_KEYCODE = 1015

// https://docs.samsungknox.com/dev/knox-sdk/install-sdk.htm
class MainActivity: FlutterActivity() {

    override fun provideFlutterEngine(context: Context): FlutterEngine {
        // Instantiate a FlutterEngine with a unique ID
        val flutterEngine = FlutterEngine(context.applicationContext)

        // Cache the FlutterEngine with a unique ID
        FlutterEngineCache.getInstance().put("myEngineId", flutterEngine)
        return flutterEngine
    }
}


class IntentReceiver : BroadcastReceiver() {
    private val CHANNEL_NAME = "com.rgnets.pttoc/ptt"
    private lateinit var channel: MethodChannel

    override fun onReceive(context: Context, intent: Intent) {
        val flutterEngine = FlutterEngineCache.getInstance().get("myEngineId")
        if (flutterEngine != null) {
            channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)

            val intentAction = intent.action
            if ("com.samsung.android.knox.intent.action.HARD_KEY_REPORT" == intentAction) {
                val keyCode = intent.getIntExtra("com.samsung.android.knox.intent.extra.KEY_CODE", -10);
                val keyReportType = intent.getIntExtra("com.samsung.android.knox.intent.extra.KEY_REPORT_TYPE", -10);
                if (keyCode == XCOVER_PTT_KEYCODE && keyReportType == 1) {
                    Log.i("IntentReceiver", "XCover key pressed")
                    channel.invokeMethod("pttEvent", "ptt_pressed")
                }
                else if (keyCode == XCOVER_PTT_KEYCODE && keyReportType == 2) {
                    Log.i("IntentReceiver", "XCover key released")
                    channel.invokeMethod("pttEvent", "ptt_released")
                }
            }
        } else {
            Log.i("IntentReceiver", "Couldn't find flutter engine!")
        }
    }
}
