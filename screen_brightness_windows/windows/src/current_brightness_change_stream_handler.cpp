#include "../include/screen_brightness_windows/current_brightness_change_stream_handler.h"

namespace screen_brightness
{
	void CurrentBrightnessChangeStreamHandler::AddCurrentBrightnessToEventSink(double brightness) const
	{
		if (sink_ == nullptr) {
			return;
		}

		sink_->Success(brightness);
	}
}