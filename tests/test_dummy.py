import pytest
from c_icesat_2.dummy_module import dummy_foo


def test_dummy():
    assert dummy_foo(4) == (4 + 4)
