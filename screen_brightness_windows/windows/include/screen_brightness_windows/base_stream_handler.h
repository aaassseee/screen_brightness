#ifndef FLUTTER_PLUGIN_SCREEN_BRIGHTNESS_WINDOWS_PLUGIN_BASE_STREAM_HANDLER_H
#define FLUTTER_PLUGIN_SCREEN_BRIGHTNESS_WINDOWS_PLUGIN_BASE_STREAM_HANDLER_H

#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/encodable_value.h>

namespace screen_brightness
{
	template <typename T = flutter::EncodableValue>
	class BaseStreamHandler : public flutter::StreamHandler<T>
	{
	public:
		virtual ~BaseStreamHandler() 
		{
			sink_.reset();
		}

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
}

#endif