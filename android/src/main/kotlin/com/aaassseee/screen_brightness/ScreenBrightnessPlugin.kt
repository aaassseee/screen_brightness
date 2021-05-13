package com.aaassseee.screen_brightness

import android.app.Activity
import android.provider.Settings
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlin.math.sign
import kotlin.properties.Delegates

/**
 * ScreenBrightnessPlugin setting screen brightness
 */
class ScreenBrightnessPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    private var activity: Activity? = null

    /// The value which will be init when this plugin is attached to the Flutter engine
    ///
    /// Should not be changed in the future
    private var initialBrightness: Float? = null

    /**
     *
     */
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
                flutterPluginBinding.binaryMessenger,
                "github.com/aaassseee/screen_brightness"
        )
        channel.setMethodCallHandler(this)
        try {
            initialBrightness = Settings.System.getInt(
                    flutterPluginBinding.applicationContext.contentResolver,
                    Settings.System.SCREEN_BRIGHTNESS
            ) / 255.0f
        } catch (e: Settings.SettingNotFoundException) {
            e.printStackTrace()
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getInitialBrightness" -> getInitialBrightness(result)
            "getScreenBrightness" -> getScreenBrightness(result)
            "setScreenBrightness" -> setScreenBrightness(call, result)
            "resetScreenBrightness" -> resetScreenBrightness(result)
            else -> result.notImplemented()
        }
    }

    private fun getInitialBrightness(result: Result) {
        result.success(initialBrightness)
    }

    private fun getScreenBrightness(result: Result) {
        val activity = activity
        if (activity == null) {
            result.error("-10", "Unexpected error on activity binding", null)
            return
        }

        var brightness: Float?
        // get current window attribute brightness
        val layoutParams: WindowManager.LayoutParams = activity.window.attributes
        brightness = layoutParams.screenBrightness
        // check brightness changed
        if (brightness.sign != -1.0f) {
            // return changed brightness
            result.success(brightness)
            return
        }

        // get system setting brightness
        try {
            brightness = Settings.System.getInt(
                    activity.contentResolver,
                    Settings.System.SCREEN_BRIGHTNESS
            ) / 255.0f
        } catch (e: Settings.SettingNotFoundException) {
            e.printStackTrace()
        }

        if (brightness == null) {
            result.error("-11", "Could not found system setting screen brightness value", null)
            return
        }

        result.success(brightness)
    }

    private fun setWindowsAttributesBrightness(brightness: Float): Boolean {
        return try {
            val layoutParams: WindowManager.LayoutParams = activity!!.window.attributes
            layoutParams.screenBrightness = brightness
            activity!!.window.attributes = layoutParams
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun setScreenBrightness(call: MethodCall, result: Result) {
        val activity = activity
        if (activity == null) {
            result.error("-10", "Unexpected error on activity binding", null)
            return
        }

        val brightness: Double? = call.argument("brightness")
        if (brightness == null) {
            result.error("-2", "Unexpected error on null brightness", null)
            return
        }

        val isSet = setWindowsAttributesBrightness(brightness.toFloat())
        if (!isSet) {
            result.error("-1", "Unable to change screen brightness", null)
            return
        }

        result.success(null)
    }

    private fun resetScreenBrightness(result: Result) {
        val activity = activity
        if (activity == null) {
            result.error("-10", "Unexpected error on activity binding", null)
            return
        }

        val isSet =
                setWindowsAttributesBrightness(WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE)
        if (!isSet) {
            result.error("-1", "Unable to change screen brightness", null)
            return
        }

        result.success(null)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
