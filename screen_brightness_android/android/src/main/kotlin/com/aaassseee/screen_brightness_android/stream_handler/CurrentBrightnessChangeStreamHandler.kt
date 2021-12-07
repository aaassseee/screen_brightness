package com.aaassseee.screen_brightness_android.stream_handler

import android.content.Context
import android.database.ContentObserver
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.EventChannel

class CurrentBrightnessChangeStreamHandler(
    private val context: Context,
    val onListenStart: ((eventSink: EventChannel.EventSink) -> Unit)?,
    val onChange: ((eventSink: EventChannel.EventSink) -> Unit)
) : BaseStreamHandler() {
    private val contentObserver: ContentObserver =
        object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean) {
                super.onChange(selfChange)
                val eventSink = eventSink ?: return
                onChange.invoke(
                    eventSink
                )
            }
        }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        super.onListen(arguments, events)
        context.contentResolver.registerContentObserver(
            Settings.System.getUriFor(Settings.System.SCREEN_BRIGHTNESS),
            false,
            contentObserver
        )
        val eventSink = eventSink ?: return
        onListenStart?.invoke(eventSink)
    }

    override fun onCancel(arguments: Any?) {
        super.onCancel(arguments)
        context.contentResolver.unregisterContentObserver(contentObserver)
    }

    fun addCurrentBrightnessToEventSink(brightness: Double) {
        val eventSink = eventSink ?: return
        eventSink.success(brightness)
    }
}