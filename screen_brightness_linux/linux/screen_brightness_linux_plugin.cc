#include "include/screen_brightness_linux/screen_brightness_linux_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <cstring>
#include <exception>
#include <iostream>
#include <X11/Xatom.h>
#include <X11/Xlib.h>
#include <X11/extensions/Xrandr.h>

#define SCREEN_BRIGHTNESS_LINUX_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), screen_brightness_linux_plugin_get_type(), \
                              ScreenBrightnessLinuxPlugin))

struct _ScreenBrightnessLinuxPlugin {
    GObject parent_instance;

    FlPluginRegistrar *registrar = nullptr;

    FlMethodChannel *method_channel = nullptr;

    FlEventChannel *current_brightness_change_event_channel = nullptr;

    gboolean can_send_events = FALSE;

    gdouble system_brightness_ = -1;

    gdouble minimum_brightness_ = -1;

    gdouble maximum_brightness_ = -1;

    gdouble current_brightness_ = -1;

    gdouble changed_brightness_ = -1;

    gboolean is_auto_reset_ = true;
};

G_DEFINE_TYPE(ScreenBrightnessLinuxPlugin, screen_brightness_linux_plugin, g_object_get_type()
)

static void screen_brightness_linux_plugin_get_brightness(double &minimum_brightness,
                                                          double &maximum_brightness, double &current_brightness) {
    try {
        Display *display = XOpenDisplay(nullptr);
        if (display == nullptr) return;

        Atom backlight = XInternAtom(display, "Backlight", True);
        Window root = RootWindow(display, 0);
        XRRScreenResources *resources = XRRGetScreenResources(display, root);
        if (resources == nullptr) return;

        RROutput output = resources->outputs[0];
        XRRPropertyInfo *info = XRRQueryOutputProperty(display, output, backlight);
        if (info != nullptr) {
            minimum_brightness = info->values[0];
            maximum_brightness = info->values[1];
            current_brightness = info->values[2];
            XFree(info);
        }
        XRRFreeScreenResources(resources);
    } catch (const std::exception &exception) {
        std::cout << exception.what() << std::endl;
    }
}

static void screen_brightness_linux_plugin_set_brightness(double brightness) {
    try {
        double min = 0;
        double max = 0;

        Display *display = XOpenDisplay(nullptr);
        if (display == nullptr) return;

        Atom backlight = XInternAtom(display, "Backlight", True);
        Window root = RootWindow(display, 0);
        XRRScreenResources *resources = XRRGetScreenResources(display, root);
        if (resources == nullptr) return;

        RROutput output = resources->outputs[0];
        XRRPropertyInfo *info = XRRQueryOutputProperty(display, output, backlight);
        if (info != nullptr) {
            min = info->values[0];
            max = info->values[1];
        }
        XFree(info);
        XRRFreeScreenResources(resources);

        double value = brightness * (max - min) + min;

        XRRChangeOutputProperty(display, output, backlight, XA_INTEGER,
                                32, PropModeReplace, (unsigned char *) &value, 1);
        XFlush(display);
        XSync(display, False);
    } catch (const std::exception &exception) {
        std::cout << exception.what() << std::endl;
    }
}

static double
screen_brightness_linux_plugin_get_brightness_percentage(double minimum_brightness, double maximum_brightness,
                                                         double brightness) {
    return (brightness - minimum_brightness) / (maximum_brightness - minimum_brightness);
}

static void
screen_brightness_linux_plugin_handle_current_brightness_changed(FlEventChannel *channel, double minimum_brightness,
                                                                 double maximum_brightness, double changed_brightness) {
    if (channel == nullptr) {
        return;
    }

    try {
        const double brightness_percentage = screen_brightness_linux_plugin_get_brightness_percentage(
                minimum_brightness, maximum_brightness,
                changed_brightness);
        fl_event_channel_send(channel, fl_value_new_float(brightness_percentage), nullptr, nullptr);
    } catch (const std::exception &exception) {
        std::cout << exception.what() << std::endl;
    }
}

