cmake_minimum_required(VERSION 3.10)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")

# Configuration provided via flutter tool.
include(${EPHEMERAL_DIR}/generated_config.cmake)

# TODO: Move the rest of this into files in ephemeral. See
# https://github.com/flutter/flutter/issues/57146.
set(WRAPPER_ROOT "${EPHEMERAL_DIR}/cpp_client_wrapper")

# === Flutter Library ===
set(FLUTTER_LIBRARY "${EPHEMERAL_DIR}/flutter_linux_bundle/linux/libflutter_linux_gtk.so")

# Published to parent scope for install step.
set(FLUTTER_LIBRARY ${FLUTTER_LIBRARY} PARENT_SCOPE)
set(FLUTTER_ICU_DATA_FILE "${EPHEMERAL_DIR}/icudtl.dat" PARENT_SCOPE)
set(PROJECT_BUILD_DIR "${PROJECT_DIR}/build/" PARENT_SCOPE)

# === Wrapper ===
list(APPEND CPP_WRAPPER_SOURCES_CORE
  "${WRAPPER_ROOT}/engine_method_result.cc"
  "${WRAPPER_ROOT}/flutter_view_controller.cc"
  "${WRAPPER_ROOT}/standard_codec.cc"
)
add_library(flutter_wrapper_app STATIC ${CPP_WRAPPER_SOURCES_CORE})
target_link_libraries(flutter_wrapper_app PUBLIC PkgConfig::GTK)
target_link_libraries(flutter_wrapper_app PUBLIC flutter)
add_dependencies(flutter_wrapper_app flutter_assemble)

# === Flutter tool ===
set(FLUTTER_TOOL "${FLUTTER_ROOT}/bin/flutter" CACHE STRING "" FORCE)

# Flutter build tool.
set(FLUTTER_ASSEMBLE "${CMAKE_CURRENT_BINARY_DIR}/flutter_assemble.stamp")
add_custom_command(
  OUTPUT ${FLUTTER_ASSEMBLE}
  COMMAND ${FLUTTER_TOOL} ARGS build "${FLUTTER_BUILD}" --target="lib/main.dart"
    --output="${EPHEMERAL_DIR}"
  COMMAND ${CMAKE_COMMAND} -E touch ${FLUTTER_ASSEMBLE}
  VERBATIM
)
add_custom_target(flutter_assemble DEPENDS ${FLUTTER_ASSEMBLE})
