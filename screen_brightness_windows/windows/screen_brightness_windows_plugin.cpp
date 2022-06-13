#include "include/screen_brightness_windows/screen_brightness_windows_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

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
		BaseStreamHandler();
		virtual ~BaseStreamHandler();

	protected:
		std::unique_ptr<flutter::EventSink<T>> sink;

		std::unique_ptr<flutter::StreamHandlerError<T>> OnListenInternal(
			const T* arguments,
			std::unique_ptr<flutter::EventSink<T>>&& events) override
		{
			sink = std::move(events);
			return nullptr;
		}

		std::unique_ptr<flutter::StreamHandlerError<T>> OnCancelInternal(
			const T* arguments) override
		{
			sink.reset();
			return nullptr;
		}
	};

	template<typename T>
	BaseStreamHandler<T>::BaseStreamHandler()
	{
	}

	template<typename T>
	BaseStreamHandler<T>::~BaseStreamHandler()
	{
		sink.reset();
	}

	// CurrentBrightnessChangeStreamHandler
	class CurrentBrightnessChangeStreamHandler : public BaseStreamHandler<flutter::EncodableValue>
	{
	public:
		CurrentBrightnessChangeStreamHandler();
		~CurrentBrightnessChangeStreamHandler();

		void AddCurrentBrightnessToEventSink(double brightness);
	};

	CurrentBrightnessChangeStreamHandler::CurrentBrightnessChangeStreamHandler()
	{
	}

	CurrentBrightnessChangeStreamHandler::~CurrentBrightnessChangeStreamHandler()
	{
	}

	void CurrentBrightnessChangeStreamHandler::AddCurrentBrightnessToEventSink(double brightness)
	{
		if (sink == nullptr) {
			return;
		}

		sink->Success(flutter::EncodableValue(brightness));
	}

	class ScreenBrightnessWindowsPlugin : public flutter::Plugin
	{
	public:
		static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

		ScreenBrightnessWindowsPlugin();

		virtual ~ScreenBrightnessWindowsPlugin();

	private:
		HWND windowHandler;

		DWORD systemBrightness;

		DWORD minimumBrightness;

		DWORD maximumBrightness;

		DWORD currentBrightness;

		DWORD changedBrightness;

		bool isAutoReset;

		CurrentBrightnessChangeStreamHandler* currentBrightnessChangeStreamHandler;

		// Called when a method is called on this plugin's channel from Dart.
		void HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue>& method_call,
			std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void GetBrightness(DWORD _minimumBrightness, DWORD brightness, DWORD _maximumBrightness);

		void SetBrightness(DWORD brightness);

		double GetBrighnessPercentage(DWORD brightness);

		DWORD GetBrightnessValueByPercentage(double percentage);

		void HandleGetSystemBrightnessMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void HandleGetScreenBrightnessMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void HandleSetScreenBrightnessMethodCall(
			const flutter::MethodCall<flutter::EncodableValue>& call,
			std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void HandleResetScreenBrightnessMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void HandleCurrentBrightnessChanged(DWORD changedBrightness);

		void HandleHasChangedMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void HandleIsAutoResetMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void HandleSetAutoResetMethodCall(const flutter::MethodCall<flutter::EncodableValue>& call,
			std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
	};

	// static
	void ScreenBrightnessWindowsPlugin::RegisterWithRegistrar(
		flutter::PluginRegistrarWindows* registrar) {
		auto plugin = std::make_unique<ScreenBrightnessWindowsPlugin>();

		auto methodChannel =
			std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
				registrar->messenger(), "github.com/aaassseee/screen_brightness",
				&flutter::StandardMethodCodec::GetInstance());
		methodChannel->SetMethodCallHandler
		([plugin_pointer = plugin.get()](const auto& call, auto result)
		{
			plugin_pointer->HandleMethodCall(call, std::move(result));
		});

		auto currentBrightnessChangeEventChannel =
			std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
				registrar->messenger(), "github.com/aaassseee/screen_brightness/change",
				&flutter::StandardMethodCodec::GetInstance());

		plugin->currentBrightnessChangeStreamHandler = new CurrentBrightnessChangeStreamHandler();
		std::unique_ptr<flutter::StreamHandler<flutter::EncodableValue>> uniquePointer
		{
			static_cast<flutter::StreamHandler<flutter::EncodableValue>*>(plugin->currentBrightnessChangeStreamHandler)
		};
		currentBrightnessChangeEventChannel->SetStreamHandler(std::move(uniquePointer));

		// init parameter
		plugin->windowHandler = registrar->GetView()->GetNativeWindow();
		plugin->GetBrightness(plugin->minimumBrightness, plugin->systemBrightness, plugin->maximumBrightness);

		registrar->AddPlugin(std::move(plugin));
	}

	ScreenBrightnessWindowsPlugin::ScreenBrightnessWindowsPlugin()
	{
		windowHandler = NULL;
		systemBrightness = NULL;
		systemBrightness = NULL;
		minimumBrightness = NULL;
		maximumBrightness = NULL;
		currentBrightness = NULL;
		changedBrightness = NULL;
		isAutoReset = true;
		currentBrightnessChangeStreamHandler = nullptr;
	}

	ScreenBrightnessWindowsPlugin::~ScreenBrightnessWindowsPlugin()
	{
	}

	void ScreenBrightnessWindowsPlugin::HandleMethodCall(
		const flutter::MethodCall<flutter::EncodableValue>& method_call,
		std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		if (method_call.method_name().compare("getSystemScreenBrightness") == 0)
		{
			HandleGetScreenBrightnessMethodCall(std::move(result));
			return;
		}

		if (method_call.method_name().compare("getScreenBrightness") == 0)
		{
			HandleGetScreenBrightnessMethodCall(std::move(result));
			return;
		}

		if (method_call.method_name().compare("setScreenBrightness") == 0)
		{
			HandleSetScreenBrightnessMethodCall(method_call, std::move(result));
			return;
		}

		if (method_call.method_name().compare("resetScreenBrightness") == 0)
		{
			HandleResetScreenBrightnessMethodCall(std::move(result));
			return;
		}

		if (method_call.method_name().compare("hasChanged"))
		{
			HandleHasChangedMethodCall(std::move(result));
			return;
		}

		if (method_call.method_name().compare("isAutoReset"))
		{
			HandleIsAutoResetMethodCall(std::move(result));
			return;
		}

		if (method_call.method_name().compare("setAutoReset"))
		{
			HandleSetAutoResetMethodCall(method_call, std::move(result));
			return;
		}

		result->NotImplemented();
	}

	void ScreenBrightnessWindowsPlugin::GetBrightness(DWORD _minimumBrightness, DWORD brightness, DWORD _maximumBrightness)
	{
		if (!GetMonitorBrightness(windowHandler, &_minimumBrightness, &brightness, &_maximumBrightness))
		{
			throw("Problem getting monitor brightness");
		}
	}

	void ScreenBrightnessWindowsPlugin::SetBrightness(DWORD brightness)
	{
		if (!SetMonitorBrightness(windowHandler, brightness))
		{
			throw("Problem setting monitor brightness");
		}
	}

	double ScreenBrightnessWindowsPlugin::GetBrighnessPercentage(DWORD brightness)
	{
		if (brightness == NULL)
		{
			return 0;
		}

		return (double)((brightness - minimumBrightness) / (maximumBrightness - minimumBrightness));
	}

	DWORD ScreenBrightnessWindowsPlugin::GetBrightnessValueByPercentage(double percentage)
	{
		return (DWORD)((percentage * (maximumBrightness - minimumBrightness)) + minimumBrightness);
	}

	void ScreenBrightnessWindowsPlugin::HandleGetSystemBrightnessMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		if (systemBrightness == NULL)
		{
			result->Error("-11", "Could not found system setting screen brightness value");
			return;
		}

		result->Success(flutter::EncodableValue(GetBrighnessPercentage(systemBrightness)));
	}

	void ScreenBrightnessWindowsPlugin::HandleGetScreenBrightnessMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		if (windowHandler == NULL)
		{
			result->Error("-10", "Unexpected error on window handler");
			return;
		}

		try
		{
			GetBrightness(minimumBrightness, currentBrightness, maximumBrightness);
			result->Success(flutter::EncodableValue(GetBrighnessPercentage(currentBrightness)));
		}
		catch (std::exception exception)
		{
			result->Error("-11", "Could not found monitor brightness value");
		}
	}

	void ScreenBrightnessWindowsPlugin::HandleSetScreenBrightnessMethodCall(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		if (windowHandler == NULL)
		{
			result->Error("-10", "Unexpected error on window handler");
			return;
		}

		const flutter::EncodableMap& args = std::get<flutter::EncodableMap>(*call.arguments());
		double brightness = std::get<double>(args.at(flutter::EncodableValue("brightness")));
		if (brightness == NULL)
		{
			result->Error("-2", "Unexpected error on null brightness");
			return;
		}

		if (minimumBrightness == NULL || maximumBrightness == NULL) {
			result->Error("-3", "Missing minimum or maximum brightness");
			return;
		}

		DWORD _changedBrightness = GetBrightnessValueByPercentage(brightness);
		if (!SetMonitorBrightness(windowHandler, _changedBrightness))
		{
			result->Error("-1", "Unable to change screen brightness");
			return;
		}

		changedBrightness = _changedBrightness;
		result->Success(nullptr);
	}

	void ScreenBrightnessWindowsPlugin::HandleResetScreenBrightnessMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		if (windowHandler == NULL)
		{
			result->Error("-10", "Unexpected error on window handler");
			return;
		}

		if (!SetMonitorBrightness(windowHandler, systemBrightness))
		{
			result->Error("-1", "Unable to change screen brightness");
			return;
		}

		changedBrightness = NULL;
		result->Success(nullptr);
	}

	void ScreenBrightnessWindowsPlugin::HandleCurrentBrightnessChanged(DWORD brightness)
	{
		if (currentBrightnessChangeStreamHandler == nullptr)
		{
			return;
		}

		double brighrnessPercentage = GetBrighnessPercentage(brightness);
		currentBrightnessChangeStreamHandler->AddCurrentBrightnessToEventSink(brighrnessPercentage);
	}

	void ScreenBrightnessWindowsPlugin::HandleHasChangedMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		result->Success(changedBrightness != NULL);
	}

	void ScreenBrightnessWindowsPlugin::HandleIsAutoResetMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		result->Success(isAutoReset);
	}

	void ScreenBrightnessWindowsPlugin::HandleSetAutoResetMethodCall(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		const flutter::EncodableMap& args = std::get<flutter::EncodableMap>(*call.arguments());
		bool _isAutoReset = std::get<bool>(args.at(flutter::EncodableValue("isAutoReset")));
		if (_isAutoReset == NULL) {
			result->Error("-2", "Unexpected error on null isAutoReset");
			return;
		}

		isAutoReset = _isAutoReset;
		result->Success(nullptr);
	}

}  // namespace

void ScreenBrightnessWindowsPluginRegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar)
{
	ScreenBrightnessWindowsPlugin::RegisterWithRegistrar(
		flutter::PluginRegistrarManager::GetInstance()
		->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}