cmake_minimum_required(VERSION 3.20)

project(WiFiMonitor
    VERSION 0.1.0
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.11 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(WiFiMonitor
    src/main.cpp
)

qt_add_qml_module(WiFiMonitor
    URI WiFiMonitorUI
    VERSION 1.0
    QML_FILES
        qml/Main.qml
)

target_link_libraries(WiFiMonitor
    PRIVATE
        Qt6::Quick
)