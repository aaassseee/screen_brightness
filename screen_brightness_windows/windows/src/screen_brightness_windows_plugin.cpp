#include "../include/screen_brightness_windows/screen_brightness_windows_plugin.h"

// This must be included before many other Windows headers.
#include <Windows.h>

#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <sstream>
#include <highlevelmonitorconfigurationapi.h>

#pragma comment(lib, "Dxva2.lib")

namespace screen_brightness
{
	ScreenBrightnessWindowsPlugin::ScreenBrightnessWindowsPlugin(
		flutter::PluginRegistrarWindows* registrar) : registrar_(registrar)
	{
		window_handler_ = registrar->GetView()->GetNativeWindow();
		try
		{
			GetScreenBrightness(minimum_screen_brightness_, system_screen_brightness_, maximum_screen_brightness_);
		}
		catch (const std::exception& exception)
		{
			std::cout << exception.what() << std::endl;
		}

		window_proc_id_ = registrar->RegisterTopLevelWindowProcDelegate
		([this](HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
			{
				return HandleWindowProc(hWnd, message, wParam, lParam);
			});
	}

	ScreenBrightnessWindowsPlugin::~ScreenBrightnessWindowsPlugin()
	{
		registrar_->UnregisterTopLevelWindowProcDelegate(window_proc_id_);
	}

	// static
	void ScreenBrightnessWindowsPlugin::RegisterWithRegistrar(
		flutter::PluginRegistrarWindows* registrar)
	{
		auto plugin = std::make_unique<ScreenBrightnessWindowsPlugin>(registrar);

		const auto method_channel =
			std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
				registrar->messenger(), "github.com/aaassseee/screen_brightness",
				&flutter::StandardMethodCodec::GetInstance());
		method_channel->SetMethodCallHandler
		([plugin_pointer = plugin.get()](const auto& call, auto result)
		{
			plugin_pointer->HandleMethodCall(call, std::move(result));
		});

		const auto application_screen_brightness_change_event_channel =
			std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
				registrar->messenger(), "github.com/aaassseee/screen_brightness/application_brightness_change",
				&flutter::StandardMethodCodec::GetInstance());

		plugin->application_screen_brightness_change_stream_handler_ = new ApplicationScreenBrightnessChangeStreamHandler();
		std::unique_ptr<flutter::StreamHandler<flutter::EncodableValue>>
			application_screen_brightness_change_stream_handler_unique_pointer
		{
			static_cast<flutter::StreamHandler<flutter::EncodableValue>*>(plugin->application_screen_brightness_change_stream_handler_)
		};
		application_screen_brightness_change_event_channel->SetStreamHandler(std::move(application_screen_brightness_change_stream_handler_unique_pointer));

