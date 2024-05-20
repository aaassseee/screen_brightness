package com.aaassseee.screen_brightness_android

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager
import com.aaassseee.screen_brightness_android.stream_handler.ApplicationScreenBrightnessChangeStreamHandler
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import java.lang.reflect.Field
import kotlin.math.sign
import kotlin.properties.Delegates

/**
 * ScreenBrightnessAndroidPlugin setting screen brightness
 */
class ScreenBrightnessAndroidPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /**
     * The MethodChannel that will the communication between Flutter and native Android
     *
     * This local reference serves to register the plugin with the Flutter Engine and unregister it
     * when the Flutter Engine is detached from the Activity
     */
    private lateinit var methodChannel: MethodChannel

    private lateinit var applicationScreenBrightnessChangedEventChannel: EventChannel

    private var applicationScreenBrightnessChangeStreamHandler: ApplicationScreenBrightnessChangeStreamHandler? = null

    private var activity: Activity? = null

    /**
     * The value which will be init when this plugin is attached to the Flutter engine
     *
     * This value refer to the brightness value between 0 and 1 when the application initialized.
     */
    private var systemScreenBrightness by Delegates.notNull<Float>()

    /**
     * The value which will be init when this plugin is attached to the Flutter engine
     *
     * This value refer to the maximum brightness value.
     *
     * By system default the value should be 255.0f, however it vary in some OS, e.g. Miui.
     * Should not be changed in the future
     */
    private var maximumScreenBrightness by Delegates.notNull<Float>()

    /**
     * The value which will be set when user called [handleSetApplicationScreenBrightnessMethodCall]
     * or [handleResetApplicationScreenBrightnessMethodCall]
     *
     * This value refer to the brightness value between 0 and 1 when user called [handleSetApplicationScreenBrightnessMethodCall].
     */
    private var applicationScreenBrightness: Float? = null

    private var isAutoReset: Boolean = true

    private var isAnimate: Boolean = true

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "github.com/aaassseee/screen_brightness"
        )
        methodChannel.setMethodCallHandler(this)


        applicationScreenBrightnessChangedEventChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            "github.com/aaassseee/screen_brightness/application_brightness_change"
        )

        try {
            maximumScreenBrightness = getScreenMaximumBrightness(flutterPluginBinding.applicationContext)
            systemScreenBrightness = getSystemBrightness(flutterPluginBinding.applicationContext)
        } catch (e: Settings.SettingNotFoundException) {
            e.printStackTrace()
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity

        applicationScreenBrightnessChangeStreamHandler =
            ApplicationScreenBrightnessChangeStreamHandler(
                binding.activity,
                onListenStart = null,
                onChange = { eventSink ->
                    systemScreenBrightness = getSystemBrightness(binding.activity)
                    if (applicationScreenBrightness == null) {
                        eventSink.success(systemScreenBrightness)
                    }
                })
        applicationScreenBrightnessChangedEventChannel.setStreamHandler(applicationScreenBrightnessChangeStreamHandler)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getSystemScreenBrightness" -> handleGetSystemBrightnessMethodCall(result)
            "setSystemScreenBrightness" -> handleSetSystemBrightnessMethodCall(call, result)
            "getApplicationScreenBrightness" -> handleGetApplicationScreenBrightnessMethodCall(result)
            "setApplicationScreenBrightness" -> handleSetApplicationScreenBrightnessMethodCall(call, result)
            "resetApplicationScreenBrightness" -> handleResetApplicationScreenBrightnessMethodCall(result)
            "hasApplicationScreenBrightnessChanged" -> handleHasApplicationScreenBrightnessChangedMethodCall(result)
            "isAutoReset" -> handleIsAutoResetMethodCall(result)
            "setAutoReset" -> handleSetAutoResetMethodCall(call, result)
            "isAnimate" -> handleIsAnimateMethodCall(result)
            "setAnimate" -> handleSetAnimateMethodCall(call, result)
            else -> result.notImplemented()
        }
    }

    private fun getSystemBrightness(context: Context): Float {
        return Settings.System.getInt(
            context.contentResolver,
            Settings.System.SCREEN_BRIGHTNESS
        ) / maximumScreenBrightness
    }

    private fun setSystemBrightness(context: Context, brightness: Float): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.System.canWrite(context)) {
                Intent(
                    Settings.ACTION_MANAGE_WRITE_SETTINGS,
                    Uri.parse("package:${context.packageName}")
                ).let {
                    it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(it)
                }
                return false
            }
        }

        return Settings.System.putInt(
            context.contentResolver,
            Settings.System.SCREEN_BRIGHTNESS,
            (maximumScreenBrightness * brightness).toInt()
        )
    }

    private fun handleGetSystemBrightnessMethodCall(result: MethodChannel.Result) {
        result.success(systemScreenBrightness)
    }

    private fun handleSetSystemBrightnessMethodCall(
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

        val isSet = setSystemBrightness(activity.applicationContext, brightness)
        if (!isSet) {
            result.error("-1", "Unable to change system brightness", null)
            return
        }

        systemScreenBrightness = brightness
        result.success(null)
    }


    private fun handleGetApplicationScreenBrightnessMethodCall(result: MethodChannel.Result) {
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
            result.success(brightness)
        } catch (e: Settings.SettingNotFoundException) {
            e.printStackTrace()
            result.error("-11", "Could not found system setting screen brightness value", null)
            return
        }
    }

    private fun getScreenMaximumBrightness(context: Context): Float {
        try {
            val powerManager: PowerManager =
                context.getSystemService(Context.POWER_SERVICE) as PowerManager?
                    ?: throw ClassNotFoundException()
            val fields: Array<Field> = powerManager.javaClass.declaredFields
            for (field in fields) {
                if (field.name.equals("BRIGHTNESS_ON")) {
                    field.isAccessible = true
                    return (field[powerManager] as Int).toFloat()
                }
            }

            return 255.0f
        } catch (e: Exception) {
            return 255.0f
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

    private fun handleSetApplicationScreenBrightnessMethodCall(
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

        applicationScreenBrightness = brightness
        handleCurrentBrightnessChanged(brightness)
        result.success(null)
    }

    private fun handleResetApplicationScreenBrightnessMethodCall(result: MethodChannel.Result) {
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

        applicationScreenBrightness = null
        handleCurrentBrightnessChanged(systemScreenBrightness)
        result.success(null)
    }

    private fun handleCurrentBrightnessChanged(currentBrightness: Float) {
        applicationScreenBrightnessChangeStreamHandler?.addCurrentBrightnessToEventSink(currentBrightness.toDouble())
    }

    private fun handleHasApplicationScreenBrightnessChangedMethodCall(result: MethodChannel.Result) {
        result.success(applicationScreenBrightness != null)
    }

    private fun handleIsAutoResetMethodCall(result: MethodChannel.Result) {
        result.success(isAutoReset)
    }

    private fun handleSetAutoResetMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val isAutoReset: Boolean? = call.argument("isAutoReset") as? Boolean
        if (isAutoReset == null) {
            result.error("-2", "Unexpected error on null isAutoReset", null)
            return
        }

        this.isAutoReset = isAutoReset
        result.success(null)
    }

    private fun handleIsAnimateMethodCall(result: MethodChannel.Result) {
        result.success(isAnimate)
    }

    private fun handleSetAnimateMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val isAnimate: Boolean? = call.argument("isAnimate") as? Boolean
        if (isAnimate == null) {
            result.error("-2", "Unexpected error on null isAnimate", null)
            return
        }

        this.isAnimate = isAnimate
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
        applicationScreenBrightnessChangedEventChannel.setStreamHandler(null)
        applicationScreenBrightnessChangeStreamHandler = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        applicationScreenBrightnessChangedEventChannel.setStreamHandler(null)
        applicationScreenBrightnessChangeStreamHandler = null
    }
}
