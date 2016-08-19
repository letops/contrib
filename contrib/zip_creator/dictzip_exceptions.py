#!/usr/bin/env python
__author__ = 'parias'

A = 2

class DictZipError(Exception):
    def __init__(self, value):
        self.value = value

    def __str__(self):
        return repr(self.value)


class StructureIsNotAListError(DictZipError):
    def __init__(self):
        DictZipError.__init__(self, "Structure must be a list of dict and/or str")

    def __str__(self):
        return repr(self.value)


class InvalidElementInStructure(DictZipError):
    def __init__(self):
       DictZipError.__init__(self, "Elements from structure must be: dict or str")

    def __str__(self):
        return repr(self.value)

class KeyInDictElementIsNotAString(DictZipError):
    def __init__(self):
       DictZipError.__init__(self, "The keys in the dict elements of the structure must be str")

    def __str__(self):
        return repr(self.value)