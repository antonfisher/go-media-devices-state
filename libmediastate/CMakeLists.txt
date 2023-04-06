cmake_minimum_required(VERSION 3.21)

project(mediastate LANGUAGES C OBJC)

add_compile_options(-fmodules)

add_library(
    mediastate
    STATIC
    camera_darwin.m
    microphone_darwin.m
)

install(TARGETS mediastate)
