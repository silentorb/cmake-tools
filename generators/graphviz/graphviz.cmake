#  message("project ${ALL_PROJECTS}")
set(GRAPHVIZ_CMAKE_PATH ${CMAKE_CURRENT_LIST_DIR})
macro(gemerate_graphviz_file graph_name)

  set(dot_content "")

  foreach (project IN LISTS ALL_PROJECTS)

    #    message("project ${project}")
    if (GRAPHVIZ_PROJECT_FILTER)
      #      message(hello)
      string(REGEX MATCH ${GRAPHVIZ_PROJECT_FILTER} match_result ${project})
      if (match_result)
        message("graphviz filtered out ${match_result}")
        continue()
      endif ()
    endif ()
    set(dot_content "${dot_content}  \"${project}\" [ label=\"${project}\" shape=\"polygon\"];\n")
    set(temp ${${project}_dependencies})
    foreach (dependency IN LISTS temp)
      #      message("  ${dependency}")
      set(dot_content "${dot_content}  \"${project}\" -> \"${dependency}\"\n")
    endforeach ()
    #    message("  ${${project}_dependencies}")
  endforeach ()

  configure_file(
    ${GRAPHVIZ_CMAKE_PATH}/templates/graph.dot
    ${CMAKE_BINARY_DIR}/${graph_name}.dot
  )
endmacro()