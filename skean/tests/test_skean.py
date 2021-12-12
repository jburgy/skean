#!/usr/bin/env python

"""Tests for `skean` package."""
import pytest

from skean import sheath, tracing, get_lru_cache


@pytest.fixture
def response():
    """Sample pytest fixture.

    See more at: http://doc.pytest.org/en/latest/fixture.html
    """
    # import requests
    # return requests.get('https://github.com/audreyr/cookiecutter-pypackage')


def test_content():
    """Sample pytest test function with the pytest fixture as an argument."""
    # from bs4 import BeautifulSoup
    # assert 'GitHub' in BeautifulSoup(response.content).title.string

    @sheath
    def outer(f, a, b):
        return f(a, b)

    @sheath
    def inner(a, b):
        return a + b

    with tracing():
        print(outer(inner, 4, 5.0))

    node = get_lru_cache(inner)(4, 5.0)
    print(node, node.callers)
    # print(lru_cache.cache_info())


test_content()