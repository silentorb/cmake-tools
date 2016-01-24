if (MINGW)
  SET(GENERATOR_KEY mingw)
elseif (MSVC)
  SET(GENERATOR_KEY msvc)
else ()
  message(FATAL_ERROR "Unsupported Generator.")
endif ()