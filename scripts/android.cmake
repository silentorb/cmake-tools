unset(MSVC)

macro(add_library target)
  #  add_custom_target(${target})
  set(${target}_sources ${ARGN})
  set(${target}_sources ${ARGN} PARENT_SCOPE)
endmacro()

macro(project target)
  set(PROJECT_NAME ${target} PARENT_SCOPE)
endmacro()

macro(add_executable target)
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
  set(${CURRENT_TARGET}_includes ${${CURRENT_TARGET}_includes} ${ARGN})
  set(${CURRENT_TARGET}_includes ${${CURRENT_TARGET}_includes} ${ARGN} PARENT_SCOPE)
  #      message("  ${CURRENT_TARGET}")
  #  message(${${CURRENT_TARGET}_includes})
endmacro()

macro(create_library target)
  set(all_libraries ${all_libraries} ${target} PARENT_SCOPE)
  set(CURRENT_TARGET ${target})
  #message(WARNING "*${PROJECT_NAME} STREQUAL ${target}*")
  if (NOT "${PROJECT_NAME}" STREQUAL ${target})
    #    message(WARNING "No project for ${target}")
    add_project(${target})
  endif ()

  file(GLOB_RECURSE SOURCES source/*.cpp source/*.c)
  add_library(${target} ${SOURCES})

  #  if (NOT ANDROID)
  #    set("TARGET_FILE_DIR_${target}" $<TARGET_FILE_DIR:${target}>)
  #    set("TARGET_LINKER_FILE_${target}" $<TARGET_LINKER_FILE:${target}>)
  #    set("TARGET_FILE_${target}" $<TARGET_FILE:${target}>)
  #  endif ()

  string(LENGTH "${CMAKE_SOURCE_DIR}" string_length)
  math(EXPR string_length "${string_length} + 1")
  string(SUBSTRING ${CMAKE_CURRENT_SOURCE_DIR} ${string_length} -1 current_path)
  set(${target}_relative_path ${current_path} PARENT_SCOPE)
  get_filename_component(current_path ${current_path} DIRECTORY)
  set(${target}_containing_path ${current_path} PARENT_SCOPE)

  include_directories(${CMAKE_TOOLS}/include) # for dllexport

endmacro(create_library)

macro(get_relative_path result root_path path)
  string(LENGTH "${root_path}" string_length)
  math(EXPR string_length "${string_length} + 1")
  string(SUBSTRING ${path} ${string_length} -1 ${result})
endmacro(get_relative_path)

macro(create_test target)

endmacro(create_test)

macro(require)
  foreach (library_name ${ARGN})
    #    message("${PROJECT_NAME} require ${library_name}")
    find_package(${library_name} REQUIRED)

    set(${CURRENT_TARGET}_libraries ${${CURRENT_TARGET}_libraries} ${library_name})
    set(${CURRENT_TARGET}_libraries ${${CURRENT_TARGET}_libraries} PARENT_SCOPE)
    add_system_libraries(${${library_name}_system_libraries})
  endforeach ()
endmacro()

macro(add_project project_name)
  if (${MINGW})
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
  endif ()

  project(${project_name})

  set(${project_name}_DIR ${CMAKE_CURRENT_LIST_DIR} PARENT_SCOPE)

  include(${project_name}-config.cmake OPTIONAL)

endmacro(add_project)

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

    #    add_custom_command(TARGET ${CURRENT_TARGET} POST_BUILD
    #      COMMAND ${CMAKE_COMMAND} -E copy_directory
    #      ${CMAKE_CURRENT_LIST_DIR}/${resource_dir} $TARGET_FILE_DIR_${CURRENT_TARGET}/${resource_dir})
  endif ()

endmacro(add_resources)

macro(finish_mythic)
  include(${CMAKE_TOOLS}/generators/android/android-generator.cmake)
  message(FATAL_ERROR "This is not a real error, but the only way to prevent CMake from generating unneeded files.")
endmacro(finish_mythic)