
function(platform_build_external key generator)
  set(build_path "build/${key}")
  set(bin_path "bin/${key}")
  file(MAKE_DIRECTORY ${build_path})
  file(MAKE_DIRECTORY ${bin_path})

  if (generator)
    set(generator_flag "-G")
  endif ()

  execute_process(COMMAND ${CMAKE_COMMAND} ${generator_flag} ${generator}
    -DCMAKE_INSTALL_PREFIX=${CMAKE_SOURCE_DIR}/bin/${key} ../../cmake
    -Dtoolset=${key}
    WORKING_DIRECTORY ${build_path}
    RESULT_VARIABLE output
    )
  message(${output})

  if (MSVC)
    set(config_flag "--config")
    set(config_value RELWITHDEBINFO)
  endif ()

  execute_process(COMMAND ${CMAKE_COMMAND} --build . ${config_flag} ${config_value}
    WORKING_DIRECTORY ${build_path}
    RESULT_VARIABLE output
    )
  message(${output})

endfunction()

function(build_external)
  if (WIN32)
    platform_build_external(mingw "MinGW Makefiles")
    platform_build_external(msvc "")
  endif ()

endfunction()