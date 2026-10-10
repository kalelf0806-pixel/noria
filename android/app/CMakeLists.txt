cmake_minimum_required(VERSION 3.22.1)
project(noria_native CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Options d'optimisation agressive pour Snapdragon 888 (Cortex-X1 / A78 / Hexagon)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -flto -march=armv8.4-a+crypto+fp16+dotprod")

# Bibliothèque partagée native de Noria
add_library(
    noria_native
    SHARED
    noria_native.cpp
)

# Liaison des bibliothèques système Android (log, liaison JNI, threads)
find_library(log-lib log)
find_library(android-lib android)

target_link_libraries(
    noria_native
    ${log-lib}
    ${android-lib}
)
