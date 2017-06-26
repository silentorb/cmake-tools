
function(platform_build_external key generator)
  file(MAKE_DIRECTORY build)
  set(build_path "build/${key}")
  file(MAKE_DIRECTORY ${build_path})
  if (generator)
    execute_process(COMMAND cmake -G ${generator} ../../cmake
      WORKING_DIRECTORY ${build_path}
      RESULT_VARIABLE output
      )
  else ()
    execute_process(COMMAND cmake -DCMAKE_INSTALL_PREFIX=${parent_dir} ../../cmake
      WORKING_DIRECTORY ${build_path}
      RESULT_VARIABLE output
      )
  endif ()
  message(${output})

#  execute_process(COMMAND cmake -DCMAKE_INSTALL_PREFIX=${CMAKE_SOURCE_DIR}/bin/msvc --build .
#    WORKING_DIRECTORY ${build_path}
#    RESULT_VARIABLE output
#    )
#  message(${output})
#
#    execute_process(COMMAND cmake -P cmake_install.cmake
#      WORKING_DIRECTORY ${build_path}
#      RESULT_VARIABLE output
#      )
#    message(${output})
endfunction()

function(build_external)
  if (WIN32)
    platform_build_external(mingw "MinGW Makefiles")
    #    platform_build_external(msvc)
  endif ()

endfunction()