#include "../include/screen_brightness_windows/application_screen_brightness_change_stream_handler.h"

namespace screen_brightness
{
	void ApplicationScreenBrightnessChangeStreamHandler::AddApplicationScreenBrightnessToEventSink(double applicationScreenBrightness) const
	{
		if (sink_ == nullptr) {
			return;
		}

		sink_->Success(applicationScreenBrightness);
	}
}