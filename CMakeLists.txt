cmake_minimum_required(VERSION 3.0)

include(AddQtMacApp.cmake)

set(QT_MAC_QT_ROOT ${QT_MAC_QT_ROOT} CACHE STRING "qt sdk root folder")
set(QT_MAC_SOURCE_DIR ${QT_MAC_SOURCE_DIR} CACHE STRING "add_qt_mac_app CMakeLists.txt folder")

set(QT_MAC_CMAKE_FOUND ON CACHE BOOL "QtMacCMake have been found" FORCE)
set(QT_MAC_CMAKE_VERSION "1.1.1" CACHE STRING "QtMacCMake version" FORCE)

set(QT_MAC_DEPLOY_APP ${QT_MAC_DEPLOY_APP} CACHE STRING "macdeployqt program" FORCE)
