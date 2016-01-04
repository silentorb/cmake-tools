set(CMAKE_UTILITY ..)
include(print-info.cmake)

macro(create_library target)
  set(CURRENT_TARGET ${target})
  #message(WARNING "*${PROJECT_NAME} STREQUAL ${target}*")
  if (NOT "${PROJECT_NAME}" STREQUAL ${target})
    #    message(WARNING "No project for ${target}")
    add_project(${target})
  endif ()

  if ("${ARGN}" STREQUAL "")
    #    message("No sources for ${target}")
    file(GLOB_RECURSE SOURCES source/*.cpp source/*.c)
    file(GLOB_RECURSE HEADERS source/*.h)
    add_library(${target} ${SOURCES} ${HEADERS})
  else ()
    add_library(${target} ${ARGN})
  endif ()

  string(LENGTH "${CMAKE_SOURCE_DIR}" string_length)
  math(EXPR string_length "${string_length} + 1")
  string(SUBSTRING .. ${string_length} -1 current_path)
  get_filename_component(current_path ${current_path} DIRECTORY)
  set_target_properties(${target} PROPERTIES FOLDER ${current_path})
  #      message( "${current_path} ${temp}")

  include_directories(${CMAKE_UTILITY}/include) # for dllexport

  if (IOS)
    set_xcode_property(${target} IPHONEOS_DEPLOYMENT_TARGET "8.0")
  else ()
    set_target_properties(${target} PROPERTIES DEFINE_SYMBOL "EXPORTING_DLL")
  endif (IOS)

endmacro(create_library)

macro(create_test target)
  set(LAST_TARGET ${CURRENT_TARGET})
  set(CURRENT_TARGET ${target})

  file(GLOB_RECURSE SOURCES test/*.cpp test/*.h)
  add_executable(${target} ${SOURCES})

  include_directories(
    ${CMAKE_CURRENT_LIST_DIR}/test
  )

  string(LENGTH "${CMAKE_SOURCE_DIR}" string_length)
  math(EXPR string_length "${string_length} + 1")
  string(SUBSTRING .. ${string_length} -1 current_path)
  get_filename_component(current_path ${current_path} DIRECTORY)
  set_target_properties(${target} PROPERTIES FOLDER ${current_path})

  require(${LAST_TEST})

endmacro(create_test)

macro(require)
  foreach (library_name ${ARGN})
#    message("${PROJECT_NAME} require ${library_name}")
    find_package(${library_name} REQUIRED)

    if (IOS)
      target_link_libraries(${CURRENT_TARGET}
        $<TARGET_FILE:${library_name}>
        )
    else ()
      target_link_libraries(${CURRENT_TARGET}
        $<TARGET_LINKER_FILE:${library_name}>
        )
    endif ()

    add_dependencies(${CURRENT_TARGET}
      ${library_name}
      )
  endforeach ()
endmacro()

if (IOS)

  macro(add_project project_name)
    message(STATUS "ios ${project_name}")
    #include(${CMAKE_SOURCE_DIR}/toolchains/ios.cmake)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

    project(${project_name})

    set(${project_name}_DIR .. PARENT_SCOPE)

    include(${project_name}-config.cmake)
  endmacro(add_project)

  #  macro(create_library target)
  #    add_library(${target} ${ARGN})
  #    set_xcode_property(${target} IPHONEOS_DEPLOYMENT_TARGET "8.0")
  #  endmacro(create_library)

  macro(require_package project_name library_name)
    find_package(${library_name} REQUIRED)

    target_link_libraries(${project_name}
      $<TARGET_FILE:${library_name}>
      )

    add_dependencies(${project_name}
      ${library_name}
      )

  endmacro(require_package)

else ()

  macro(add_project project_name)
    if (${MINGW})
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
    endif ()

    project(${project_name})

    set(${project_name}_DIR .. PARENT_SCOPE)

    include(${project_name}-config.cmake)

  endmacro(add_project)

  macro(require_package project_name library_name)
    find_package(${library_name} REQUIRED)

    target_link_libraries(${project_name}
      $<TARGET_LINKER_FILE:${library_name}>
      )

    add_dependencies(${project_name}
      ${library_name}
      )

  endmacro(require_package)

endif ()


macro(add name)
  add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/${name})
endmacro(add)
