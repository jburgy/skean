from cpython.pystate cimport PyInterpreterState, PyThreadState
from cpython.ref cimport PyObject


cdef extern from "code.h":
    ctypedef struct PyCodeObject:
        int co_argcount         # arguments, except *args
        int co_posonlyargcount  # #positional only arguments
        int co_kwonlyargcount   # #keyword only arguments
        # ...

    ctypedef void freefunc(void *)

    int _PyCode_GetExtra(PyObject *code, Py_ssize_t index, void **extra)
    int _PyCode_SetExtra(PyObject *code, Py_ssize_t index, void *extra)


cdef extern from "frameobject.h":
    ctypedef struct PyTryBlock:
        int b_type              # what kind of block this is
        int b_handler           # where to jump to find handler
        int b_level             # value stack level to pop to

    ctypedef struct PyFrameObject:
        PyFrameObject *f_back   # previous frame, or NULL
        PyCodeObject *f_code    # code segment
        PyObject *f_builtins    # builtin symbol table (PyDictObject)
        PyObject *f_globals     # global symbol table (PyDictObject)
        PyObject *f_locals      # local symbol table (any mapping)
        PyObject **f_valuestack  # points after the last local
        # Next free slot in f_valuestack.  Frame creation sets to f_valuestack.
        # Frame evaluation usually NULLs it, but a frame that yields sets it
        # to the current stack top.
        PyObject **f_stacktop
        PyObject *f_trace       # Trace function
        char f_trace_lines      # Emit per-line trace events?
        char f_trace_opcodes    # Emit per-opcode trace events?

        # Borrowed reference to a generator, or NULL
        PyObject *f_gen

        int f_lasti             # Last instruction if called
        #  Call PyFrame_GetLineNumber() instead of reading this field
        # directly.  As of 2.3 f_lineno is only valid when tracing is
        # active (i.e. when f_trace is set).  At other times we use
        # PyCode_Addr2Line to calculate the line from the current
        # bytecode index.
        int f_lineno            # Current line number
        int f_iblock            # index in f_blockstack
        char f_executing        # whether the frame is still executing
        PyTryBlock f_blockstack[20]  # for try and loop blocks
        PyObject *f_localsplus[1]  # locals+stack, dynamically sized

    PyFrameObject *PyFrame_GetBack(PyFrameObject *frame)


cdef extern from "pyframe.h":
    PyCodeObject *PyFrame_GetCode(PyFrameObject *frame)


cdef extern from "pystate.h":
    PyInterpreterState *PyInterpreterState_Get()

    ctypedef PyObject *(*_PyFrameEvalFunction)(PyThreadState *tstate, PyFrameObject *frame, int exc)

    void _PyInterpreterState_SetEvalFrameFunc(PyInterpreterState *interp, _PyFrameEvalFunction eval_frame)


cdef extern from "ceval.h":
    PyObject *_PyEval_EvalFrameDefault(PyThreadState *tstate, PyFrameObject *frame, int exc)
    Py_ssize_t _PyEval_RequestCodeExtraIndex(freefunc)
