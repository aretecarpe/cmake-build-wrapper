# CMake Build Wrapper

A light wrapper on cmake to aid in the creation of header-only, static, or shared libraries as well as executables on both Linux and Windows. Libraries or applications built using this wrapper should not require any special CMake operating system options, the operating system specifics are hidden away.

## Release notes

This section describes the release notes for the CMake Build Wrapper.

### CMake Build Wrapper 0.0.5

### [changelog...](./CHANGELOG.md)

## Getting Started

### Prerequisites

The only requirements is a CMake version greater than 3.20.

### Getting the CMake Build Wrapper

Using git clone the repository using the command below.
```
git clone https://github.com/aretecarpe/cmake-build-wrapper
```

## Usage
For an example utilizing the cmake build wrapper refer [here](https://github.com/aretecarpe/example-cmake-project)

### Project Config

To utilize the build wrapper you must have a [project-config.json](./cmake/example/project-config.json) for the entire project, which outlines the products as well as the name and description. This can be extended to add in a dependency list in the future as well.

* **name** - This option sets the name of the project.
* **description** - This takes in the description of the project.
* **version** - This option sets the project version.
* **products** - This is a list of all the products under this project.
* **cpp_standard** - This option can be used to select what C++ version you want, it can either be 11, 14, 17, or 23.

### Product Config

Any product you have under the project must contain its own [product-config.json](./cmake/example/product-config.json), which outlines product specifics, such as name, version, product type, cpp standard, and the source and deployed headers.

* **name** - This sets the name of the product, it will also be used as the name for the package which is used in the find_package() command.
* **description** - This takes in the description of the product.
* **type** - This option can either be: header-only, static, shared, or binary.
* **version** - This option is to set the version for the product, it can be used to query the package for a specific version using find_package(product version REQUIRED). 
* **install_artifact** - This option will install this product on your system.
* **source (Optional)** - This is a list of all the source files. If none are listed will parse your source directory for the files.
* **deployed_headers (Optional)** - This is a list of all the files you want deployed in the "include" folder. If none are listed will parse your source directory for the files.

There are a couple ways to use the CMake Build Wrapper, below are two ways: one way is using the CMake Tools extension, the other is via the command line.

#### CMake Tools

The wrapper can be used in conjunction with the CMake Tools extension in VScode alongside [cmake_presets](https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html). There a couple of supplied presets for linux and windows [here](./cmake/presets/).

#### Command Line

The wrapper can work without any special extensions. All you'll need is a terminal and CMake. There are a couple of options that can be set to enhance the installation of the application or library.

* **-DCMAKE_BUILD_TYPE={Debug/Release}** - This is the level of optimization wanted, which can either be "Debug" or "Release"
* **-DCMAKE_INSTALL_PREFIX={path_to_install}** - This is where the packages will be installed, whether it be your library or application.
* **-DARCHITECTURE={system_architecture}** - This is what will be specified on the package it's installed, it defaults to "x86_64"
* **-DOS={operating_system}** - This is what will be specifed on the package when it's installed, it defaults to "unknown"