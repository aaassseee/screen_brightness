## 2.1.3

* added ohos support [by ErBWs](https://github.com/ErBWs)
* updated resetScreenBrightness deprecated message to correct new method name [by cmenkemeller](https://github.com/cmenkemeller)

## 2.1.2

* updated README about permission on system brightness with Android [#47](https://github.com/aaassseee/screen_brightness/issues/47)
* changed with using application as mush as possible in Android [#45](https://github.com/aaassseee/screen_brightness/issues/45)

## 2.1.1

* fixed iOS and macOS compile errors [#43](https://github.com/aaassseee/screen_brightness/issues/43)

## 2.1.0

* added canChangeSystemBrightness for user to check if system brightness is changeable

## 2.0.1

* [Windows] fixed call HandleWindowProc will lead to crash [#38](https://github.com/aaassseee/screen_brightness/issues/38)

## 2.0.0+2

* updated README.md

## 2.0.0+1

* updated README.md

## 2.0.0

* support changing system brightness [#31](https://github.com/aaassseee/screen_brightness/issues/31) [#32](https://github.com/aaassseee/screen_brightness/issues/32)
* fixed dependency constraint not up-to-date problem [#30](https://github.com/aaassseee/screen_brightness/issues/30) [#33](https://github.com/aaassseee/screen_brightness/issues/33)

## 1.0.1

* added animate boolean

## 1.0.0

* updated minimum supported SDK version to Flutter 3.0/Dart 3.0.
* added static instance method

## 0.2.2+1

* updated topics
* updated dependencies

## 0.2.2

* added Windows support

## 0.2.1

* added macOS support

## 0.2.0

* upgraded dependecies
* changed dependencies version using version range
* updated README.md

## 0.1.4

* added is auto reset boolean for disable auto reset (iOS only)

## 0.1.3

* added has changed boolean

## 0.1.2+2

* updated screen_brightness_ios minimum version

## 0.1.2+1

* separated android and ios to different federated plugins

## 0.1.2

* updated get maximum brightness method in android (ref. [issue](https://github.com/aaassseee/screen_brightness/issues/1) & [solution](https://stackoverflow.com/questions/56203720/how-do-i-detect-the-screen-brightness-range-on-android))

## 0.1.1

* fixed broken repository link in pubspec

## 0.1.0 

(breaking change)
* migrated to [federated plugins](https://docs.google.com/document/d/1LD7QjmzJZLCopUrFAAE98wOUQpjmguyGTN2wd_89Srs)
* fixed issue [#2](https://github.com/aaassseee/screen_brightness/issues/2) by monitoring system brightness
* added onCurrentBrightnessChanged stream

## 0.0.4

* fixed issue [#1](https://github.com/aaassseee/screen_brightness/issues/1) Miui out of range error

## 0.0.3

* removed jcenter
* updated example with route aware

## 0.0.2

* updated pubspec.yaml with more project information

## 0.0.1

* Initial release
