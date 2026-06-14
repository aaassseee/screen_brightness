//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <screen_brightness_linux/screen_brightness_linux_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) screen_brightness_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "ScreenBrightnessLinuxPlugin");
  screen_brightness_linux_plugin_register_with_registrar(screen_brightness_linux_registrar);
}
