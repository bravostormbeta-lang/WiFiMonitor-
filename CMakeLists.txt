cmake_minimum_required(VERSION 3.20)

project(WiFiMonitor
    VERSION 0.1.0
    LANGUAGES CXX OBJCXX
)

# ============================================================
# C++ configuration
# ============================================================

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)


# ============================================================
# Qt
# ============================================================

find_package(Qt6 6.11 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.8)


# ============================================================
# macOS frameworks
# ============================================================

find_library(COREWLAN_FRAMEWORK
    CoreWLAN
    REQUIRED
)

find_library(FOUNDATION_FRAMEWORK
    Foundation
    REQUIRED
)

find_library(CORELOCATION_FRAMEWORK
    CoreLocation
    REQUIRED
)


# ============================================================
# Executable
# ============================================================

qt_add_executable(WiFiMonitor

    src/main.cpp

    # Core
    src/core/WiFiMonitor.cpp
    src/core/WiFiHistory.cpp

    # macOS platform
    src/platform/macos/WiFiMacOS.mm

    # UI / controller
    src/ui/WiFiMonitorController.cpp
)


# ============================================================
# QML module
# ============================================================

qt_add_qml_module(WiFiMonitor

    URI WiFiMonitor
    VERSION 1.0

    QML_FILES
        qml/Main.qml
)


# ============================================================
# macOS application bundle
# ============================================================

set_target_properties(WiFiMonitor PROPERTIES

    MACOSX_BUNDLE TRUE

    MACOSX_BUNDLE_GUI_IDENTIFIER
        "com.wifimonitor.app"

    MACOSX_BUNDLE_BUNDLE_NAME
        "WiFi Monitor"

    MACOSX_BUNDLE_INFO_PLIST
        "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist"
)


# ============================================================
# Libraries / frameworks
# ============================================================

target_link_libraries(WiFiMonitor

    PRIVATE

    Qt6::Quick

    ${COREWLAN_FRAMEWORK}
    ${FOUNDATION_FRAMEWORK}
    ${CORELOCATION_FRAMEWORK}
)