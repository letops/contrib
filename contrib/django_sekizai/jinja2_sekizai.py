from __future__ import absolute_import, unicode_literals

from jinja2 import nodes
from jinja2.ext import Extension

from sekizai.templatetags.sekizai_tags import AddData, Addtoblock, RenderBlock, WithData


# NOTE: TRASH... WONT EVEN BOTHER TO ERASE IT JUST TO MAKE A POINT THAT IT IS NOT POSSIBLE
#                   24 hours of my life to the trash...

class AddtoblockExtension(Extension):
    tags = set(['addtoblock'])

    def parse(self, parser):
        lineno = next(parser.stream).lineno
        blockName = parser.parse_expression()

        if isinstance(blockName, nodes.Name):
            blockName = nodes.Const(blockName.name)
        args = [blockName]

        body = parser.parse_statements(['name:endaddtoblock'], drop_needle=True)
        block = Addtoblock(parser, blockName)
        return nodes.CallBlock(
                self.call_method('_addtoblock', args),
                [],
                [],
                body
            ).set_lineno(lineno)

    def _addtoblock(self, name, caller):
        original_content = caller()
        context = {
            'original_content': original_content
        }
        return ("<h1>Hi</h1>")
        # pass
        # return Addtoblock(parser, original_content).render_tag(context, name, False, None, context)

    def get_original_content(self, context):
        return context['original_content']

# Nicer import names
sekizai = AddtoblockExtension
