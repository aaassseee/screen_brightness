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
	// static
	void ScreenBrightnessWindowsPlugin::RegisterWithRegistrar(
		flutter::PluginRegistrarWindows* registrar) 
	{
		auto plugin = std::make_unique<ScreenBrightnessWindowsPlugin>();

		const auto method_channel =
			std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
				registrar->messenger(), "github.com/aaassseee/screen_brightness",
				&flutter::StandardMethodCodec::GetInstance());
		method_channel->SetMethodCallHandler
		([plugin_pointer = plugin.get()](const auto& call, auto result)
		{
			plugin_pointer->HandleMethodCall(call, std::move(result));
		});

		const auto current_brightness_change_event_channel =
			std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
				registrar->messenger(), "github.com/aaassseee/screen_brightness/change",
				&flutter::StandardMethodCodec::GetInstance());

		plugin->current_brightness_change_stream_handler_ = new CurrentBrightnessChangeStreamHandler();
		std::unique_ptr<flutter::StreamHandler<flutter::EncodableValue>> current_brightness_change_stream_handler_unique_pointer
		{
			static_cast<flutter::StreamHandler<flutter::EncodableValue>*>(plugin->current_brightness_change_stream_handler_)
		};
		current_brightness_change_event_channel->SetStreamHandler(std::move(current_brightness_change_stream_handler_unique_pointer));

		// init parameter
		plugin->window_handler_ = registrar->GetView()->GetNativeWindow();
		plugin->GetBrightness(plugin->minimum_brightness_, plugin->system_brightness_, plugin->maximum_brightness_);

		registrar->AddPlugin(std::move(plugin));
	}

	void ScreenBrightnessWindowsPlugin::HandleMethodCall(
		const flutter::MethodCall<flutter::EncodableValue>& method_call,
		std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		if (method_call.method_name() == "getSystemScreenBrightness")
		{
			HandleGetScreenBrightnessMethodCall(std::move(result));
			return;
		}

		if (method_call.method_name() == "getScreenBrightness")
		{
			HandleGetScreenBrightnessMethodCall(std::move(result));
			return;
		}

		if (method_call.method_name() == "setScreenBrightness")
		{
			HandleSetScreenBrightnessMethodCall(method_call, std::move(result));
			return;
		}

		if (method_call.method_name() == "resetScreenBrightness")
		{
			HandleResetScreenBrightnessMethodCall(std::move(result));
			return;
		}

		if (method_call.method_name() == "hasChanged")
		{
			HandleHasChangedMethodCall(std::move(result));
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

		result->NotImplemented();
	}

	void ScreenBrightnessWindowsPlugin::GetBrightness(long& minimum_brightness, long& brightness, long& maximum_brightness)
	{
		DWORD dwPhysicalMonitorArraySize = 0;
		HMONITOR hMonitor = MonitorFromWindow(window_handler_, MONITOR_DEFAULTTOPRIMARY);
		DWORD dwMin = 0, dwCurrent = 0, dwMax = 0;

		if (!GetNumberOfPhysicalMonitorsFromHMONITOR(hMonitor, &dwPhysicalMonitorArraySize))
		{
			throw std::exception("Problem getting numbers of monitor");
		}

		LPPHYSICAL_MONITOR pPhysicalMonitor = (LPPHYSICAL_MONITOR)malloc(dwPhysicalMonitorArraySize * sizeof(PHYSICAL_MONITOR));

		if (pPhysicalMonitor == NULL)
		{
			throw std::exception("No monitors");
		}

		if (!GetPhysicalMonitorsFromHMONITOR(hMonitor, dwPhysicalMonitorArraySize, pPhysicalMonitor))
		{
			throw std::exception("Problem getting physical monitors");
		}

		if (!GetMonitorBrightness(pPhysicalMonitor->hPhysicalMonitor, &dwMin, &dwCurrent, &dwMax))
		{
			throw std::exception("Problem getting monitor brightness");
		}

		minimum_brightness = dwMin;
		brightness = dwCurrent;
		maximum_brightness = dwMax;

		DestroyPhysicalMonitors(dwPhysicalMonitorArraySize, pPhysicalMonitor);

		free(pPhysicalMonitor);
	}

	void ScreenBrightnessWindowsPlugin::SetBrightness(const long brightness)
	{
		DWORD dwPhysicalMonitorArraySize = 0;
		HMONITOR hMonitor = MonitorFromWindow(window_handler_, MONITOR_DEFAULTTOPRIMARY);

		if (!GetNumberOfPhysicalMonitorsFromHMONITOR(hMonitor, &dwPhysicalMonitorArraySize))
		{
			throw std::exception("Problem getting numbers of monitor");
		}

		LPPHYSICAL_MONITOR pPhysicalMonitor = (LPPHYSICAL_MONITOR)malloc(dwPhysicalMonitorArraySize * sizeof(PHYSICAL_MONITOR));

		if (pPhysicalMonitor == NULL)
		{
			throw std::exception("No monitors");
		}

		if (!GetPhysicalMonitorsFromHMONITOR(hMonitor, dwPhysicalMonitorArraySize, pPhysicalMonitor))
		{
			throw std::exception("Problem getting physical monitors");
		}

		if (!SetMonitorBrightness(pPhysicalMonitor->hPhysicalMonitor, brightness))
		{
			throw std::exception("Problem setting monitor brightness");
		}

		DestroyPhysicalMonitors(dwPhysicalMonitorArraySize, pPhysicalMonitor);

		free(pPhysicalMonitor);
	}

	double ScreenBrightnessWindowsPlugin::GetBrightnessPercentage(const long brightness) const
	{
		if (brightness < 0)
		{
			return 0;
		}

		return static_cast<double>(brightness - minimum_brightness_) / (maximum_brightness_ - minimum_brightness_);
	}

	long ScreenBrightnessWindowsPlugin::GetBrightnessValueByPercentage(const double percentage) const
	{
		return static_cast<long>((percentage * (maximum_brightness_ - minimum_brightness_)) + minimum_brightness_);
	}

	void ScreenBrightnessWindowsPlugin::HandleGetSystemBrightnessMethodCall(const std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) const
	{
		result->Success(GetBrightnessPercentage(system_brightness_));
	}

	void ScreenBrightnessWindowsPlugin::HandleGetScreenBrightnessMethodCall(const std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		if (window_handler_ == nullptr)
		{
			result->Error("-10", "Unexpected error on window handler");
			return;
		}

		try
		{
			GetBrightness(minimum_brightness_, current_brightness_, maximum_brightness_);
			result->Success(GetBrightnessPercentage(current_brightness_));
		}
		catch (const std::exception& exception)
		{
			result->Error("-11", "Could not found monitor brightness value. error: " + *exception.what());
		}
	}

	void ScreenBrightnessWindowsPlugin::HandleSetScreenBrightnessMethodCall(const flutter::MethodCall<flutter::EncodableValue>& call, const std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
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

		const long changed_brightness = GetBrightnessValueByPercentage(brightness);
		try 
		{
			SetBrightness(changed_brightness);
			changed_brightness_ = changed_brightness;
			HandleCurrentBrightnessChanged(changed_brightness);
			result->Success(nullptr);
		}
		catch (const std::exception& exception)
		{
			result->Error("-1", "Unable to change screen brightness. error: " + *exception.what());
		}
	}

	void ScreenBrightnessWindowsPlugin::HandleResetScreenBrightnessMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		if (window_handler_ == nullptr)
		{
			result->Error("-10", "Unexpected error on window handler");
			return;
		}

		try
		{
			SetBrightness(system_brightness_);
			changed_brightness_ = -1;
			HandleCurrentBrightnessChanged(system_brightness_);
			result->Success(nullptr);
		}
		catch (const std::exception& exception)
		{
			result->Error("-1", "Unable reset screen brightness. error: " + *exception.what());
		}
	}

	void ScreenBrightnessWindowsPlugin::HandleCurrentBrightnessChanged(const long brightness)
	{
		if (current_brightness_change_stream_handler_ == nullptr)
		{
			return;
		}

		try
		{
			const double brightness_percentage = GetBrightnessPercentage(brightness);
			current_brightness_change_stream_handler_->AddCurrentBrightnessToEventSink(brightness_percentage);
		}
		catch (const std::exception& exception)
		{
			std::cout << exception.what() << std::endl;
		}
	}

	void ScreenBrightnessWindowsPlugin::HandleHasChangedMethodCall(const std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) const
	{
		result->Success(changed_brightness_ != -1);
	}

	void ScreenBrightnessWindowsPlugin::HandleIsAutoResetMethodCall(const std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		result->Success(is_auto_reset_);
	}

	void ScreenBrightnessWindowsPlugin::HandleSetAutoResetMethodCall(const flutter::MethodCall<flutter::EncodableValue>& call, const std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		const flutter::EncodableMap& args = std::get<flutter::EncodableMap>(*call.arguments());
		const bool is_auto_reset = std::get<bool>(args.at(flutter::EncodableValue("isAutoReset")));
		if (is_auto_reset == NULL) {
			result->Error("-2", "Unexpected error on null isAutoReset");
			return;
		}

		is_auto_reset_ = is_auto_reset;
		result->Success(nullptr);
	}
}

void ScreenBrightnessWindowsPluginRegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar)
{
	screen_brightness::ScreenBrightnessWindowsPlugin::RegisterWithRegistrar(
		flutter::PluginRegistrarManager::GetInstance()
		->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}