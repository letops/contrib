# -*- coding: utf-8 -*-

from intercom.templatetags import intercom as _intercom
from jinja2 import nodes
from jinja2.ext import Extension


class IntercomExtension(Extension):
    tags = set(['intercom_tag'])

    def __init__(self, environment):
        self.environment = environment

    def parse(self, parser):
        lineno = parser.stream.expect('name:intercom_tag').lineno
        call = self.call_method(
            '_render',
            [nodes.Name('intercom_tag', 'load'), ],
        )
        return nodes.Output([nodes.MarkSafe(call)]).set_lineno(lineno)

    def _render(self, intercom_tag):
        return _intercom.intercom_tag(intercom_tag)
