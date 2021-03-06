unset(MSVC)
unset(MINGW)
message("Generating for Android")
cmake_policy(SET CMP0011 NEW)
cmake_policy(SET CMP0057 NEW)

macro(append_target_property property_name value)
  set(${CURRENT_TARGET}_${property_name} ${${CURRENT_TARGET}_${property_name}} ${value})
  set(${CURRENT_TARGET}_${property_name} ${${CURRENT_TARGET}_${property_name}} PARENT_SCOPE)
endmacro()

macro(set_target_property property_name value)
  set(${CURRENT_TARGET}_${property_name} ${value})
  set(${CURRENT_TARGET}_${property_name} ${${CURRENT_TARGET}_${property_name}} PARENT_SCOPE)
endmacro()

macro(add_library target)
  #  message("add_library ${target} ${ARGV1}")
  if (NOT "${ARGV1}" STREQUAL "SHARED")
    create_library(${target} ${ARGN})
    #    message("target ${target}")
  endif ()
endmacro()

macro(project target)
  #  message("project ${target}")
  set(CURRENT_TARGET ${target})
  set(LOCAL_PROJECT ${target})
  #  message("project ${target}")
  set(PROJECT_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
  set(${target}_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})

  file(RELATIVE_PATH relative_path ${CMAKE_ROOT} ${CMAKE_CURRENT_SOURCE_DIR})

  #  message("**** ${CMAKE_SOURCE_DIR}    ${CMAKE_CURRENT_SOURCE_DIR}")
  if (${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_CURRENT_SOURCE_DIR})
    set(PROJECT_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}")
    set(${target}_BINARY_DIR ${PROJECT_BINARY_DIR})
  else ()
    string(LENGTH "${CMAKE_SOURCE_DIR}" root_length)
    math(EXPR root_length "${root_length} + 1")
    string(SUBSTRING ${CMAKE_CURRENT_SOURCE_DIR} ${root_length} -1 relative_path)
    #  message("Relative ${relative_path}")
    set(PROJECT_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/${relative_path}")
    set(${target}_BINARY_DIR ${PROJECT_BINARY_DIR})
  endif ()
  get_directory_property(has_parent PARENT_DIRECTORY)
  if (has_parent)
    set(PROJECT_NAME ${target} PARENT_SCOPE)
    set(PROJECT_NAME ${target})
  else ()
    set(PROJECT_NAME ${target})
  endif ()

endmacro()

macro(android_create_entrypoint target)
  #  add_custom_target(${target})
  #  set(${target}_sources ${ARGN} PARENT_SCOPE)
  create_library(${target} ${ARGN})
  set(${target}_is_executable 1 PARENT_SCOPE)
  set(application_name ${target} PARENT_SCOPE)

endmacro()

macro(add_sources)
  foreach (source ${ARGN})
    get_filename_component(absolute_path ${source} ABSOLUTE)
    set(${CURRENT_TARGET}_sources ${${CURRENT_TARGET}_sources} ${absolute_path})
  endforeach ()
  set(${CURRENT_TARGET}_sources ${${CURRENT_TARGET}_sources} PARENT_SCOPE)
endmacro()

macro(add_system_libraries)
  if (NOT "${ARGN}" STREQUAL "")
    set(${CURRENT_TARGET}_system_libraries ${${CURRENT_TARGET}_system_libraries} ${ARGN})
    list(REMOVE_DUPLICATES ${CURRENT_TARGET}_system_libraries)
    set(${CURRENT_TARGET}_system_libraries ${${CURRENT_TARGET}_system_libraries} PARENT_SCOPE)
  endif ()
endmacro()

macro(include_directories)
  set(args "${ARGN}")
  foreach (arg IN LISTS args)
    if (NOT ${arg} STREQUAL "BEFORE" AND NOT ${arg} STREQUAL "AFTER")
      append_target_property(includes ${arg})
    endif ()
  endforeach ()
endmacro()

macro(android_add_project project_name)
  message("project ${project_name}")
  if (${MINGW})
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
  endif ()

  project(${project_name})
  if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/${project_name}-config.cmake")
    set(${project_name}_project_path ${CMAKE_CURRENT_LIST_DIR})
    set(${project_name}_project_path ${CMAKE_CURRENT_LIST_DIR} PARENT_SCOPE)
    include(${project_name}-config.cmake)
  else ()
    set(${project_name}_project_includes "${CMAKE_CURRENT_LIST_DIR}/source" PARENT_SCOPE)
    include_directories(${CMAKE_CURRENT_LIST_DIR}/source)
  endif ()

  #  set(${project_name}_DIR ${CMAKE_CURRENT_LIST_DIR} PARENT_SCOPE)
  #  include(${project_name}-config.cmake OPTIONAL)

endmacro()

macro(create_library target)

  #  message("${target} - ${LOCAL_PROJECT}")
  set(EXACT_CURRENT_TARGET ${target})
  if (NOT LOCAL_PROJECT)
    set(CURRENT_TARGET ${target})
    set(LOCAL_TARGET ${target})
  endif ()

  if (NOT "${PROJECT_NAME}" STREQUAL ${target})
    android_add_project(${CURRENT_TARGET})
  endif ()

  set(all_libraries ${all_libraries} ${CURRENT_TARGET} PARENT_SCOPE)

  if (NOT "${ARGN}" STREQUAL "")
    set(args "${ARGN}")
    unset(${CURRENT_TARGET}_sources) # For when the library uses that same named variable to populate the source args.
    #    message("${CURRENT_TARGET} ${${CURRENT_TARGET}_sources}")
    foreach (arg IN LISTS args)
      append_target_property(sources "${CMAKE_CURRENT_SOURCE_DIR}/${arg}")
    endforeach ()
  else ()
    file(GLOB_RECURSE SOURCES source/*.cpp source/*.c)
    if (SOURCES)
      #      message("${target} ${SOURCES}")
      append_target_property(sources "${SOURCES}")
      #      message("${${target}_sources}")
    endif ()
  endif ()

  string(LENGTH "${CMAKE_SOURCE_DIR}" string_length)
  math(EXPR string_length "${string_length} + 1")
  string(SUBSTRING ${CMAKE_CURRENT_SOURCE_DIR} ${string_length} -1 current_path)
  set(${CURRENT_TARGET}_relative_path ${current_path} PARENT_SCOPE)
  get_filename_component(current_path ${current_path} DIRECTORY)
  set(${CURRENT_TARGET}_containing_path ${current_path} PARENT_SCOPE)

  if (COMMAND on_create_target)
    on_create_target()
  endif ()

endmacro(create_library)

macro(get_relative_path result root_path path)
  string(LENGTH "${root_path}" string_length)
  math(EXPR string_length "${string_length} + 1")
  string(SUBSTRING ${path} ${string_length} -1 ${result})
endmacro(get_relative_path)

macro(create_test target)

endmacro(create_test)

macro(android_add_library library_name)
  #  set(${CURRENT_TARGET}_libraries ${${CURRENT_TARGET}_libraries} ${library_name})
  #  set(${CURRENT_TARGET}_libraries ${${CURRENT_TARGET}_libraries} PARENT_SCOPE)
  append_target_property(libraries ${library_name})
endmacro()

macro(append_dependency_hierarchy libraries output_variable parent_name)
  set(parent ${parent_name})
  foreach (library_name ${libraries})
    list(FIND ${output_variable} ${library_name} library_index)
    if (${library_index} EQUAL "-1")
      list(APPEND ${output_variable} ${library_name})
      append_dependency_hierarchy("${${library_name}_dependencies}" ${output_variable} ${library_name})
    endif ()
  endforeach ()
endmacro()

macro(get_dependency_hierarchy libraries output_variable)
  set(${output_variable} "")
  append_dependency_hierarchy("${libraries}" ${output_variable} "")
endmacro()

macro(require)
  if (LOCAL_TARGET)
    get_dependency_hierarchy("${ARGN}" all_dependencies)
    foreach (library_name ${all_dependencies})
      if (${library_name}_project_includes)
        include_directories(${${library_name}_project_includes})
      else ()
#        message(hello " ${library_name}")
        include(${${library_name}_project_path}/${library_name}-config.cmake)
      endif ()
    endforeach ()

    foreach (library_name ${ARGN})
      if (${library_name} IN_LIST all_libraries)
        android_add_library(${library_name})
        add_system_libraries(${${library_name}_system_libraries})
      endif ()

      list(APPEND "${CURRENT_TARGET}_dependencies" "${library_name}")
      set(${CURRENT_TARGET}_dependencies ${${CURRENT_TARGET}_dependencies} PARENT_SCOPE)

    endforeach ()
  endif ()
endmacro()

macro(add name)
  add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/${name})
endmacro(add)

macro(add_resources resources_dir)
  set(${CURRENT_TARGET}_resources_dir ${CMAKE_CURRENT_LIST_DIR}/${resources_dir} PARENT_SCOPE)
endmacro(add_resources)

macro(finish_cmake)
  include(${CMAKE_TOOLS}/generators/android/android-generator.cmake)
  message(FATAL_ERROR "This is not a real error, but the only way to prevent CMake from generating unneeded files.")
endmacro(finish_cmake)


macro(doctor varname path name extension)
  if (path AND EXISTS ${path}/${name}.${extension})
  else ()
    string(SUBSTRING "${name}" 0 3 libprefix)
    if (NOT libprefix STREQUAL "lib")
      set(name "lib${name}")
    endif ()
  endif ()

  set(name2 name)
  set(extension2 extension)
  set(${varname} "${${name2}}.${${extension2}}" PARENT_SCOPE)
endmacro()

function(doctor_dynamic varname path)
  set(name ${${varname}})
  set(extension "a")

  doctor(${varname} ${path} ${name} ${extension})

endfunction()

function(doctor_static varname path is_dynamic)
  set(name ${${varname}})
  set(extension "a")
  doctor(${varname} ${path} ${name} ${extension})

endfunction()

macro(include_external_directory path)
  set(include_suffix "${ARGV1}")
  if (NOT include_suffix)
    set(include_suffix "")
  else ()
    set(include_suffix "/${include_suffix}")
  endif ()
#message("${CURRENT_TARGET} ${MYTHIC_DEPENDENCIES}/${path}/include${include_suffix}")
  include_directories(${MYTHIC_DEPENDENCIES}/${path}/include${include_suffix})

endmacro()

macro(link_external_static path)
  set(libname "${ARGV1}")
  if (NOT libname)
    set(libname ${path})
  endif ()

  android_add_library(${path})
  include_directories(${MYTHIC_DEPENDENCIES}/${path}/include${include_suffix})
endmacro()

macro(link_external path)
  set(libname "${ARGV1}")
  if (NOT libname)
    set(libname ${path})
  endif ()

  set(dllname "${ARGV2}")
  if (NOT dllname)
    set(dllname ${libname})
  endif ()

  link_external_static(${path} ${libname})
endmacro()

macro(set_target_properties target PROPERTIES)
  if ("${target}" STREQUAL "${EXACT_CURRENT_TARGET}")
    if (${ARGV2} STREQUAL DEFINE_SYMBOL)
      #      message("define ${target} ${ARGV3}")
      append_target_property(defines ${ARGV3})
    endif ()
  endif ()
endmacro()

macro(install)
endmacro()

if (BUILDING_DEPENDENCIES)
  macro(find_package)
  endmacro()
endif ()

macro(target_include_directories)
  #  set(args "${ARGN}")
  #  foreach (arg IN LISTS args)
  #    if (NOT arg STREQUAL "INTERFACE")
  #
  #    endif ()
  #  endforeach ()
endmacro()

macro(export)
endmacro()

macro(target_link_libraries target)
  #  require(${ARGN})
  set(args "${ARGN}")
  foreach (arg IN LISTS args)
    require(${arg})
  endforeach ()
endmacro()

macro(add_definitions)
  append_target_property(defines "${ARGN}")
  #  set(args "${ARGN}")
  #  foreach (arg IN LISTS args)
  #    append_target_property(defines ${arg})
  #  endforeach ()
endmacro()

macro(create_header_library target)
  if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/${target}-config.cmake")
    set(${target}_project_path ${CMAKE_CURRENT_LIST_DIR})
    set(${target}_project_path ${CMAKE_CURRENT_LIST_DIR} PARENT_SCOPE)
  else ()
    set(${target}_project_includes "${CMAKE_CURRENT_LIST_DIR}/source" PARENT_SCOPE)
  endif ()
endmacro()