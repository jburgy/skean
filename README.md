# skean

`skean` is a [PEP 523](https://peps.python.org/pep-0523/)-based hack to
add Excel-like [reactivity](https://en.wikipedia.org/wiki/Reactive_programming) to
python function calls.  It exposes a decorator (`sheath`) to memoize functions and give them
push-based invalidation semantics. These semantics only occur in contexts managed by
`skean.tracing`.  Think of it as unidirectional [Trellis](https://pypi.org/project/Trellis/).

## contrived example
```python
from skean import sheath, tracing

@sheath
def get_celsius() -> float:
    # pretend it's a slow API that warrants memoizing
    return 50.0


@sheath
def get_fahrenheit() -> float:
    return (get_celsius() - 32) / 1.8


with tracing():
    assert get_fahrenheit() == 10.0

# the previous call established a link between `get_celsius` and `get_fahrenheit`
# `sheath` behave like `functools.lru_cache` whose memoized results can be retrieved
# (via `__getitem__`) and, if necessary, invalidated

celsius = get_celsius[()]
assert celsius.valid is True
fahrenheit = get_fahrenheit[()]
assert celsius.callers == {fahrenheit}

# Demo invalidation (notify transitive closure of callers)
assert fahrenheit.valid is True
celsius.invalidate()
assert fahrenheit.valid is False
```


## Note on the name
Like the [Dataflow programming](https://en.wikipedia.org/wiki/Dataflow_programming)
page explains, `skean` models a program as a [Directed Acyclic Graph](https://en.wikipedia.org/wiki/Directed_acyclic_graph)
or DAG.  As such, the name dagger came to mind.  Unfortunately, [dagger](https://pypi.org/project/dagger/)
already exists on PyPI so we looked for synonyms.

According to wiktionary, a skean is a "double-edged, leaf-shaped, typically bronze dagger
formerly used in Ireland and Scotland."  This project's code quality clearly makes its usage
[double-edged](https://en.wiktionary.org/wiki/double-edged). 
