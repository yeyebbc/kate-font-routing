cmake_minimum_required(VERSION 3.20)

project(kate-font-routing VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_AUTOMOC ON)

find_package(ECM REQUIRED NO_MODULE)
list(APPEND CMAKE_MODULE_PATH "${ECM_MODULE_PATH}")

include(KDEInstallDirs)
include(KDECMakeSettings)

find_package(Qt6 6.9.0 REQUIRED COMPONENTS Gui)
find_package(KF6 6.0.0 REQUIRED COMPONENTS CoreAddons TextEditor)

kcoreaddons_add_plugin(katefontrouting
    SOURCES
        src/katefontroutingplugin.cpp
        src/katefontroutingplugin.json
    INSTALL_NAMESPACE "kf6/ktexteditor"
)

target_link_libraries(katefontrouting
    PRIVATE
        Qt6::Gui
        KF6::CoreAddons
        KF6::TextEditor
)
