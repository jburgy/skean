from cpython.pystate cimport PyInterpreterState, PyThreadState
from cpython.ref cimport PyObject

cdef extern from "Python.h":
    ctypedef struct PyCodeObject:
        int co_argcount         # arguments, except *args
        int co_posonlyargcount  # #positional only arguments
        int co_kwonlyargcount   # #keyword only arguments
        # ...
    # see https://cython.readthedocs.io/en/latest/src/tutorial/clibraries.html#id4
    cdef struct _PyInterpreterFrame
    ctypedef struct PyFrameObject
    ctypedef void freefunc(void *)

    int PyUnstable_Code_GetExtra(PyObject *code, Py_ssize_t index, void **extra)
    int PyUnstable_Code_SetExtra(PyObject *code, Py_ssize_t index, void *extra)
    PyObject *PyCode_GetVarnames(PyCodeObject *co)

    PyFrameObject *PyThreadState_GetFrame(PyThreadState *tstate)
    PyFrameObject *PyFrame_GetBack(PyFrameObject *frame)
    PyCodeObject *PyFrame_GetCode(PyFrameObject *frame)
    PyObject *PyFrame_GetLocals(PyFrameObject *frame)

    PyInterpreterState *PyInterpreterState_Get()

    ctypedef PyObject *(*_PyFrameEvalFunction)(PyThreadState *tstate, _PyInterpreterFrame *frame, int exc)
    void _PyInterpreterState_SetEvalFrameFunc(PyInterpreterState *interp, _PyFrameEvalFunction eval_frame)
    PyObject *PyUnstable_InterpreterFrame_GetCode(_PyInterpreterFrame *frame)

    PyObject *_PyEval_EvalFrameDefault(PyThreadState *tstate, _PyInterpreterFrame *frame, int exc)
    Py_ssize_t PyUnstable_Eval_RequestCodeExtraIndex(freefunc)
