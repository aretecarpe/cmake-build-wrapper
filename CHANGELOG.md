## Changelog

### cmake-build-wrapper

## 0.0.5
* Fix for conditionally enabling tests and examples via cmake vars.

## 0.0.4
* Fix for updating cmake cache
* All projects now utilize namespaces by default.

## 0.0.3
* Fix for windows target properties
* Fix for presets for windows.

## 0.0.2
* Added support for multi-level include installs for projects.
* Added support for non-listing of header/source files. We will automatically find .h/.hpp headers or .cpp/.cxx source files.
* Moved cpp_standard to project-config.json instead of having it inside of product-config.json

## 0.0.1
This is the initial release of cmake-build-wrapper
* Added support for building header-only, static, shared libraries as well as binary applications for C++ projects.