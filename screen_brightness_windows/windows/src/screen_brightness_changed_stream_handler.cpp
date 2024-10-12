#include "../include/screen_brightness_windows/screen_brightness_changed_stream_handler.h"

namespace screen_brightness
{
	void ScreenBrightnessChangedStreamHandler::AddScreenBrightnessToEventSink(double brightness) const
	{
		if (sink_ == nullptr) {
			return;
		}

		sink_->Success(brightness);
	}
}