set(CMAKE_UTILITY ${CMAKE_CURRENT_LIST_DIR})
include(${CMAKE_UTILITY}/scripts/print-info.cmake)

if (ANDROID)
    include(${CMAKE_UTILITY}/scripts/android.cmake)
else ()
  include(${CMAKE_UTILITY}/scripts/project.cmake)
endif ()

