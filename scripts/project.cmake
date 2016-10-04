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
  if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/${target}-config.cmake")
    set(${target}_project_path ${CMAKE_CURRENT_LIST_DIR})
    set(${target}_project_path ${CMAKE_CURRENT_LIST_DIR} PARENT_SCOPE)
  else ()
    set(${target}_project_includes "${CMAKE_CURRENT_LIST_DIR}/source" PARENT_SCOPE)
  endif ()
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

#if (IOS)
#  macro(add_project project_name)
#    message(STATUS "ios ${project_name}")
#    #include(${CMAKE_SOURCE_DIR}/toolchains/ios.cmake)
#    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
#    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
#    project(${project_name})
#    set(${project_name}_project_path ${CMAKE_CURRENT_LIST_DIR} PARENT_SCOPE)
#    include(${project_name}-config.cmake)
#  endmacro(add_project)
#else ()

macro(add_project project_name)
  if (NOT MSVC)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
  endif ()

  project(${project_name})
  if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/${project_name}-config.cmake")
    #      message("* ${CMAKE_CURRENT_LIST_DIR}/${project_name}-config.cmake")
    set(${project_name}_project_path ${CMAKE_CURRENT_LIST_DIR})
    set(${project_name}_project_path ${CMAKE_CURRENT_LIST_DIR} PARENT_SCOPE)
    include(${project_name}-config.cmake)
  else ()
    #      message(${CMAKE_CURRENT_LIST_DIR}/source)
    set(${project_name}_project_includes "${CMAKE_CURRENT_LIST_DIR}/source")
    set(${project_name}_project_includes "${CMAKE_CURRENT_LIST_DIR}/source" PARENT_SCOPE)
    include_directories(${CMAKE_CURRENT_LIST_DIR}/source)
  endif ()

endmacro(add_project)

#endif ()

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
        ${CMAKE_CURRENT_LIST_DIR}/${resources_dir} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${resources_dir}
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

macro(finish_cmake)

endmacro(finish_cmake)

macro(add_sources)
  target_sources(${CURRENT_TARGET} PUBLIC ${ARGN})
endmacro()

macro(move_dependency_item output_variable parent_name)
  #      message("check ${library_index}, ${parent_index}")
  list(FIND ${output_variable} ${parent_name} parent_index)
#  if (${parent_name} STREQUAL "bloom_scenery" AND ${library_name} STREQUAL "scenery")
#    message("${parent_name} ${library_name} | ${parent_index} GREATER ${library_index}")
#  endif ()
  if (${parent_index} GREATER ${library_index})
#    message(" < ${library_name} ${parent_name}")
#    message("befor ${${output_variable}}")
#    message("move ${parent_index} ${library_index}")
    list(REMOVE_AT ${output_variable} ${parent_index})
    list(INSERT ${output_variable} ${library_index} ${parent_name})
#    message("after ${${output_variable}}")
  endif ()
endmacro()

macro(append_dependency_hierarchy libraries output_variable parent_name)
  set(parent ${parent_name})
  foreach (library_name ${libraries})
    list(FIND ${output_variable} ${library_name} library_index)
    #    message("'${${output_variable}}' ${library_name} ${library_index}")
    if (${library_index} EQUAL "-1")
      list(APPEND ${output_variable} ${library_name})
#      if (IS_EXECUTABLE) # AND "${CURRENT_TARGET}" STREQUAL ""
#        message(" + ${library_name} ${parent_name}")
#      endif ()
      append_dependency_hierarchy("${${library_name}_dependencies}" ${output_variable} ${library_name})
    elseif (IS_EXECUTABLE AND MINGW AND NOT "${parent_name}" STREQUAL "")
      move_dependency_item(${output_variable} ${parent_name})
    endif ()
  endforeach ()

endmacro()

macro(clean_up_dependency_order output_variable)
  foreach (parent_name ${${output_variable}})
    foreach (library_name ${${parent_name}_dependencies})
      list(FIND ${output_variable} ${library_name} library_index)
#      message(" * ${parent_name} ${library_name}")
      move_dependency_item(${output_variable} ${parent_name})
    endforeach ()
  endforeach ()
endmacro()

