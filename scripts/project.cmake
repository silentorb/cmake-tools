
macro(create_library target)
  set(CURRENT_TARGET ${target})
  #message(WARNING "*${PROJECT_NAME} STREQUAL ${target}*")
  if (NOT "${PROJECT_NAME}" STREQUAL ${target})
    #    message(WARNING "No project for ${target}")
    add_project(${target})
  endif ()

  if ("${ARGN}" STREQUAL "")
    #    message("No sources for ${target}")
    file(GLOB_RECURSE SOURCES source/*.cpp source/*.mm source/*.m source/*.c)

    file(GLOB_RECURSE HEADERS source/*.h)
    add_library(${target} ${SOURCES} ${HEADERS})
  else ()
    add_library(${target} ${ARGN})
  endif ()

  #  if (NOT ANDROID)
  #    set("TARGET_FILE_DIR_${target}" $<TARGET_FILE_DIR:${target}>)
  ##    set("TARGET_LINKER_FILE_${target}" $<TARGET_LINKER_FILE:${target}>)
  #    set("TARGET_FILE_${target}" $<TARGET_FILE:${target}>)
  #  endif ()

  if (NOT CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    string(LENGTH "${CMAKE_SOURCE_DIR}" string_length)
    math(EXPR string_length "${string_length} + 1")
    string(SUBSTRING ${CMAKE_CURRENT_SOURCE_DIR} ${string_length} -1 current_path)
    get_filename_component(current_path ${current_path} DIRECTORY)
    if (NOT ANDROID)
      set_target_properties(${target} PROPERTIES FOLDER ${current_path})
    endif ()
    #      message( "${current_path} ${temp}")
  endif ()

  include_directories(${CMAKE_TOOLS}/include) # for dllexport

  if (IOS)
    set_xcode_property(${target} IPHONEOS_DEPLOYMENT_TARGET "8.0")
  else ()
    set_target_properties(${target} PROPERTIES DEFINE_SYMBOL "EXPORTING_DLL")
  endif (IOS)

endmacro(create_library)

macro(get_relative_path result root_path path)
  string(LENGTH "${root_path}" string_length)
  math(EXPR string_length "${string_length} + 1")
  string(SUBSTRING ${path} ${string_length} -1 ${result})
endmacro(get_relative_path)

macro(create_test target)
  set(LAST_TARGET ${CURRENT_TARGET})
  set(CURRENT_TARGET ${target})

  file(GLOB_RECURSE SOURCES test/*.cpp test/*.h)
  add_executable(${target} ${SOURCES})

  include_directories(
    ${CMAKE_CURRENT_LIST_DIR}/test
  )

  if (NOT CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    string(LENGTH "${CMAKE_SOURCE_DIR}" string_length)
    math(EXPR string_length "${string_length} + 1")
    string(SUBSTRING ${CMAKE_CURRENT_SOURCE_DIR} ${string_length} -1 current_path)
    get_filename_component(current_path ${current_path} DIRECTORY)
    set_target_properties(${target} PROPERTIES FOLDER ${current_path})
  endif ()

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
    elseif (NOT ANDROID)
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

    set(${project_name}_DIR ${CMAKE_CURRENT_LIST_DIR} PARENT_SCOPE)

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

    if (CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
      set(${project_name}_DIR ${CMAKE_CURRENT_LIST_DIR})
    else ()
      set(${project_name}_DIR ${CMAKE_CURRENT_LIST_DIR} PARENT_SCOPE)
    endif ()

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

macro(add_resources resources_dir)

  if (IOS)
    file(GLOB_RECURSE BUNDLE_RESOURCES ${resources_dir}/*)
    add_executable("${CURRENT_TARGET}_resources" MACOSX_BUNDLE ${BUNDLE_RESOURCES})
    get_filename_component(base_path ${resources_dir} ABSOLUTE)

    foreach (resource_path ${BUNDLE_RESOURCES})
      #message("hello ${base_path}, ${resource_path}")
      get_filename_component(resource_dir ${resource_path} DIRECTORY)
      get_relative_path(relative_dir ${base_path} ${resource_dir})
      message("resource ${resource_path}")
      message("resource ${relative_dir}")
      #set_source_files_properties(${BUNDLE_RESOURCES} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)

    endforeach ()
    #set_source_files_properties(${BUNDLE_RESOURCES} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
    #SET_TARGET_PROPERTIES("${CURRENT_TARGET}_resources" PROPERTIES LINKER_LANGUAGE C)
    set(ALL_RESOURCES "${ALL_RESOURCES} BUNDLE_RESOURCES" PARENT_SCOPE)
  else ()
    #MESSAGE(WARNING "${CMAKE_CURRENT_LIST_DIR}/${resource_dir} $<TARGET_FILE_DIR:${CURRENT_TARGET}>/${resources_dir}")
    add_custom_command(TARGET ${CURRENT_TARGET} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy_directory
      ${CMAKE_CURRENT_LIST_DIR}/${resources_dir} $<TARGET_FILE_DIR:${CURRENT_TARGET}>/${resources_dir})
  endif ()

endmacro(add_resources)

macro(finish_mythic)

endmacro(finish_mythic)

macro(add_sources)
  target_sources(${CURRENT_TARGET} PUBLIC ${ARGN})
endmacro()

function(set_lib_prefix varname)
  string(SUBSTRING "${${varname}}" 0 3 libprefix)
#  message(WARNING "substring ${libprefix} ${libname}")
  if (NOT libprefix STREQUAL "lib")
    set(${varname} "lib${${varname}}" PARENT_SCOPE)
  endif ()
endfunction()

macro(link_external path)
#  message(WARNING "args... ${ARGV0} ${ARGV1}")
  set(libname "${ARGV1}")
  if (NOT libname)
#    message(WARNING "args 2")
    set(libname ${path})
  endif ()

  set(dllname "${ARGV2}")
  if (NOT dllname)
    set(dllname ${libname})
  endif ()

  if (MINGW)
    set(libname "${libname}.dll.a")

    set_lib_prefix(libname)
    set_lib_prefix(dllname)
#    string(SUBSTRING "${libname}" 0 3 libprefix)
#    message(WARNING "substring ${libprefix} ${libname}")
#    if (NOT libprefix STREQUAL "lib")
#      set(libname "lib${libname}")
#    endif ()

  elseif (MSVC)
    set(libname "${libname}.lib")
  endif ()

  target_link_libraries(${CURRENT_TARGET} ${MYTHIC_DEPENDENCIES}/${path}/lib/${libname})

  add_custom_command(TARGET ${CURRENT_TARGET} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy ${MYTHIC_DEPENDENCIES}/${path}/bin/${dllname}.dll $<TARGET_FILE_DIR:${CURRENT_TARGET}>
    )
endmacro()
