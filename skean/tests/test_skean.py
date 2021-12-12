#!/usr/bin/env python

"""Tests for `skean` package."""
import pytest

from skean import sheath, tracing, get_lru_cache


@pytest.fixture
def lru_cache():
    """Sample pytest fixture.

    See more at: http://doc.pytest.org/en/latest/fixture.html
    """
    @sheath
    def factorial(n):
        return n * factorial(n - 1) if n else 1

    with tracing():
        factorial(10)

    return get_lru_cache(factorial)


def test_callers(lru_cache):
    """Sample pytest test function with the pytest fixture as an argument."""
    root = lru_cache(0)

    n, factorial = 0, 1

    stack = [root]
    while stack:
        node = stack.pop()
        value = node.value
        assert node.valid
        assert value == factorial
        n += 1
        factorial *= n
        stack.extend(node.callers)


def test_invalidate(lru_cache):
    root = lru_cache(0)
    root.invalidate()
    stack = [root]
    while stack:
        node = stack.pop()
        assert not node.valid
        stack.extend(node.callers)