static void screen_brightness_linux_plugin_handle_get_screen_brightness_method_call(ScreenBrightnessLinuxPlugin * self,
                                                                                    FlMethodCall * method_call) {
    try {
        screen_brightness_linux_plugin_get_brightness(self->minimum_brightness_, self->maximum_brightness_,
                                                      self->current_brightness_);
        fl_method_call_respond_success(method_call,
                                       fl_value_new_float(screen_brightness_linux_plugin_get_brightness_percentage(
                                               self->minimum_brightness_, self->maximum_brightness_,
                                               self->current_brightness_)),
                                       nullptr);
    } catch (const std::exception &exception) {
        fl_method_call_respond_error(method_call, "-11", "Could not found monitor brightness value", nullptr, nullptr);
    }
}

static void screen_brightness_linux_plugin_handle_set_screen_brightness_method_call(ScreenBrightnessLinuxPlugin * self,
                                                                                    FlMethodCall * method_call) {
    g_autoptr(FlValue)
    args = fl_method_call_get_args(method_call);
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
        fl_method_call_respond_error(method_call, "-2", "Unexpected error on parameter", nullptr, nullptr);
        return;
    }

    g_autoptr(FlValue)
    brightness_value = fl_value_lookup_string(args, "brightness");
    if (fl_value_get_type(brightness_value) != FL_VALUE_TYPE_FLOAT) {
        fl_method_call_respond_error(method_call, "-2", "Unexpected error on parameter", nullptr, nullptr);
        return;
    }

    double brightness = fl_value_get_float(brightness_value);
    double changed_brightness = screen_brightness_linux_plugin_get_brightness_percentage(self->minimum_brightness_,
                                                                                         self->maximum_brightness_,
                                                                                         brightness);
    try {
        screen_brightness_linux_plugin_set_brightness(changed_brightness);
        self->changed_brightness_ = changed_brightness;
        screen_brightness_linux_plugin_handle_current_brightness_changed(self->current_brightness_change_event_channel,
                                                                         self->minimum_brightness_,
                                                                         self->maximum_brightness_,
                                                                         changed_brightness);
        fl_method_call_respond_success(method_call, nullptr, nullptr);
    } catch (const std::exception &exception) {
        fl_method_call_respond_error(method_call, "-1", "Unable to change screen brightness", nullptr, nullptr);
    }
}

static void
screen_brightness_linux_plugin_handle_reset_screen_brightness_method_call(ScreenBrightnessLinuxPlugin * self,
                                                                          FlMethodCall * method_call) {
    try {
        screen_brightness_linux_plugin_set_brightness(self->system_brightness_);
        self->changed_brightness_ = -1;
        screen_brightness_linux_plugin_handle_current_brightness_changed(self->current_brightness_change_event_channel,
                                                                         self->minimum_brightness_,
                                                                         self->maximum_brightness_,
                                                                         self->system_brightness_);
        fl_method_call_respond_success(method_call, nullptr, nullptr);
    } catch (const std::exception &exception) {
        fl_method_call_respond_error(method_call, "-1", "Unable reset screen brightness", nullptr, nullptr);
    }
}

static void screen_brightness_linux_plugin_handle_has_changed_method_call(ScreenBrightnessLinuxPlugin * self,
                                                                          FlMethodCall * method_call) {
    fl_method_call_respond_success(method_call, fl_value_new_bool(self->changed_brightness_ != -1), nullptr);
}

static void screen_brightness_linux_plugin_handle_is_auto_reset_method_call(ScreenBrightnessLinuxPlugin * self,
                                                                            FlMethodCall * method_call) {
    fl_method_call_respond_success(method_call, fl_value_new_bool(self->is_auto_reset_), nullptr);
}

static void screen_brightness_linux_plugin_handle_set_auto_reset_method_call(ScreenBrightnessLinuxPlugin * self,
                                                                             FlMethodCall * method_call) {
    g_autoptr(FlValue)
    args = fl_method_call_get_args(method_call);
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
        fl_method_call_respond_error(method_call, "-2", "Unexpected error on parameter", nullptr, nullptr);
        return;
    }

    g_autoptr(FlValue)
    isAutoResetValue = fl_value_lookup_string(args, "isAutoReset");
    if (fl_value_get_type(args) != FL_VALUE_TYPE_BOOL) {
        fl_method_call_respond_error(method_call, "-2", "Unexpected error on parameter", nullptr, nullptr);
        return;
    }

    self->is_auto_reset_ = fl_value_get_bool(isAutoResetValue);
    fl_method_call_respond_success(method_call, fl_value_new_bool(self->is_auto_reset_), nullptr);
}

