set(CMAKE_TOOLS ${CMAKE_CURRENT_LIST_DIR})
include(${CMAKE_TOOLS}/scripts/print-info.cmake)

if (ANDROID)
    include(${CMAKE_TOOLS}/scripts/android.cmake)
else ()
  include(${CMAKE_TOOLS}/scripts/project.cmake)
endif ()

