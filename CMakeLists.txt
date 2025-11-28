cmake_minimum_required(VERSION 3.16)

project(FlightClient VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Network)

qt_standard_project_setup(REQUIRES 6.5)

# 添加子目录，编译 FluentUI 源码
add_subdirectory(FluentUI)

qt_add_executable(appFlightClient
    main.cpp
)

# QML 模块定义
qt_add_qml_module(appFlightClient
    URI FlightClient
    VERSION 1.0
    QML_FILES
        Main.qml
        pages/LoginPage.qml
        pages/FlightSearch.qml
        pages/Orders.qml
        pages/DashboardPage.qml
        pages/RegisterPage.qml
    RESOURCES
        figures/logo.png
        figures/loginBackground.png
        QML_FILES
)

set_target_properties(appFlightClient PROPERTIES
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

# === 重点修改在这里 ===
target_link_libraries(appFlightClient
    PRIVATE Qt6::Quick
    fluentuiplugin  # 将 FluentUI 改为 fluentuiplugin
)

target_include_directories(appFlightClient PRIVATE controller)
