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

		bool isAutoReset = true;

		// Called when a method is called on this plugin's channel from Dart.
		void HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue>& method_call,
			std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void GetBrightness();
		void SetBrightness(DWORD brightness);

		void HandleGetSystemBrightnessMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
		void HandleGetScreenBrightnessMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
		void HandleSetScreenBrightnessMethodCall(
			const flutter::MethodCall<flutter::EncodableValue>& call,
			std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
		void HandleResetScreenBrightnessMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
		void HandleCurrentBrightnessChanged(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
		void HandleHasChangedMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
		void HandleIsAutoResetMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
		void HandleSetAutoResetMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
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

		currentBrightnessChangeEventChannel->SetStreamHandler(std::make_unique<CurrentBrightnessChangeStreamHandler>());

		// init parameter
		plugin->windowHandler = registrar->GetView()->GetNativeWindow();
		GetMonitorBrightness(plugin->windowHandler, &plugin->minimumBrightness, &plugin->systemBrightness, &plugin->maximumBrightness);

		registrar->AddPlugin(std::move(plugin));
	}

	ScreenBrightnessWindowsPlugin::ScreenBrightnessWindowsPlugin()
	{
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
			HandleSetAutoResetMethodCall(std::move(result));
			return;
		}

		result->NotImplemented();
	}

	void ScreenBrightnessWindowsPlugin::GetBrightness()
	{
		if (!GetMonitorBrightness(windowHandler, &minimumBrightness, &currentBrightness, &maximumBrightness))
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

	void ScreenBrightnessWindowsPlugin::HandleGetSystemBrightnessMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		if (windowHandler == NULL)
		{
			result->Error("-10", "Unexpected error on window handler");
			return;
		}

		try
		{
			GetBrightness();
			result->Success(flutter::EncodableValue((double)systemBrightness));
		}
		catch (std::exception exception)
		{
			result->Error("-11", "Could not found monitor brightness value");
		}
		
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
			GetBrightness();
			result->Success(flutter::EncodableValue((double)currentBrightness));
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

		if (!SetMonitorBrightness(windowHandler, (DWORD)brightness))
		{
			result->Error("-1", "Unable to change screen brightness");
			return;
		}
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
	}

	void ScreenBrightnessWindowsPlugin::HandleCurrentBrightnessChanged(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{}

	void ScreenBrightnessWindowsPlugin::HandleHasChangedMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{}

	void ScreenBrightnessWindowsPlugin::HandleIsAutoResetMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{}

	void ScreenBrightnessWindowsPlugin::HandleSetAutoResetMethodCall(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{}

	// BaseStreamHandler
	template <typename T = flutter::EncodableValue>
	class BaseStreamHandler : public flutter::StreamHandler<T>
	{
	public:
		BaseStreamHandler();
		virtual ~BaseStreamHandler();

	private:
		std::unique_ptr<flutter::EventSink<T>>&& sink;


	protected:
		std::unique_ptr<flutter::EventSink<T>>&& getSink()
		{
			return sink;
		}


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

	private:
		void AddCurrentBrightnessToEventSink(DWORD brightness);
	};

	CurrentBrightnessChangeStreamHandler::CurrentBrightnessChangeStreamHandler()
	{
	}

	CurrentBrightnessChangeStreamHandler::~CurrentBrightnessChangeStreamHandler()
	{
	}

	void CurrentBrightnessChangeStreamHandler::AddCurrentBrightnessToEventSink(DWORD brightness)
	{
		std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& sink = this->getSink();
		if (sink == nullptr) {
			return;
		}

		sink->Success(flutter::EncodableValue((double)brightness));
	}
	
}  // namespace

void ScreenBrightnessWindowsPluginRegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar)
{
	ScreenBrightnessWindowsPlugin::RegisterWithRegistrar(
		flutter::PluginRegistrarManager::GetInstance()
		->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}