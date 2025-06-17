project('skean', 'cython',
    version : '0.1.0',
    default_options : ['python.install_env=venv'])

py = import('python').find_installation(pure : false)
message(py.get_install_dir())

py.extension_module(
    'skean',
    'src/skean.pyx',
    dependencies : py.dependency(),
)