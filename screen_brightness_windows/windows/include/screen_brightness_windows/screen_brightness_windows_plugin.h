#ifndef FLUTTER_PLUGIN_SCREEN_BRIGHTNESS_WINDOWS_PLUGIN_H_
#define FLUTTER_PLUGIN_SCREEN_BRIGHTNESS_WINDOWS_PLUGIN_H_

#include <flutter_plugin_registrar.h>

#include "../include/screen_brightness_windows/screen_brightness_changed_stream_handler.h"

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

        int window_proc_id_ = -1;

		ScreenBrightnessChangedStreamHandler* system_screen_brightness_changed_stream_handler_ = nullptr;

		ScreenBrightnessChangedStreamHandler* application_screen_brightness_changed_stream_handler_ = nullptr;

		long minimum_screen_brightness_ = -1;

		long maximum_screen_brightness_ = -1;

		long system_screen_brightness_ = -1;

		long application_screen_brightness_ = -1;

		bool is_auto_reset_ = true;

		bool is_animate_ = true;

		// Called when a method is called on this plugin's channel from Dart.
		void HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue>& method_call,
			std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void HandleGetSystemScreenBrightnessMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) const;

		void HandleSetSystemScreenBrightnessMethodCall(
			const flutter::MethodCall<flutter::EncodableValue>& call,
			std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void HandleSystemScreenBrightnessChanged(long brightness);

		void HandleGetApplicationScreenBrightnessMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void HandleSetApplicationScreenBrightnessMethodCall(
			const flutter::MethodCall<flutter::EncodableValue>& call,
			std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void HandleResetApplicationScreenBrightnessMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void HandleApplicationScreenBrightnessChanged(long brightness);

		void HandleHasApplicationScreenBrightnessChangedMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) const;

		void HandleIsAutoResetMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void HandleSetAutoResetMethodCall(const flutter::MethodCall<flutter::EncodableValue>& call,
			std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void HandleIsAnimateMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void HandleSetAnimateMethodCall(const flutter::MethodCall<flutter::EncodableValue>& call,
			std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void HandleCanChangeSystemBrightnessMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		std::optional<LRESULT> HandleWindowProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam);

		void GetScreenBrightness(long& minimum_screen_brightness, long& screen_brightness, long& maximum_screen_brightness);

		void SetScreenBrightness(long screen_brightness);

		[[nodiscard]] double GetScreenBrightnessPercentage(long screen_brightness) const;

		[[nodiscard]] long GetScreenBrightnessValueByPercentage(double percentage) const;

		void OnApplicationPause();

		void OnApplicationResume();
	};
}

#endif  // FLUTTER_PLUGIN_SCREEN_BRIGHTNESS_WINDOWS_PLUGIN_H_
