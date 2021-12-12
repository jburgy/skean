#!/usr/bin/env python

"""The setup script."""

from setuptools import setup
from Cython.Build import cythonize

with open('README.rst') as readme_file:
    readme = readme_file.read()

with open('HISTORY.rst') as history_file:
    history = history_file.read()

requirements = [ ]

test_requirements = ['pytest>=3', ]

setup(
    author="Jan Burgy",
    author_email='jburgy@gmail.com',
    python_requires='>=3.6',
    classifiers=[
        'Development Status :: 2 - Pre-Alpha',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: Apache Software License',
        'Natural Language :: English',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
    ],
    description="PEP 523 based directed acyclic graph implementation in python",
    entry_points={
        'console_scripts': [
            'skean=skean.cli:main',
        ],
    },
    install_requires=requirements,
    license="Apache Software License 2.0",
    long_description=readme + '\n\n' + history,
    include_package_data=True,
    keywords='skean',
    name='skean',
    setup_requires=["cython"],
    ext_modules=cythonize("skean/skean.pyx", language_level=3),
    test_suite='tests',
    tests_require=test_requirements,
    url='https://github.com/jburgy/skean',
    version='0.1.0',
    zip_safe=False,
)
