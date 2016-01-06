
#  message("a ${quartz_sources}")
set(android_includes "")

macro(list_to_string variable list)
  set(result "")
  foreach (item ${list})
    set(result "${result} \\\n\t${item}")
  endforeach ()
  set(${variable} ${result})
endmacro()

foreach (target ${all_libraries})
  #  set(target_sources ${${target}_sources})
  #  set(target_sources "")
  #  foreach (source ${${target}_sources})
  #    set(target_sources "${target_sources} ${source}")
  #  endforeach ()
#      message(${${target}_includes})
  list(REMOVE_DUPLICATES ${target}_includes)
#    message("${target} ${${target}_system_libraries}")
#  if (${target}_system_libraries)
#    list(REMOVE_DUPLICATES ${target}_system_libraries)
#  endif ()
  list_to_string(target_sources "${${target}_sources}")
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

  configure_file(
    ${CMAKE_CURRENT_LIST_DIR}/templates/jni/Android.mk
    ${CMAKE_BINARY_DIR}/jni/${target_relative_path}/Android.mk
  )

  set(android_includes "${android_includes}\ninclude jni/${target_relative_path}/Android.mk")
  #  print_info()
  #
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

configure_file(
  ${CMAKE_CURRENT_LIST_DIR}/templates/project/build.xml
  ${CMAKE_BINARY_DIR}/build.xml
)

configure_file(
  ${CMAKE_CURRENT_LIST_DIR}/templates/project/project.properties
  ${CMAKE_BINARY_DIR}/project.properties
)