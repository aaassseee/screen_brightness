#include "include/screen_brightness_windows/screen_brightness_windows_plugin.h"

// This must be included before many other Windows headers.
#include <Windows.h>

#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <sstream>
#include <highlevelmonitorconfigurationapi.h>

#pragma comment(lib, "Dxva2.lib")

namespace
{

	// BaseStreamHandler
	template <typename T = flutter::EncodableValue>
	class BaseStreamHandler : public flutter::StreamHandler<T>
	{
	public:
		BaseStreamHandler() = default;

		~BaseStreamHandler() override;

		BaseStreamHandler(const BaseStreamHandler&) = delete;

		BaseStreamHandler& operator=(const BaseStreamHandler&) = delete;

	protected:
		std::unique_ptr<flutter::EventSink<T>> sink_;

		std::unique_ptr<flutter::StreamHandlerError<T>> OnListenInternal(
			const T* arguments,
			std::unique_ptr<flutter::EventSink<T>>&& events) override
		{
			sink_ = std::move(events);
			return nullptr;
		}

		std::unique_ptr<flutter::StreamHandlerError<T>> OnCancelInternal(
			const T* arguments) override
		{
			sink_.reset();
			return nullptr;
		}
	};

	template<typename T>
	BaseStreamHandler<T>::~BaseStreamHandler()
	{
		sink_.reset();
	}

	// CurrentBrightnessChangeStreamHandler
	class CurrentBrightnessChangeStreamHandler final : public BaseStreamHandler<flutter::EncodableValue>
	{
	public:
		CurrentBrightnessChangeStreamHandler() = default;

		~CurrentBrightnessChangeStreamHandler() override;

		CurrentBrightnessChangeStreamHandler(const CurrentBrightnessChangeStreamHandler&) = delete;

		CurrentBrightnessChangeStreamHandler& operator=(const CurrentBrightnessChangeStreamHandler&) = delete;

		void AddCurrentBrightnessToEventSink(double brightness) const;
	};

	CurrentBrightnessChangeStreamHandler::~CurrentBrightnessChangeStreamHandler()
	{
		BaseStreamHandler<flutter::EncodableValue>::~BaseStreamHandler();
	}

	void CurrentBrightnessChangeStreamHandler::AddCurrentBrightnessToEventSink(double brightness) const
	{
		if (sink_ == nullptr) {
			return;
		}

		sink_->Success(brightness);
	}

	class ScreenBrightnessWindowsPlugin final : public flutter::Plugin
	{
	public:
		static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

		ScreenBrightnessWindowsPlugin() = default;

		~ScreenBrightnessWindowsPlugin() override = default;

	private:
		HWND window_handler_ = nullptr;

		DWORD system_brightness_ = 0;

		DWORD minimum_brightness_ = 0;

		DWORD maximum_brightness_ = 100;

		DWORD current_brightness_ = 0;

		DWORD changed_brightness_ = 0;

		bool is_auto_reset_ = true;

		CurrentBrightnessChangeStreamHandler* current_brightness_change_stream_handler_ = nullptr;

		// Called when a method is called on this plugin's channel from Dart.
		void HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue>& method_call,
			std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void GetBrightness(DWORD minimum_brightness, DWORD brightness, DWORD maximum_brightness) const;

		void SetBrightness(DWORD brightness) const;

		[[nodiscard]] double GetBrightnessPercentage(DWORD brightness) const;

		[[nodiscard]] DWORD GetBrightnessValueByPercentage(double percentage) const;

		void HandleGetSystemBrightnessMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) const;

		void HandleGetScreenBrightnessMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) const;

		void HandleSetScreenBrightnessMethodCall(
			const flutter::MethodCall<flutter::EncodableValue>& call,
			std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void HandleResetScreenBrightnessMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void HandleCurrentBrightnessChanged(DWORD brightness) const;

		void HandleHasChangedMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) const;

		void HandleIsAutoResetMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void HandleSetAutoResetMethodCall(const flutter::MethodCall<flutter::EncodableValue>& call,
			std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
	};

	// static
	void ScreenBrightnessWindowsPlugin::RegisterWithRegistrar(
		flutter::PluginRegistrarWindows* registrar) {
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

	

	void ScreenBrightnessWindowsPlugin::GetBrightness(DWORD minimum_brightness, DWORD brightness, DWORD maximum_brightness) const
	{
		if (!GetMonitorBrightness(window_handler_, &minimum_brightness, &brightness, &maximum_brightness))
		{
			throw std::exception("Problem getting monitor brightness");
		}
	}

	void ScreenBrightnessWindowsPlugin::SetBrightness(const DWORD brightness) const
	{
		if (!SetMonitorBrightness(window_handler_, brightness))
		{
			throw std::exception("Problem setting monitor brightness");
		}
	}

	double ScreenBrightnessWindowsPlugin::GetBrightnessPercentage(const DWORD brightness) const
	{
		if (brightness == NULL)
		{
			return 0;
		}

		return static_cast<double>(brightness - minimum_brightness_) / (maximum_brightness_ - minimum_brightness_);
	}

	DWORD ScreenBrightnessWindowsPlugin::GetBrightnessValueByPercentage(const double percentage) const
	{
		return static_cast<DWORD>((percentage * (maximum_brightness_ - minimum_brightness_)) + minimum_brightness_);
	}

	void ScreenBrightnessWindowsPlugin::HandleGetSystemBrightnessMethodCall(const std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) const
	{
		if (system_brightness_ == NULL)
		{
			result->Error("-11", "Could not found system setting screen brightness value");
			return;
		}

		result->Success(GetBrightnessPercentage(system_brightness_));
	}

	void ScreenBrightnessWindowsPlugin::HandleGetScreenBrightnessMethodCall(const std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) const
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
			std::cout << exception.what() << std::endl;
			result->Error("-11", "Could not found monitor brightness value");
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

		if (minimum_brightness_ == NULL || maximum_brightness_ == NULL) {
			result->Error("-3", "Missing minimum or maximum brightness");
			return;
		}

		const DWORD changed_brightness = GetBrightnessValueByPercentage(brightness);
		if (!SetMonitorBrightness(window_handler_, changed_brightness))
		{
			result->Error("-1", "Unable to change screen brightness");
			return;
		}

		changed_brightness_ = changed_brightness;
		result->Success(nullptr);
	}

	void ScreenBrightnessWindowsPlugin::HandleResetScreenBrightnessMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		if (window_handler_ == nullptr)
		{
			result->Error("-10", "Unexpected error on window handler");
			return;
		}

		if (!SetMonitorBrightness(window_handler_, system_brightness_))
		{
			result->Error("-1", "Unable to change screen brightness");
			return;
		}

		changed_brightness_ = NULL;
		result->Success(nullptr);
	}

	void ScreenBrightnessWindowsPlugin::HandleCurrentBrightnessChanged(const DWORD brightness) const
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
			std::cout << exception.what();
		}
	}

	void ScreenBrightnessWindowsPlugin::HandleHasChangedMethodCall(const std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) const
	{
		result->Success(changed_brightness_ != NULL);
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
}  // namespace

void ScreenBrightnessWindowsPluginRegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar)
{
	ScreenBrightnessWindowsPlugin::RegisterWithRegistrar(
		flutter::PluginRegistrarManager::GetInstance()
		->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}