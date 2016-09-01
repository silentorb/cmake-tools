set(DOLLAR_SIGN "$")

#if (IOS OR ANDROID)
set(BUILD_SHARED_LIBS OFF)
#else ()
#  set(BUILD_SHARED_LIBS true)
#endif ()

if (IOS)
  add_definitions(-DIOS=1)
endif ()

macro(create_target target is_executable)
  set(CMAKE_OSX_ARCHITECTURES "armv7 arm64")
  list(APPEND ALL_PROJECTS ${target})
  set(ALL_PROJECTS ${ALL_PROJECTS} PARENT_SCOPE)
  set(IS_EXECUTABLE ${is_executable})
  set(IS_EXECUTABLE ${is_executable} PARENT_SCOPE)

  # Optimize debug build to help diagnose release build crashes.
  if (GCC_DEBUG_OPTIMIZATION_LEVEL)
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -${GCC_DEBUG_OPTIMIZATION_LEVEL}")
  endif ()

  set(CURRENT_TARGET ${target})
  set(LOCAL_TARGET ${target})

  if (NOT "${PROJECT_NAME}" STREQUAL ${target})
    add_project(${target})
  endif ()

  if (MINGW)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wreturn-type")
  endif ()

  if ("${ARGN}" STREQUAL "")
    #    message("No sources for ${target}")
    if (IOS)
      file(GLOB_RECURSE CURRENT_SOURCES source/*.cpp source/*.mm source/*.m source/*.c)
    else ()
      file(GLOB_RECURSE CURRENT_SOURCES source/*.cpp source/*.c)
    endif ()

    file(GLOB_RECURSE HEADERS source/*.h)
    set(CURRENT_SOURCES ${CURRENT_SOURCES} PARENT_SCOPE)
    #    add_library(${target} ${CURRENT_SOURCES} ${HEADERS})
    set(SOURCES ${CURRENT_SOURCES} ${HEADERS})
  else ()
    set(SOURCES ${ARGN})
  endif ()

  if (COMMAND on_enumerate_target_sources)
    on_enumerate_target_sources()
  endif ()

  if (${is_executable})
    add_executable(${target} ${SOURCES})
  else ()
    add_library(${target} ${SOURCES})
  endif ()

  if (NOT CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    string(LENGTH "${CMAKE_SOURCE_DIR}" string_length)
    math(EXPR string_length "${string_length} + 1")
    string(SUBSTRING ${CMAKE_CURRENT_SOURCE_DIR} ${string_length} -1 current_path)
    get_filename_component(current_path ${current_path} DIRECTORY)
    set_target_properties(${target} PROPERTIES FOLDER ${current_path})
  endif ()

  if (COMMAND on_create_target)
    on_create_target()
  endif ()

  if (IOS)
    set_xcode_property(${target} IPHONEOS_DEPLOYMENT_TARGET "8.4")
    set_xcode_property(${target} VALID_ARCHS "armv7 armv7s arm64")
    set_xcode_property(${target} SUPPORTED_PLATFORMS "iphonesimulator iphoneos")
    set_xcode_property(${target} ONLY_ACTIVE_ARCH "NO")

  else ()
    set_target_properties(${target} PROPERTIES DEFINE_SYMBOL "EXPORTING_DLL")
  endif (IOS)

endmacro(create_target)

macro(create_library target)
  create_target(${target} FALSE)
  string(TOUPPER "${CURRENT_TARGET}" UPPER_CURRENT_TARGET)
  add_definitions("-D${UPPER_CURRENT_TARGET}_LIB")
endmacro(create_library)

macro(create_executable target)
  create_target(${target} TRUE)
endmacro(create_executable)

macro(create_header_library target)
  set(${target}_DIR ${CMAKE_CURRENT_LIST_DIR} CACHE INTERNAL "${target} path")
endmacro(create_header_library)

macro(get_relative_path result root_path path)
  string(LENGTH "${root_path}" string_length)
  math(EXPR string_length "${string_length} + 1")
  string(SUBSTRING ${path} ${string_length} -1 ${result})
endmacro(get_relative_path)

macro(create_test target)
  if (MINGW)
    create_executable(${target})
    link_external_static(googletest gtest)
    target_link_libraries(${target} "${MYTHIC_DEPENDENCIES}/googletest/lib/libgtest_main.a")
  endif ()
endmacro(create_test)

macro(append_dependency_hierarchy libraries output_variable)
  #  message("${libraries}")
  foreach (library_name ${libraries})
    list(FIND ${output_variable} ${library_name} already_added)
    #    message("'${${output_variable}}' ${library_name} ${already_added}")
    if (${already_added} EQUAL "-1")
      list(APPEND ${output_variable} ${library_name})
      append_dependency_hierarchy("${${library_name}_dependencies}" ${output_variable})
    endif ()
  endforeach ()
endmacro()

macro(get_dependency_hierarchy libraries output_variable)
  set(${output_variable} "")
  append_dependency_hierarchy("${libraries}" ${output_variable})
endmacro()

macro(include_project library_name)
  if (${library_name}_includes)
    include_directories(${${library_name}_includes})
  else ()
    #    message("${library_name}_DIR ${${library_name}_DIR}")
    #    find_package(${library_name} REQUIRED)
    include(${${library_name}_DIR}/${library_name}-config.cmake)
  endif ()

  #
  #  set(temp ${${library_name}_dependencies})
  #  foreach (dependency IN LISTS temp)
  #    include_project(${dependency})
  #  endforeach ()
endmacro()

macro(require)

  if (LOCAL_TARGET)
    get_dependency_hierarchy("${ARGN}" all_dependencies)
    #    message("  ${CURRENT_TARGET}: ${all_dependencies}")
    foreach (library_name ${all_dependencies})
      include_project(${library_name})
      if (TARGET ${library_name} AND IS_EXECUTABLE)
        target_link_libraries(${CURRENT_TARGET}
          $<TARGET_FILE:${library_name}>
          )

        if (${library_name}_external_dependencies)
          #          message("*** ${${library_name}_external_dependencies}")
          set(temp ${${library_name}_external_dependencies})
          foreach (external_library IN LISTS temp)
            message("Linking dynamic: ${external_library}")
            link_external(${external_library})
          endforeach ()
        endif ()

        if (${library_name}_external_static_dependencies)
          #          message("*** ${${library_name}_external_dependencies}")
          set(temp ${${library_name}_external_static_dependencies})
          foreach (external_library IN LISTS temp)
            message("Linking  static: ${external_library}")
            link_external_static(${external_library})
            #            link_external_static(${external_library} ${external_library} ${external_library_${libname}_is_dynamc})
          endforeach ()
        endif ()
      endif ()
    endforeach ()

    foreach (library_name ${ARGN})
      if (TARGET ${library_name})
        add_dependencies(${CURRENT_TARGET}
          ${library_name}
          )
        list(APPEND "${CURRENT_TARGET}_dependencies" "${library_name}")
        set(${CURRENT_TARGET}_dependencies ${${CURRENT_TARGET}_dependencies} PARENT_SCOPE)
      endif ()
    endforeach ()
  endif ()
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
else ()

  macro(add_project project_name)
    if (MINGW OR ANDROID)
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
    endif ()

    project(${project_name})
    #    message("project ${project_name}")
    if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/${project_name}-config.cmake")
      #      message(${CMAKE_CURRENT_LIST_DIR}/${project_name}-config.cmake)
      #      if (CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
      set(${project_name}_DIR ${CMAKE_CURRENT_LIST_DIR} CACHE INTERNAL "${project_name} dir")
      #      else ()
      #        set(${project_name}_DIR ${CMAKE_CURRENT_LIST_DIR} PARENT_SCOPE)
      #      endif ()
      #      message("${project_name}_DIR ${${project_name}_DIR}")

      include(${project_name}-config.cmake)

    else ()
      set(${project_name}_includes "${CMAKE_CURRENT_LIST_DIR}/source" PARENT_SCOPE)
      include_directories(${CMAKE_CURRENT_LIST_DIR}/source)
    endif ()

  endmacro(add_project)

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
      #      message("resource ${resource_path}")
      #      message("resource ${relative_dir}")
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

    else ()
      add_custom_command(TARGET ${CURRENT_TARGET}
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${CMAKE_CURRENT_LIST_DIR}/${resources_dir} $<TARGET_FILE_DIR:${CURRENT_TARGET}>/${resources_dir}
        COMMENT "Copying ${CURRENT_TARGET} files"
        )
    endif ()
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

macro(doctor varname path name extension)
  if (path AND EXISTS ${path}/${name}.${extension})
  elseif (NOT MSVC)
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

  set(name2 name)
  set(extension2 extension)
  set(${varname} "${${name2}}.${${extension2}}" PARENT_SCOPE)
endmacro()

function(doctor_dynamic varname path)
  set(name ${${varname}})

  if (MSVC OR MINGW)
    set(extension "dll")
  else ()
    set(extension "a")
  endif ()

  doctor(${varname} ${path} ${name} ${extension})

endfunction()

function(doctor_static varname path is_dynamic)
  set(name ${${varname}})

  if (MSVC)
    set(extension "lib")
  elseif (MINGW AND is_dynamic)
    set(extension "dll.a")
  else ()
    set(extension "a")
  endif ()

  doctor(${varname} ${path} ${name} ${extension})

endfunction()

macro(include_external_directory path)
  set(include_suffix "${ARGV1}")
  if (NOT include_suffix)
    set(include_suffix "")
  else ()
    set(include_suffix "/${include_suffix}")
  endif ()

  if (MSVC)
    include_directories(${MYTHIC_DEPENDENCIES}/Release/${path}/include${include_suffix})
  else ()
    include_directories(${MYTHIC_DEPENDENCIES}/${path}/include${include_suffix})
  endif ()
endmacro()

macro(link_external_static path)
  set(libname "${ARGV1}")
  set(is_dynamic "${ARGV2}")
  if (NOT is_dynamic)
    set(is_dynamic FALSE)
  endif ()

  if (NOT libname)
    set(libname ${path})
  endif ()

  if (NOT is_dynamic)
    list(APPEND "${CURRENT_TARGET}_external_static_dependencies" "${libname}")
    set(${CURRENT_TARGET}_external_static_dependencies ${${CURRENT_TARGET}_external_static_dependencies} PARENT_SCOPE)
  endif ()

  set(include_suffix "${ARGV3}")
  if (NOT include_suffix)
    set(include_suffix "")
  else ()
    set(include_suffix "/${include_suffix}")
  endif ()

  if (MSVC)
    foreach (build_mode Release Debug)
      if (build_mode STREQUAL "Debug")
        set(cmake_build_mode debug)
      else ()
        set(cmake_build_mode optimized)
      endif ()

      set(fullpath ${MYTHIC_DEPENDENCIES}/${build_mode}/${path}/lib)
      set(libname2 ${libname})
      doctor_static(libname2 ${fullpath} ${is_dynamic})
      target_link_libraries(${CURRENT_TARGET} ${cmake_build_mode} "${fullpath}/${libname2}")
    endforeach ()
    if (EXISTS ${MYTHIC_DEPENDENCIES}/Release/${path}/include${include_suffix})
      include_directories(${MYTHIC_DEPENDENCIES}/Release/${path}/include${include_suffix})
    endif ()
  else ()
    set(fullpath ${MYTHIC_DEPENDENCIES}/${path}/lib)
    doctor_static(libname ${fullpath} ${is_dynamic})

    #  message("${CURRENT_TARGET} ${fullpath}/${libname}")
    message("${CURRENT_TARGET} ${fullpath}/${libname} ${is_dynamic}")

    if (IOS)
      target_link_libraries(${CURRENT_TARGET} "-l${fullpath}/${libname}")
    else ()
      target_link_libraries(${CURRENT_TARGET} "${fullpath}/${libname}")
    endif ()

    include_directories(${MYTHIC_DEPENDENCIES}/${path}/include${include_suffix})
  endif ()

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

  if (NOT IS_EXECUTABLE)
    list(APPEND "${CURRENT_TARGET}_external_dependencies" "${libname}")
    set(${CURRENT_TARGET}_external_dependencies ${${CURRENT_TARGET}_external_dependencies} PARENT_SCOPE)
    #    set(external_library_${libname}_is_dynamic TRUE)
  endif (

  )
  if (IOS)
    link_external_static(${path} ${libname})
  else ()
    link_external_static(${path} ${libname} TRUE)

    if (IS_EXECUTABLE)
      if (MSVC)
        #      set(fullpath "${MYTHIC_DEPENDENCIES}/$<$<CONFIG:debug>:Debug>$<$<CONFIG:release>:Release>:Debug>$<$<CONFIG:relwithdebinfo>:Release>/${path}/bin")
        set(fullpath "${MYTHIC_DEPENDENCIES}/RelWithDebInfo/${path}/bin")
      else ()
        set(fullpath "${MYTHIC_DEPENDENCIES}/${path}/bin")
      endif ()

      doctor_dynamic(dllname ${fullpath})
      #      message(WARNING "${CURRENT_TARGET} ${fullpath}/${dllname}")
      add_custom_command(TARGET ${CURRENT_TARGET} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy ${fullpath}/${dllname} $<TARGET_FILE_DIR:${CURRENT_TARGET}>
        )
    endif ()
  endif ()
endmacro()

#if (ANRDOID_NDK)
macro(add_system_libraries)
  #    if (NOT "${ARGN}" STREQUAL "")
  set(${CURRENT_TARGET}_system_libraries ${${CURRENT_TARGET}_system_libraries} ${ARGN})
  list(REMOVE_DUPLICATES ${CURRENT_TARGET}_system_libraries)
  set(${CURRENT_TARGET}_system_libraries ${${CURRENT_TARGET}_system_libraries} PARENT_SCOPE)
  #    endif ()
endmacro()
#endif ()