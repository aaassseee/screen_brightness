package com.aaassseee.screen_brightness

import android.app.Activity
import android.content.Context
import android.content.res.Resources
import android.provider.Settings
import android.view.WindowManager
import androidx.annotation.NonNull
import com.aaassseee.screen_brightness.stream_handler.CurrentBrightnessChangeStreamHandler
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import kotlin.math.sign
import kotlin.properties.Delegates

/**
 * ScreenBrightnessPlugin setting screen brightness
 */
class ScreenBrightnessPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /**
     * The MethodChannel that will the communication between Flutter and native Android
     *
     * This local reference serves to register the plugin with the Flutter Engine and unregister it
     * when the Flutter Engine is detached from the Activity
     */
    private lateinit var methodChannel: MethodChannel

    private lateinit var currentBrightnessChangeEventChannel: EventChannel

    private var currentBrightnessChangeStreamHandler: CurrentBrightnessChangeStreamHandler? = null

    private var activity: Activity? = null

    /**
     * The value which will be init when this plugin is attached to the Flutter engine
     *
     * This value refer to the brightness value between 0 to 1 when the application initialized.
     */
    private var systemBrightness by Delegates.notNull<Float>()

    /**
     * The value which will be init when this plugin is attached to the Flutter engine
     *
     * This value refer to the maximum brightness value.
     *
     * By system default the value should be 255.0f, however it vary in some OS, e.g Miui.
     * Should not be changed in the future
     */
    private var maximumBrightness by Delegates.notNull<Float>()

    /**
     * The value which will be set when user called [handleSetScreenBrightnessMethodCall]
     * or [handleResetScreenBrightnessMethodCall]
     *
     * This value refer to the brightness value between 0 to 1 when user called [handleSetScreenBrightnessMethodCall].
     */
    private var changedBrightness: Float? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "github.com/aaassseee/screen_brightness"
        )
        methodChannel.setMethodCallHandler(this)


        currentBrightnessChangeEventChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            "github.com/aaassseee/screen_brightness/change"
        )

        try {
            maximumBrightness = getScreenMaximumBrightness()
            systemBrightness = getSystemBrightness(flutterPluginBinding.applicationContext)
        } catch (e: Settings.SettingNotFoundException) {
            e.printStackTrace()
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity

        currentBrightnessChangeStreamHandler =
            CurrentBrightnessChangeStreamHandler(
                binding.activity,
                onListenStart = null,
                onChange = { eventSink ->
                    systemBrightness = getSystemBrightness(binding.activity)
                    if (changedBrightness == null) {
                        eventSink.success(systemBrightness)
                    }
                })
        currentBrightnessChangeEventChannel.setStreamHandler(currentBrightnessChangeStreamHandler)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "getSystemScreenBrightness" -> handleGetSystemBrightnessMethodCall(result)
            "getScreenBrightness" -> handleGetScreenBrightnessMethodCall(result)
            "setScreenBrightness" -> handleSetScreenBrightnessMethodCall(call, result)
            "resetScreenBrightness" -> handleResetScreenBrightnessMethodCall(result)
            else -> result.notImplemented()
        }
    }

    private fun getSystemBrightness(context: Context): Float {
        return Settings.System.getInt(
            context.contentResolver,
            Settings.System.SCREEN_BRIGHTNESS
        ) / maximumBrightness
    }

    private fun handleGetSystemBrightnessMethodCall(result: MethodChannel.Result) {
        result.success(systemBrightness)
    }

    private fun handleGetScreenBrightnessMethodCall(result: MethodChannel.Result) {
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
            brightness = getSystemBrightness(activity)
        } catch (e: Settings.SettingNotFoundException) {
            e.printStackTrace()
        }

        if (brightness == null) {
            result.error("-11", "Could not found system setting screen brightness value", null)
            return
        }

        result.success(brightness)
    }

    private fun getScreenMaximumBrightness(): Float {
        return try {
            val systemResources: Resources = Resources.getSystem()
            val maximumBrightnessIdentifier: Int =
                systemResources.getIdentifier(
                    "config_screenBrightnessSettingMaximum",
                    "integer",
                    "android"
                )
            if (maximumBrightnessIdentifier == 0) {
                throw NullPointerException()
            }

            systemResources.getInteger(maximumBrightnessIdentifier).toFloat()
        } catch (e: Exception) {
            255.0f
        }
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

    private fun handleSetScreenBrightnessMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        val activity = activity
        if (activity == null) {
            result.error("-10", "Unexpected error on activity binding", null)
            return
        }

        val brightness: Float? = (call.argument("brightness") as? Double)?.toFloat()
        if (brightness == null) {
            result.error("-2", "Unexpected error on null brightness", null)
            return
        }

        val isSet = setWindowsAttributesBrightness(brightness)
        if (!isSet) {
            result.error("-1", "Unable to change screen brightness", null)
            return
        }

        changedBrightness = brightness
        handleCurrentBrightnessChanged(brightness)
        result.success(null)
    }

    private fun handleResetScreenBrightnessMethodCall(result: MethodChannel.Result) {
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

        changedBrightness = null
        handleCurrentBrightnessChanged(systemBrightness)
        result.success(null)
    }

    private fun handleCurrentBrightnessChanged(currentBrightness: Float) {
        currentBrightnessChangeStreamHandler?.addCurrentBrightnessToEventSink(currentBrightness.toDouble())
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
        currentBrightnessChangeEventChannel.setStreamHandler(null)
        currentBrightnessChangeStreamHandler = null
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        currentBrightnessChangeEventChannel.setStreamHandler(null)
        currentBrightnessChangeStreamHandler = null
    }
}
