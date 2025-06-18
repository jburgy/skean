#!/usr/bin/env python

"""Tests for `skean` package."""
import pytest

from skean import sheath, tracing


@pytest.fixture
def cached_factorial() -> sheath:
    """Sample pytest fixture.

    See more at: http://doc.pytest.org/en/latest/fixture.html
    """

    @sheath
    def factorial(n: int) -> int:
        return n * factorial(n - 1) if n else 1

    with tracing():
        factorial(10)

    return factorial


def test_callers(cached_factorial):
    """Sample pytest test function with the pytest fixture as an argument."""
    root = cached_factorial[0]

    n, factorial = 0, 1

    stack = [root]
    while stack:
        node = stack.pop()
        assert node.valid and node.value == factorial
        n += 1
        factorial *= n
        stack.extend(node.callers)


def test_invalidate(cached_factorial):
    root = cached_factorial[0]
    root.invalidate()
    stack = [root]
    while stack:
        node = stack.pop()
        assert not node.valid
        stack.extend(node.callers)
