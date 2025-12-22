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
        figures/123.jpg
        QML_FILES
        QML_FILES pages/UserCenterPage.qml
        QML_FILES pages/Avatar.qml
        QML_FILES
        QML_FILES pages/LoginPage1.qml
        QML_FILES pages/BurstAvatar.qml
        QML_FILES pages/HomePage.qml
        QML_FILES pages/HistoryPage.qml
        QML_FILES pages/AiChatPage.qml
        QML_FILES pages/BookingPage.qml
        QML_FILES pages/PayDialog.qml
        QML_FILES pages/About.qml
        QML_FILES pages/OrderDetailPage.qml
        QML_FILES pages/AdminDashboardPage.qml
        QML_FILES pages/AddFlight.qml
        QML_FILES pages/ModifyFlight.qml
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
