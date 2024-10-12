#ifndef FLUTTER_PLUGIN_SCREEN_BRIGHTNESS_WINDOWS_PLUGIN_SCREEN_BRIGHTNESS_CHANGED_STREAM_HANDLER_H
#define FLUTTER_PLUGIN_SCREEN_BRIGHTNESS_WINDOWS_PLUGIN_SCREEN_BRIGHTNESS_CHANGED_STREAM_HANDLER_H

#include "base_stream_handler.h"

namespace screen_brightness
{
	class ScreenBrightnessChangedStreamHandler final : public BaseStreamHandler<flutter::EncodableValue>
	{
	public:
		void AddScreenBrightnessToEventSink(double brightness) const;
	};
}

#endif