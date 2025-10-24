from cpython.pystate cimport PyInterpreterState, PyThreadState
from cpython.ref cimport PyObject

cdef extern from "Python.h":
    ctypedef struct PyCodeObject:
        int co_argcount         # arguments, except *args
        int co_posonlyargcount  # #positional only arguments
        int co_kwonlyargcount   # #keyword only arguments
        # ...
    ctypedef struct PyFrameObject
    ctypedef void freefunc(void *)

    int _PyCode_GetExtra(PyObject *code, Py_ssize_t index, void **extra)
    int _PyCode_SetExtra(PyObject *code, Py_ssize_t index, void *extra)
    PyObject *PyCode_GetVarnames(PyCodeObject *co)

    PyFrameObject *PyFrame_GetBack(PyFrameObject *frame)
    PyCodeObject *PyFrame_GetCode(PyFrameObject *frame)
    PyObject *PyFrame_GetLocals(PyFrameObject *frame)

cdef extern from "pystate.h":
    PyInterpreterState *PyInterpreterState_Get()

    ctypedef PyObject *(*_PyFrameEvalFunction)(PyThreadState *tstate, PyFrameObject *frame, int exc)

    void _PyInterpreterState_SetEvalFrameFunc(PyInterpreterState *interp, _PyFrameEvalFunction eval_frame)


cdef extern from "ceval.h":
    PyObject *_PyEval_EvalFrameDefault(PyThreadState *tsate, PyFrameObject *frame, int exc)
    Py_ssize_t _PyEval_RequestCodeExtraIndex(freefunc)
