if (${IOS})
  add_definitions(-DIOS=1)
  set(BUILD_SHARED_LIBS OFF)
else ()
  set(BUILD_SHARED_LIBS true)
endif ()

macro(create_library target)
  set(CURRENT_TARGET ${target})
  #message(WARNING "*${PROJECT_NAME} STREQUAL ${target}*")
  if (NOT "${PROJECT_NAME}" STREQUAL ${target})
    #    message(WARNING "No project for ${target}")
    add_project(${target})
  endif ()

  if ("${ARGN}" STREQUAL "")
    #    message("No sources for ${target}")
    if (IOS)
      file(GLOB_RECURSE CURRENT_SOURCES source/*.cpp source/*.mm source/*.m source/*.c)
    else()
      file(GLOB_RECURSE CURRENT_SOURCES source/*.cpp source/*.c)
    endif()

    file(GLOB_RECURSE HEADERS source/*.h)
    set(CURRENT_SOURCES ${CURRENT_SOURCES} PARENT_SCOPE)
    add_library(${target} ${CURRENT_SOURCES} ${HEADERS})
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
    set_xcode_property(${target} IPHONEOS_DEPLOYMENT_TARGET "8.4")
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

  file(GLOB_RECURSE BUNDLE_RESOURCES ${resources_dir}/*)
  if (IOS_NOT_USING_ANYMORE)
    # add_executable("${CURRENT_TARGET}_resources" MACOSX_BUNDLE ${BUNDLE_RESOURCES})
    add_library("${CURRENT_TARGET}_resources" ${BUNDLE_RESOURCES})
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
    set_target_properties("${CURRENT_TARGET}_resources" PROPERTIES LINKER_LANGUAGE C)
    set_target_properties("${CURRENT_TARGET}_resources" PROPERTIES BUNDLE_EXTENSION "bundle")
    set_xcode_property(${CURRENT_TARGET}_resources IPHONEOS_DEPLOYMENT_TARGET "8.4")
    set(ALL_RESOURCES "${ALL_RESOURCES} BUNDLE_RESOURCES" PARENT_SCOPE)

  else ()
    #MESSAGE(WARNING "${CMAKE_CURRENT_LIST_DIR}/${resource_dir} $<TARGET_FILE_DIR:${CURRENT_TARGET}>/${resources_dir}")

    #    add_custom_target(
    #      ${CURRENT_TARGET}_resources
    #      DEPENDS ${BUNDLE_RESOURCES}
    #      VERBATIM
    #    )

    #    add_dependencies(${CURRENT_TARGET} ${CURRENT_TARGET}_resources)
    list(GET CURRENT_SOURCES 0 FIRST_SOURCE)
#    message("${CURRENT_SOURCES}")
#    message("first: ${FIRST_SOURCE}")
#      message("${BUNDLE_RESOURCES}")
    set_source_files_properties(${FIRST_SOURCE} PROPERTIES OBJECT_DEPENDS "${BUNDLE_RESOURCES}")

if (IOS)
  add_custom_command(TARGET ${CURRENT_TARGET}
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_CURRENT_LIST_DIR}/${resources_dir} ${CMAKE_BINARY_DIR}/${resources_dir}
    COMMENT "Copying ${CURRENT_TARGET} files"
    )

else()
    add_custom_command(TARGET ${CURRENT_TARGET}
      COMMAND ${CMAKE_COMMAND} -E copy_directory
      ${CMAKE_CURRENT_LIST_DIR}/${resources_dir} $<TARGET_FILE_DIR:${CURRENT_TARGET}>/${resources_dir}
      COMMENT "Copying ${CURRENT_TARGET} files"
      )
endif()
    #    get_property(output_dir TARGET ${CURRENT_TARGET} PROPERTY LOCATION)
    #message("$<TARGET_FILE_DIR:${CURRENT_TARGET}>/$")
    #      print_info()
    #    file(COPY
    #      ${CMAKE_CURRENT_LIST_DIR}/${resources_dir}
    #      DESTINATION ${EXECUTABLE_OUTPUT_PATH}/${resources_dir}
    #      )
  endif ()

endmacro(add_resources)

macro(finish_mythic)

endmacro(finish_mythic)

macro(add_sources)
  target_sources(${CURRENT_TARGET} PUBLIC ${ARGN})
endmacro()

function(set_lib_prefix varname)
  set(path "${ARGV1}")

  #    message(WARNING "${${varname}} ${path}")
  if (path AND EXISTS ${path}/${${varname}})

  else ()
    string(SUBSTRING "${${varname}}" 0 3 libprefix)
    #  message(WARNING "substring ${libprefix} ${libname}")
    if (NOT libprefix STREQUAL "lib")
      set(${varname} "lib${${varname}}" PARENT_SCOPE)
    endif ()
  endif ()
endfunction()

function(doctor_libname varname is_dynamic path)
  #  set(path "${ARGV2}")
  set(name ${${varname}})

  if (is_dynamic)
    if (MSVC OR MINGW)
      set(extension "dll")
    else ()
      set(extension "a")
    endif ()
  else ()
    if (MSVC)
      set(extension "lib")
    elseif (IOS)
      set(extension "a")
    else ()
      set(extension "dll.a")
    endif ()

  endif ()
  #  message("${path} ${name} ${extension}")
  if (path AND EXISTS ${path}/${name}.${extension})
  else ()
    string(SUBSTRING "${name}" 0 3 libprefix)
    if (NOT libprefix STREQUAL "lib")
      set(name "lib${name}")
    endif ()
  endif ()

  if (MSVC AND path)
    if (EXISTS ${path}/${name}d.${extension})
      set(name "${name}d")
    endif ()
  endif ()

  set(${varname} "${name}.${extension}" PARENT_SCOPE)

endfunction()

macro(link_external_static path)
  set(libname "${ARGV1}")
  if (NOT libname)
    set(libname ${path})
  endif ()

  set(fullpath ${MYTHIC_DEPENDENCIES}/${path}/lib)

  doctor_libname(libname FALSE ${fullpath})
  #  if (MINGW)
  #    set(libname "${libname}.dll.a")
  #    set_lib_prefix(libname)
  #  elseif (MSVC)
  #    set(libname "${libname}.lib")
  #  endif ()

message ("${CURRENT_TARGET} ${fullpath}/${libname}")
if (IOS)
  target_link_libraries(${CURRENT_TARGET} "-l${fullpath}/${libname}")
else()
  target_link_libraries(${CURRENT_TARGET} "${fullpath}/${libname}")
endif()

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

  set(fullpath "${MYTHIC_DEPENDENCIES}/${path}/bin")
  doctor_libname(dllname TRUE ${fullpath})

  add_custom_command(TARGET ${CURRENT_TARGET} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy ${fullpath}/${dllname} $<TARGET_FILE_DIR:${CURRENT_TARGET}>
    )
endmacro()
