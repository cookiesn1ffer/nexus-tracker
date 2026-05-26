cmake_minimum_required(VERSION 3.10)
project(runner LANGUAGES CXX)

set(BINARY_NAME "nexus_tracker")
set(APPLICATION_ID "com.nexustracker.app")

cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_RPATH "@executable_path")

get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
  set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release"
    CACHE STRING "Available build-types" FORCE)
else()
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Debug" CACHE
      STRING "Flutter build mode" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      "Debug" "Profile" "Release")
  endif()
endif()

set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")

add_definitions(-DUNICODE -D_UNICODE)

function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_14)
  target_compile_options(${TARGET} PRIVATE -Werror)
  target_compile_options(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:-O3>")
  target_compile_definitions(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:NDEBUG>")
endfunction()

set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/Flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

add_executable(${BINARY_NAME}
  "MainFlutterWindow.swift"
  "AppDelegate.swift"
  "main.swift"
)
apply_standard_settings(${BINARY_NAME})
target_link_libraries(${BINARY_NAME} PRIVATE flutter_macos)
add_dependencies(${BINARY_NAME} flutter_assemble)

include(flutter/generated_plugins.cmake)

set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "." COMPONENT Runtime)
install(DIRECTORY "$<TARGET_FILE_DIR:${BINARY_NAME}>/" DESTINATION "." COMPONENT Runtime)
install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "." COMPONENT Runtime)
install(FILES "${FLUTTER_LIBRARY}" DESTINATION "." COMPONENT Runtime)

if(PLUGIN_BUNDLED_LIBRARIES)
  install(FILES "${PLUGIN_BUNDLED_LIBRARIES}" DESTINATION "${BINARY_NAME}.app/Contents/Frameworks" COMPONENT Runtime)
endif()

set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${BUILD_BUNDLE_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${BUILD_BUNDLE_DIR}" COMPONENT Runtime)
install(FILES "${AOT_LIBRARY}" DESTINATION "." COMPONENT Runtime CONFIGURATIONS Profile;Release)