// Called when a method call is received from Flutter.
static void screen_brightness_linux_plugin_handle_method_call(
        ScreenBrightnessLinuxPlugin * self,
        FlMethodCall * method_call) {
    const gchar *method = fl_method_call_get_name(method_call);

    if (strcmp(method, "getSystemScreenBrightness") == 0) {
        screen_brightness_linux_plugin_handle_get_screen_brightness_method_call(self, method_call);
        return;
    }

    if (strcmp(method, "getScreenBrightness") == 0) {
        screen_brightness_linux_plugin_handle_get_screen_brightness_method_call(self, method_call);
        return;
    }

    if (strcmp(method, "setScreenBrightness") == 0) {
        screen_brightness_linux_plugin_handle_set_screen_brightness_method_call(self, method_call);
        return;
    }

    if (strcmp(method, "resetScreenBrightness") == 0) {
        screen_brightness_linux_plugin_handle_reset_screen_brightness_method_call(self, method_call);
        return;
    }

    if (strcmp(method, "hasChanged") == 0) {
        screen_brightness_linux_plugin_handle_has_changed_method_call(self, method_call);
        return;
    }

    if (strcmp(method, "isAutoReset") == 0) {
        screen_brightness_linux_plugin_handle_is_auto_reset_method_call(self, method_call);
        return;
    }

    if (strcmp(method, "setAutoReset") == 0) {
        screen_brightness_linux_plugin_handle_set_auto_reset_method_call(self, method_call);
        return;
    }

    fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_not_implemented_response_new()), nullptr);
}

static void screen_brightness_linux_plugin_dispose(GObject * object) {
    ScreenBrightnessLinuxPlugin * self = SCREEN_BRIGHTNESS_LINUX_PLUGIN(object);

    g_clear_object(&self->registrar);
    g_clear_object(&self->method_channel);
    g_clear_object(&self->current_brightness_change_event_channel);

    G_OBJECT_CLASS(screen_brightness_linux_plugin_parent_class)->dispose(object);
}

static void screen_brightness_linux_plugin_class_init(ScreenBrightnessLinuxPluginClass *klass) {
    G_OBJECT_CLASS(klass)->dispose = screen_brightness_linux_plugin_dispose;
}

static void screen_brightness_linux_plugin_init(ScreenBrightnessLinuxPlugin * self) {

}

static void method_call_cb(FlMethodChannel *channel, FlMethodCall *method_call,
                           gpointer user_data) {
    ScreenBrightnessLinuxPlugin * plugin = SCREEN_BRIGHTNESS_LINUX_PLUGIN(user_data);
    screen_brightness_linux_plugin_handle_method_call(plugin, method_call);
}

void screen_brightness_linux_plugin_register_with_registrar(FlPluginRegistrar *registrar) {
    ScreenBrightnessLinuxPlugin * self = SCREEN_BRIGHTNESS_LINUX_PLUGIN(
            g_object_new(screen_brightness_linux_plugin_get_type(), nullptr));

    self->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));

    g_autoptr(FlStandardMethodCodec)
    codec = fl_standard_method_codec_new();
    self->method_channel =
            fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                                  "github.com/aaassseee/screen_brightness",
                                  FL_METHOD_CODEC(codec));
    fl_method_channel_set_method_call_handler(self->method_channel, method_call_cb,
                                              g_object_ref(self),
                                              g_object_unref);

    self->current_brightness_change_event_channel = fl_event_channel_new(
            fl_plugin_registrar_get_messenger(registrar), "github.com/aaassseee/screen_brightness/change",
            FL_METHOD_CODEC(codec));
    fl_event_channel_set_stream_handlers(self->current_brightness_change_event_channel,
                                         [](FlEventChannel *, FlValue *,
                                            gpointer user_data) -> FlMethodErrorResponse * {
                                             SCREEN_BRIGHTNESS_LINUX_PLUGIN(user_data)->can_send_events = TRUE;
                                             return nullptr;
                                         },
                                         [](FlEventChannel *, FlValue *,
                                            gpointer user_data) -> FlMethodErrorResponse * {
                                             SCREEN_BRIGHTNESS_LINUX_PLUGIN(user_data)->can_send_events = FALSE;
                                             return nullptr;
                                         },
                                         g_object_ref(self), g_object_unref);

    g_object_unref(self);
}