macro(get_dependency_hierarchy libraries output_variable)
  set(${output_variable} "")
  append_dependency_hierarchy("${libraries}" ${output_variable} "")

  if (IS_EXECUTABLE AND MINGW)
#    message("-")
#    message("-")
#    message("-")
#    message("-")
    clean_up_dependency_order(${output_variable})
  endif ()

endmacro()

macro(include_project library_name)
  if (${library_name}_project_includes)
    include_directories(${${library_name}_project_includes})
  else ()
    include(${${library_name}_project_path}/${library_name}-config.cmake)
  endif ()
endmacro()

macro(require)

  if (LOCAL_TARGET)
    get_dependency_hierarchy("${ARGN}" all_dependencies)
    #message("  ${CURRENT_TARGET}: ${all_dependencies}")

    if (IS_EXECUTABLE)
      #      set(reverse_list ${all_dependencies})
      #      list(REVERSE reverse_list)
#      message("  ${CURRENT_TARGET}: ${all_dependencies}")

      foreach (library_name ${all_dependencies})
        if (TARGET ${library_name})
          #          message("Linking  local: ${library_name}")
          target_link_libraries(${CURRENT_TARGET} $<TARGET_FILE:${library_name}>)
        endif ()
      endforeach ()
    endif ()

    foreach (library_name ${all_dependencies})
      include_project(${library_name})

      #      if (TARGET ${library_name})
      #        message("link ${CURRENT_TARGET} ${library_name}")
      #        target_link_libraries(${CURRENT_TARGET} $<TARGET_FILE:${library_name}>)
      #      endif ()

      if (TARGET ${library_name} AND IS_EXECUTABLE)
        #        target_link_libraries(${CURRENT_TARGET} $<TARGET_FILE:${library_name}>)

        if (${library_name}_external_dependencies)
          #          message("*** ${${library_name}_external_dependencies}")
          set(temp ${${library_name}_external_dependencies})
          foreach (external_library IN LISTS temp)
            #            message("Linking dynamic: ${external_library}")
            link_external(${external_library})
          endforeach ()
        endif ()

        if (${library_name}_external_static_dependencies)
          #          message("*** ${${library_name}_external_dependencies}")
          set(temp ${${library_name}_external_static_dependencies})
          foreach (external_library IN LISTS temp)
            #            message("Linking  static: ${external_library}")
            link_external_static(${external_library})
            #            link_external_static(${external_library} ${external_library} ${external_library_${libname}_is_dynamc})
          endforeach ()
        endif ()

        if (${library_name}_system_dependencies)
          #          message("*** ${${library_name}_external_dependencies}")
          set(temp ${${library_name}_system_dependencies})
          foreach (external_library IN LISTS temp)
            #            message("Linking  system: ${external_library}")
            if (MSVC)
              target_link_libraries(${CURRENT_TARGET} ${external_library})
            else ()
              target_link_libraries(${CURRENT_TARGET} "-l${external_library}")
            endif ()
            #            link_external_static(${external_library} ${external_library} ${external_library_${libname}_is_dynamc})
          endforeach ()
        endif ()
      endif ()
    endforeach ()

    foreach (library_name ${ARGN})
      if (TARGET ${library_name})
        add_dependencies(${CURRENT_TARGET} ${library_name})
      endif ()

      list(APPEND "${CURRENT_TARGET}_dependencies" "${library_name}")
      set(${CURRENT_TARGET}_dependencies ${${CURRENT_TARGET}_dependencies} PARENT_SCOPE)
    endforeach ()
  endif ()
endmacro()

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
    #    message("${CURRENT_TARGET} ${fullpath}/${libname} ${is_dynamic}")

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
  endif ()

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
#      add_custom_command(TARGET ${CURRENT_TARGET} POST_BUILD
#        COMMAND ${CMAKE_COMMAND} -E copy ${fullpath}/${dllname} $<TARGET_FILE_DIR:${CURRENT_TARGET}>
#        )
    endif ()
  endif ()
endmacro()

macro(link_system_library library_name)
  list(APPEND "${CURRENT_TARGET}_system_dependencies" "${library_name}")
  set(${CURRENT_TARGET}_system_dependencies ${${CURRENT_TARGET}_system_dependencies} PARENT_SCOPE)
endmacro()
