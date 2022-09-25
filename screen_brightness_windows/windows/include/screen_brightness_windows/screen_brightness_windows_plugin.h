#ifndef FLUTTER_PLUGIN_SCREEN_BRIGHTNESS_WINDOWS_PLUGIN_H_
#define FLUTTER_PLUGIN_SCREEN_BRIGHTNESS_WINDOWS_PLUGIN_H_

#include <flutter_plugin_registrar.h>

#include "../include/screen_brightness_windows/current_brightness_change_stream_handler.h"

#include <flutter/plugin_registrar_windows.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

	FLUTTER_PLUGIN_EXPORT void ScreenBrightnessWindowsPluginRegisterWithRegistrar(
		FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

// plugin header
namespace screen_brightness
{
	class ScreenBrightnessWindowsPlugin final : public flutter::Plugin
	{
	public:
		static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

		ScreenBrightnessWindowsPlugin(flutter::PluginRegistrarWindows* registrar);

		virtual ~ScreenBrightnessWindowsPlugin();

	private:
		flutter::PluginRegistrarWindows* registrar_;

		HWND window_handler_ = nullptr;

		long system_brightness_ = -1;

		long minimum_brightness_ = -1;

		long maximum_brightness_ = -1;

		long current_brightness_ = -1;

		long changed_brightness_ = -1;

		bool is_auto_reset_ = true;

		CurrentBrightnessChangeStreamHandler* current_brightness_change_stream_handler_ = nullptr;

		int window_proc_id_ = -1;

		// Called when a method is called on this plugin's channel from Dart.
		void HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue>& method_call,
			std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void GetBrightness(long& minimum_brightness, long& brightness, long& maximum_brightness);

		void SetBrightness(long brightness);

		[[nodiscard]] double GetBrightnessPercentage(long brightness) const;

		[[nodiscard]] long GetBrightnessValueByPercentage(double percentage) const;

		void HandleGetSystemBrightnessMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) const;

		void HandleGetScreenBrightnessMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void HandleSetScreenBrightnessMethodCall(
			const flutter::MethodCall<flutter::EncodableValue>& call,
			std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void HandleResetScreenBrightnessMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void HandleCurrentBrightnessChanged(long brightness);

		void HandleHasChangedMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) const;

		void HandleIsAutoResetMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void HandleSetAutoResetMethodCall(const flutter::MethodCall<flutter::EncodableValue>& call,
			std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		std::optional<LRESULT> HandleWindowProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam);
	};
}

#endif  // FLUTTER_PLUGIN_SCREEN_BRIGHTNESS_WINDOWS_PLUGIN_H_
