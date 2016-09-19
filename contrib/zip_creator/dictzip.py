#!/usr/bin/env python
import os
import zipfile
import json
from dictzip_exceptions import StructureIsNotAListError, \
    InvalidElementInStructure, KeyInDictElementIsNotAString

__author__ = 'parias'


def archive(structure, filename='archive.zip', base_path='.', dump_path='.'):
    if not isinstance(structure, list):
        raise StructureIsNotAListError()

    zip = zipfile.ZipFile(filename, 'w', zipfile.ZIP_DEFLATED)  # FIXME: base_path and dump_path?
    zip_path = []

    add_element(zip, zip_path, structure, base_path)


def add_element(zip, zip_path, structure, base_path):
    dirname = os.path.normpath('/'.join(zip_path))

    for element in structure:
        # if dict, then is a directory
        if isinstance(element, dict):
            for key, sub_structure in element.items():
                if not isinstance(key, str):
                    raise KeyInDictElementIsNotAString

                zip_path.append(key)
                add_element(zip, zip_path, sub_structure, base_path)
                zip_path.pop()

        # if str, then URL of file
        elif isinstance(element, str):
            filename = os.path.basename(element)
            if not filename:
                raise "Error for now"

            zip.write(
                os.path.join(base_path, element),
                os.path.join(dirname, filename)
            )

        else:
            raise InvalidElementInStructure()

# archive(
#     [
#         {
#             "2": ["dictzip.py", "dictzip_exceptions.py", {"inside": ["test/dictzip.txt"]}],
#             "chido" : ["test/a.txt"]
#         }
#     ],
# )
