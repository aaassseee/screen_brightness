cmake_minimum_required(VERSION 3.15)
set(PROJECT_NAME "screen_brightness_windows")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "screen_brightness_windows_plugin")

add_library(${PLUGIN_NAME} SHARED
  "include/screen_brightness_windows/screen_brightness_windows_plugin.h"
  "src/screen_brightness_windows_plugin.cpp"
  "include/screen_brightness_windows/base_stream_handler.h"
  "include/screen_brightness_windows/current_brightness_change_stream_handler.h"
  "src/current_brightness_change_stream_handler.cpp"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# List of absolute paths to libraries that should be bundled with the plugin
set(screen_brightness_windows_bundled_libraries
  ""
  PARENT_SCOPE
)
