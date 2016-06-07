
#  message("a ${quartz_sources}")
set(android_includes "${ANDROID_MK_HEADER}")
if (ANDROID_DEPENENCIES)
  set(android_includes "${android_includes}include ${ANDROID_DEPENENCIES}/Android.mk")
endif ()

set(all_resources "")

macro(list_to_string variable list)
  set(result "")
  foreach (item ${list})
    set(result "${result} \\\n\t${item}")
  endforeach ()
  set(${variable} ${result})
endmacro()

set(all_system_libraries "")
set(temp_libraries "")

foreach (target ${all_libraries})
  foreach (library ${${target}_system_libraries})
    if (NOT ${library} IN_LIST temp_libraries)
      set(temp_libraries temp_libraries library)
      set(all_system_libraries "${all_system_libraries} -l${library}")
    endif ()
  endforeach ()
endforeach ()

foreach (target ${all_libraries})
  list(REMOVE_DUPLICATES ${target}_includes)

  set(target_sources "")

  foreach (inc ${${target}_sources})
    get_filename_component(extension ${inc} EXT)
#      message("${inc}  ---  ${extension}")
    if ("${extension}" STREQUAL ".c" OR "${extension}" STREQUAL ".cpp")
      set(target_sources "${target_sources} ${inc}")
    endif ()
  endforeach ()

#  list_to_string(target_sources "${${target}_sources}")
  list_to_string(target_includes "${${target}_includes}")

  set(target_containing_path ${${target}_containing_path})
  set(target_relative_path ${${target}_relative_path})
  set(target_system_libraries "")
  foreach (library ${${target}_system_libraries})
    set(target_system_libraries "${target_system_libraries} -l${library}")
  endforeach ()

  set(target_libraries "")
  foreach (library ${${target}_libraries})
    set(target_libraries "${target_libraries} ${library}")
  endforeach ()

  #  message("library ${target}  ${${target}_libraries}")
#  message("defines ${target}  ${${target}_defines}")

  if (${${target}_is_executable})
    set(template_name front)
  else ()
    set(template_name library)
  endif ()

  configure_file(
    ${CMAKE_CURRENT_LIST_DIR}/templates/jni/Android.${template_name}.mk
    ${CMAKE_BINARY_DIR}/jni/${target_relative_path}/Android.mk
  )

  set(android_includes "${android_includes}\ninclude ${JNI_PATH}${target_relative_path}/Android.mk")

  #    message("${target} ${${target}_resources_dir}")
  if (NOT "${${target}_resources_dir}" STREQUAL "")
    list(APPEND all_resources ${${target}_resources_dir})
  endif ()
endforeach ()

configure_file(
  ${CMAKE_CURRENT_LIST_DIR}/templates/AndroidManifest.xml
  ${CMAKE_BINARY_DIR}/AndroidManifest.xml
)

configure_file(
  ${CMAKE_CURRENT_LIST_DIR}/templates/jni/Application.mk
  ${CMAKE_BINARY_DIR}/jni/Application.mk
)

configure_file(
  ${CMAKE_CURRENT_LIST_DIR}/templates/jni/Android.root.mk
  ${CMAKE_BINARY_DIR}/jni/Android.mk
)

configure_file(
  ${CMAKE_CURRENT_LIST_DIR}/templates/build.ps1
  ${CMAKE_BINARY_DIR}/build.ps1
)

configure_file(
  ${CMAKE_CURRENT_LIST_DIR}/templates/debug.bat
  ${CMAKE_BINARY_DIR}/debug.bat
)

configure_file(
  ${CMAKE_CURRENT_LIST_DIR}/templates/.gitignore
  ${CMAKE_BINARY_DIR}/.gitignore
)

# Project files

set(DOLLAR_SIGN "$")
set(build_additional "")

foreach (resource_dir ${all_resources})
  set(build_additional "${build_additional}\n\
<copy todir=\"${CMAKE_BINARY_DIR}/assets\" >\n\
        <fileset dir=\"${resource_dir}\" includes=\"**\"/>\n\
 </copy>\
")
endforeach ()

configure_file(
  ${CMAKE_CURRENT_LIST_DIR}/templates/project/build.xml
  ${CMAKE_BINARY_DIR}/build.xml
)

configure_file(
  ${CMAKE_CURRENT_LIST_DIR}/templates/project/project.properties
  ${CMAKE_BINARY_DIR}/project.properties
)