#include "include/screen_brightness_windows/screen_brightness_windows_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "include/screen_brightness_windows/screen_brightness_windows_plugin.h"

void ScreenBrightnessWindowsPluginCApiRegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar)
{
	screen_brightness::ScreenBrightnessWindowsPlugin::RegisterWithRegistrar(
		flutter::PluginRegistrarManager::GetInstance()
		->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}