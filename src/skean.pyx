#cython: language_level=3

from functools import _CacheInfo, _lru_cache_wrapper

import cython
from cpython.function cimport PyFunction_GetCode
from cpython.mem cimport PyMem_Free
from cpython.object cimport PyObject_CallObject
from cpython.pystate cimport PyInterpreterState, PyThreadState
from cpython.pythread cimport PyThread_tss_alloc, PyThread_tss_create, PyThread_tss_get, PyThread_tss_is_created, PyThread_tss_set
from cpython.ref cimport Py_DECREF, Py_INCREF
from cpython.tuple cimport PyTuple_New, PyTuple_SET_ITEM

cdef Py_tss_t *g_extra_slot = NULL


cdef Py_ssize_t _ensure_extra_index() except -1:
    global g_extra_slot
    if g_extra_slot is NULL:
        g_extra_slot = PyThread_tss_alloc()
    if not PyThread_tss_is_created(g_extra_slot):
        if PyThread_tss_create(g_extra_slot):
            return -1
    cdef Py_ssize_t index = <Py_ssize_t>PyThread_tss_get(g_extra_slot)
    if index == 0:
        index = _PyEval_RequestCodeExtraIndex(PyMem_Free)
        if index < 0:
            return index
        if PyThread_tss_set(g_extra_slot, <void *>((index << 1) | 0x01)):
            return -1
    else:
        index >>= 1

    return index


@cython.final
cdef class Node:
    cdef public object value
    cdef public bint valid
    cdef public set callers

    def __cinit__(self):
        self.value = None
        self.valid = False
        self.callers = set()

    cpdef void invalidate(self):
        self.valid = False
        for caller in self.callers:
            caller.invalidate()


def _trampoline(*args):
    node = Node()
    Py_INCREF(node)
    return node


cdef object _code_wrapper(PyObject *code, bint create):
    """Create or retrieve LRU cache attached to code object

    PEP 523 adds a new `extra` field to code objects.  `skean` leverages that
    field to store a `functools._lru_cache_wrapper` to hold on to nodes which
    wrap function return values.

    Understanding how `skean` uses the wrapper differently from `functools` is
    important.  `functools` wraps the function directly.  This does not let us
    distinguish between wrapped and unwrapped results since only the wrapped
    function can be called.

    `skean` returns the _original_ function.  Calling it outside a `tracing`
    block bypasses the LRU cache.  In a `tracing` context, the default frame
    evaluation has been replaced by a custom function which calls this function
    with `create` set to `False`.
    """
    cdef Py_ssize_t index = _ensure_extra_index()
    cdef PyObject *extra

    cdef bint error = _PyCode_GetExtra(code, index, <void **>&extra)
    if not error and extra is not NULL:
        extra_obj = <PyObject *>extra
        return <object>extra_obj

    cdef object wrapper = None
    if create:
        wrapper = _lru_cache_wrapper(_trampoline, 128, True, _CacheInfo)
        if _PyCode_SetExtra(code, index, <PyObject *>wrapper):
            return None
        Py_INCREF(wrapper)

    return wrapper


cdef PyObject *_frame_caller(PyFrameObject *frame):
    cdef PyFrameObject *f_back = PyFrame_GetBack(frame)
    cdef PyObject *f_trace

    while f_back:
        f_trace = f_back.f_trace
        if f_trace:
            return f_trace
        f_back = PyFrame_GetBack(f_back)
    return NULL


cdef tuple _frame_args(PyFrameObject *frame_obj):
    cdef PyCodeObject *code_obj = PyFrame_GetCode(frame_obj)
    cdef Py_ssize_t argc = <Py_ssize_t>(code_obj.co_argcount + code_obj.co_kwonlyargcount)
    cdef PyObject **localsplus = <PyObject **>frame_obj.f_localsplus
    cdef tuple args = PyTuple_New(argc)

    for i in range(argc):
        PyTuple_SET_ITEM(args, i, <object>localsplus[i])
    return args


cdef PyObject *_PyEval_EvalFrameCache(PyFrameObject *frame, int throwflag) noexcept:
    cdef object wrapper = _code_wrapper(<PyObject *>PyFrame_GetCode(frame), 0)
    if wrapper is None:
        return _PyEval_EvalFrameDefault(frame, throwflag)

    cdef PyObject *caller = _frame_caller(frame)
    cdef tuple args = _frame_args(frame)
    cdef Node node = PyObject_CallObject(wrapper, args)  # TODO: _PyObject_Call(tstate, ...)

    cdef PyObject *value
    if node.valid:
        value = <PyObject *>node.value
    else:
        frame.f_trace = <PyObject *>node
        value = _PyEval_EvalFrameDefault(frame, throwflag)
        node.valid = True
        node.value = <object>value
    if caller is not NULL:
        node.callers.add(<Node>caller)
    return value


@cython.final
cdef class sheath:
    cdef object func
    cdef object wrapper

    def __cinit__(self, func):
        self.func = func
        self.wrapper = _code_wrapper(PyFunction_GetCode(func), 1)

    def __dealloc__(self):
        Py_DECREF(self.func)
        Py_DECREF(self.wrapper)

    def __call__(self, *args):
        return self.func(*args)

    def __getitem__(self, args):
        return PyObject_CallObject(self.wrapper, args if isinstance(args, tuple) else (args,))


@cython.final
cdef class tracing:
    cdef PyInterpreterState *interp

    def __init__(self):
        self.interp = PyInterpreterState_Get()

    def __enter__(self):
        _PyInterpreterState_SetEvalFrameFunc(self.interp, _PyEval_EvalFrameCache)
        return self

    def __exit__(self, type, value, traceback):
        _PyInterpreterState_SetEvalFrameFunc(self.interp, _PyEval_EvalFrameDefault)
