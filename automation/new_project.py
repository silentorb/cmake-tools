import sys
import os

path = sys.argv[1].replace("\\", '/')
project_name = path.split('/')[-1]
full_path ='projects/' + path

def load_template(name):
    handle = open(os.path.dirname(__file__) + '/templates/' + name, 'r')
    content = handle.read()
    handle.close()
    return content

def copy_template(name, project_name, path):
    content = load_template(name).replace("$project", project_name)
    handle = open(path, 'w')
    handle.write(content)
    handle.close()

def register_project():
    handle = open('CMakeLists.txt', 'r+')
    content = handle.read()
    offset = content.find("#end sub-projects")
    content = content[:offset] + 'add_subdirectory(projects/' + path + ")\n" + content[offset:]
    handle.seek(0)
    handle.write(content)
    handle.close()

def run():
    os.makedirs(full_path + '/source')
    copy_template('CMakeLists.txt', project_name, full_path + '/' + 'CMakeLists.txt')
    copy_template('config.cmake', project_name, full_path + '/' + project_name + '-config.cmake')

run()
register_project()

print(path, project_name)
