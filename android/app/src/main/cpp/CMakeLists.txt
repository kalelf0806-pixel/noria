cmake_minimum_required(VERSION 3.18.1)
project(noria_native CXX)

add_library(
    noria_native
    SHARED
    noria_native.cpp
)

find_library(
    log-lib
    log
)

target_link_libraries(
    noria_native
    ${log-lib}
)
