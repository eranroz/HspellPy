from distutils.core import setup
from distutils.extension import Extension

try:
    from Cython.Distutils import build_ext
    use_cython = True
except ImportError:
    use_cython = False

if use_cython:
    ext_modules = [Extension("HspellPy",
                         ["pyhspell.pyx"],
                         language='c',
                         library_dirs = ['/usr/local/lib'],
                         include_dirs=['/usr/local/include'],
                         extra_objects=['/usr/local/lib/libhspell.a'],
                         )]
else:
    ext_modules = [Extension("HspellPy",
                         ["pyhspell.c"],
                         language='c',
                         library_dirs = ['/usr/local/lib'],
                         include_dirs=['/usr/local/include'],
                         extra_objects=['/usr/local/lib/libhspell.a'],
                         )]

setup(name='HspellPy',
      cmdclass={'build_ext': build_ext},
      ext_modules=ext_modules,
      author='Eranroz',
      url='https://github.com/eranroz/HspellPy',
      description='Python wrapper for Hspell'
      )