		registrar->AddPlugin(std::move(plugin));
	}

	void ScreenBrightnessWindowsPlugin::HandleMethodCall(
		const flutter::MethodCall<flutter::EncodableValue>& method_call,
		std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		if (method_call.method_name() == "getSystemScreenBrightness")
		{
			HandleGetSystemScreenBrightnessMethodCall(std::move(result));
			return;
		}

		if (method_call.method_name() == "setSystemScreenBrightness")
		{
			HandleSetSystemScreenBrightnessMethodCall(method_call, std::move(result));
			return;
		}

		if (method_call.method_name() == "getApplicationScreenBrightness")
		{
			HandleGetApplicationScreenBrightnessMethodCall(std::move(result));
			return;
		}

		if (method_call.method_name() == "setApplicationScreenBrightness")
		{
			HandleSetApplicationScreenBrightnessMethodCall(method_call, std::move(result));
			return;
		}

		if (method_call.method_name() == "resetApplicationScreenBrightness")
		{
			HandleResetApplicationScreenBrightnessMethodCall(std::move(result));
			return;
		}

		if (method_call.method_name() == "hasApplicationScreenBrightnessChanged")
		{
			HandleHasApplicationScreenBrightnessChangedMethodCall(std::move(result));
			return;
		}

		if (method_call.method_name() == "isAutoReset")
		{
			HandleIsAutoResetMethodCall(std::move(result));
			return;
		}

		if (method_call.method_name() == "setAutoReset")
		{
			HandleSetAutoResetMethodCall(method_call, std::move(result));
			return;
		}

		if (method_call.method_name() == "isAnimate")
		{
			HandleIsAnimateMethodCall(std::move(result));
			return;
		}

		if (method_call.method_name() == "setAnimate")
		{
			HandleSetAnimateMethodCall(method_call, std::move(result));
			return;
		}

		result->NotImplemented();
	}

	void ScreenBrightnessWindowsPlugin::GetScreenBrightness(long& minimum_screen_brightness, long& screen_brightness, long& maximum_screen_brightness)
	{
		DWORD physical_monitor_array_size = 0;
		HMONITOR monitor_handler = MonitorFromWindow(window_handler_, MONITOR_DEFAULTTOPRIMARY);
		DWORD minimum_brightness_ = 0, brightness_ = 0, maximum_brightness_ = 0;

		if (!GetNumberOfPhysicalMonitorsFromHMONITOR(monitor_handler, &physical_monitor_array_size))
		{
			throw std::exception("Problem getting numbers of monitor");
		}

		LPPHYSICAL_MONITOR physical_monitor = (LPPHYSICAL_MONITOR)malloc(physical_monitor_array_size * sizeof(PHYSICAL_MONITOR));

		if (physical_monitor == NULL)
		{
			throw std::exception("No monitors");
		}

		if (!GetPhysicalMonitorsFromHMONITOR(monitor_handler, physical_monitor_array_size, physical_monitor))
		{
			throw std::exception("Problem getting physical monitors");
		}

		if (!GetMonitorBrightness(physical_monitor->hPhysicalMonitor, &minimum_brightness_, &brightness_, &maximum_brightness_))
		{
			throw std::exception("Problem getting monitor brightness");
		}

		minimum_screen_brightness = minimum_brightness_;
		screen_brightness = brightness_;
		maximum_screen_brightness = maximum_brightness_;

		DestroyPhysicalMonitors(physical_monitor_array_size, physical_monitor);

		free(physical_monitor);
	}

	void ScreenBrightnessWindowsPlugin::SetScreenBrightness(const long screen_brightness)
	{
		DWORD physical_monitor_array_size = 0;
		HMONITOR monitor_handler = MonitorFromWindow(window_handler_, MONITOR_DEFAULTTOPRIMARY);

		if (!GetNumberOfPhysicalMonitorsFromHMONITOR(monitor_handler, &physical_monitor_array_size))
		{
			throw std::exception("Problem getting numbers of monitor");
		}

		LPPHYSICAL_MONITOR physical_monitor = (LPPHYSICAL_MONITOR)malloc(physical_monitor_array_size * sizeof(PHYSICAL_MONITOR));

		if (physical_monitor == NULL)
		{
			throw std::exception("No monitors");
		}

		if (!GetPhysicalMonitorsFromHMONITOR(monitor_handler, physical_monitor_array_size, physical_monitor))
		{
			throw std::exception("Problem getting physical monitors");
		}

		if (!SetMonitorBrightness(physical_monitor->hPhysicalMonitor, screen_brightness))
		{
			throw std::exception("Problem setting monitor brightness");
		}

		DestroyPhysicalMonitors(physical_monitor_array_size, physical_monitor);

		free(physical_monitor);
	}

	double ScreenBrightnessWindowsPlugin::GetScreenBrightnessPercentage(const long screen_brightness) const
	{
		if (screen_brightness < 0)
		{
			return 0;
		}

		return static_cast<double>(screen_brightness - minimum_screen_brightness_) / (maximum_screen_brightness_ - minimum_screen_brightness_);
	}

	long ScreenBrightnessWindowsPlugin::GetScreenBrightnessValueByPercentage(const double percentage) const
	{
		return static_cast<long>((percentage * (maximum_screen_brightness_ - minimum_screen_brightness_)) + minimum_screen_brightness_);
	}

	void ScreenBrightnessWindowsPlugin::HandleGetSystemScreenBrightnessMethodCall(const std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) const
	{
		result->Success(GetScreenBrightnessPercentage(system_screen_brightness_));
	}

	void ScreenBrightnessWindowsPlugin::HandleSetSystemScreenBrightnessMethodCall(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		if (window_handler_ == nullptr)
		{
			result->Error("-10", "Unexpected error on window handler");
			return;
		}

		const flutter::EncodableMap& args = std::get<flutter::EncodableMap>(*call.arguments());
		const double brightness = std::get<double>(args.at(flutter::EncodableValue("brightness")));
		if (std::isnan(brightness))
		{
			result->Error("-2", "Unexpected error on null brightness");
			return;
		}

		const long changed_brightness = GetScreenBrightnessValueByPercentage(brightness);
		try
		{
			if (changed_screen_brightness_ == -1)
			{
				SetScreenBrightness(changed_brightness);
				HandleCurrentBrightnessChanged(changed_brightness);
			}
			system_screen_brightness_ = changed_brightness;
			
			result->Success(nullptr);
		}
		catch (const std::exception& exception)
		{
			result->Error("-1", "Unable to change screen brightness.", exception.what());
		}
	}

	void ScreenBrightnessWindowsPlugin::HandleGetApplicationScreenBrightnessMethodCall(const std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		if (window_handler_ == nullptr)
		{
			result->Error("-10", "Unexpected error on window handler");
			return;
		}

		try
		{
			GetScreenBrightness(minimum_screen_brightness_, application_screen_brightness_, maximum_screen_brightness_);
			result->Success(GetScreenBrightnessPercentage(application_screen_brightness_));
		}
		catch (const std::exception& exception)
		{
			result->Error("-11", "Could not found monitor brightness value.", exception.what());
		}
	}

	void ScreenBrightnessWindowsPlugin::HandleSetApplicationScreenBrightnessMethodCall(const flutter::MethodCall<flutter::EncodableValue>& call, const std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		if (window_handler_ == nullptr)
		{
			result->Error("-10", "Unexpected error on window handler");
			return;
		}

		const flutter::EncodableMap& args = std::get<flutter::EncodableMap>(*call.arguments());
		const double brightness = std::get<double>(args.at(flutter::EncodableValue("brightness")));
		if (std::isnan(brightness))
		{
			result->Error("-2", "Unexpected error on null brightness");
			return;
		}

		const long changed_brightness = GetScreenBrightnessValueByPercentage(brightness);
		try
		{
			SetScreenBrightness(changed_brightness);
			changed_screen_brightness_ = changed_brightness;
			HandleCurrentBrightnessChanged(changed_brightness);
			result->Success(nullptr);
		}
		catch (const std::exception& exception)
		{
			result->Error("-1", "Unable to change screen brightness.", exception.what());
		}
	}

	void ScreenBrightnessWindowsPlugin::HandleResetApplicationScreenBrightnessMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		if (window_handler_ == nullptr)
		{
			result->Error("-10", "Unexpected error on window handler");
			return;
		}

		try
		{
			SetScreenBrightness(system_screen_brightness_);
			changed_screen_brightness_ = -1;
			HandleCurrentBrightnessChanged(system_screen_brightness_);
			result->Success(nullptr);
		}
		catch (const std::exception& exception)
		{
			result->Error("-1", "Unable reset screen brightness. error: ", exception.what());
		}
	}

	void ScreenBrightnessWindowsPlugin::HandleCurrentBrightnessChanged(const long brightness)
	{
		if (application_screen_brightness_change_stream_handler_ == nullptr)
		{
			return;
		}

		try
		{
			const double brightness_percentage = GetScreenBrightnessPercentage(brightness);
			application_screen_brightness_change_stream_handler_->AddApplicationScreenBrightnessToEventSink(brightness_percentage);
		}
		catch (const std::exception& exception)
		{
			std::cout << exception.what() << std::endl;
		}
	}

	void ScreenBrightnessWindowsPlugin::HandleHasApplicationScreenBrightnessChangedMethodCall(const std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) const
	{
		result->Success(changed_screen_brightness_ != -1);
	}

	void ScreenBrightnessWindowsPlugin::HandleIsAutoResetMethodCall(const std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		result->Success(is_auto_reset_);
	}

	void ScreenBrightnessWindowsPlugin::HandleSetAutoResetMethodCall(const flutter::MethodCall<flutter::EncodableValue>& call, const std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		const flutter::EncodableMap& args = std::get<flutter::EncodableMap>(*call.arguments());
		const bool is_auto_reset = std::get<bool>(args.at(flutter::EncodableValue("isAutoReset")));

		is_auto_reset_ = is_auto_reset;
		result->Success(nullptr);
	}

	void ScreenBrightnessWindowsPlugin::HandleIsAnimateMethodCall(const std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		result->Success(is_animate_);
	}

	void ScreenBrightnessWindowsPlugin::HandleSetAnimateMethodCall(const flutter::MethodCall<flutter::EncodableValue>& call, const std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		const flutter::EncodableMap& args = std::get<flutter::EncodableMap>(*call.arguments());
		const bool is_animate = std::get<bool>(args.at(flutter::EncodableValue("isAnimate")));

		is_animate_ = is_animate;
		result->Success(nullptr);
	}

	std::optional<LRESULT> ScreenBrightnessWindowsPlugin::HandleWindowProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
	{
		if (changed_screen_brightness_ == -1 || !is_auto_reset_)
		{
			return std::nullopt;
		}

		switch (message)
		{
		case WM_SIZE:
			switch (wParam)
			{
			case SIZE_MINIMIZED:
				SetScreenBrightness(system_screen_brightness_);
				break;

			case SIZE_MAXIMIZED:
			case SIZE_RESTORED:
				SetScreenBrightness(changed_screen_brightness_);
				break;
			}
			break;

		case WM_DESTROY:
			SetScreenBrightness(system_screen_brightness_);
			break;

		case WM_ACTIVATEAPP:
			bool is_activate = bool(wParam);
			SetScreenBrightness(is_activate ? changed_screen_brightness_ : system_screen_brightness_);
			break;
		}

		// allow another plugin to process message
		return std::nullopt;
	}
}

void ScreenBrightnessWindowsPluginRegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar)
{
	screen_brightness::ScreenBrightnessWindowsPlugin::RegisterWithRegistrar(
		flutter::PluginRegistrarManager::GetInstance()
		->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}