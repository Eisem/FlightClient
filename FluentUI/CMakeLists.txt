cmake_minimum_required(VERSION 3.20)

project(FluentUI VERSION 1.0)

if (MSVC)
    #让Release也生成pdb文件
    set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} /DEBUG /OPT:REF /OPT:ICF")
    set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} /DEBUG /OPT:REF /OPT:ICF")
endif ()

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/.cmake/)

# === 修改 1: 注释掉 Git 版本获取，防止报错 ===
# include(GetGitRevisionDescription)

# === 修改 2: 默认关闭示例程序 (OFF)，解决路径拷贝报错 ===
option(FLUENTUI_BUILD_EXAMPLES "Build FluentUI demo applications." OFF)
option(FLUENTUI_BUILD_STATIC_LIB "Build static library." OFF)

find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core)

add_subdirectory(src)

#Release也支持日志打印代码位置
# 注意：fluentuiplugin 这个目标是在 src/CMakeLists.txt 里定义的
# 如果这里报错找不到目标，说明 src 目录没编译成功，通常是因为上面的配置问题
target_compile_definitions(fluentuiplugin
        PRIVATE
        QT_MESSAGELOGCONTEXT
)

if (FLUENTUI_BUILD_EXAMPLES)
    add_subdirectory(example)
endif ()

message("------------------------ FluentUI ------------------------")
message("Build FluentUI demo applications.: ${FLUENTUI_BUILD_EXAMPLES}")
message("Build static library.: ${FLUENTUI_BUILD_STATIC_LIB}")
# message("Path to FluentUI plugin.: ${FLUENTUI_QML_PLUGIN_DIRECTORY}")
