#ifndef FLUTTER_PLUGIN_SCREEN_BRIGHTNESS_WINDOWS_PLUGIN_APPLICATION_SCREEN_BRIGHTNESS_CHNAGE_STREAM_HANDLER_H
#define FLUTTER_PLUGIN_SCREEN_BRIGHTNESS_WINDOWS_PLUGIN_APPLICATION_SCREEN_BRIGHTNESS_CHNAGE_STREAM_HANDLER_H

#include "base_stream_handler.h"

namespace screen_brightness
{
	class ApplicationScreenBrightnessChangeStreamHandler final : public BaseStreamHandler<flutter::EncodableValue>
	{
	public:
		void AddApplicationScreenBrightnessToEventSink(double applicationScreenBrightness) const;
	};
}

#endif