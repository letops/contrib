from django.contrib.staticfiles.storage import staticfiles_storage
from django.core.urlresolvers import reverse

from compressor.contrib.jinja2ext import CompressorExtension
from jinja2 import Environment

# DEPRECATED .... NOT REQUIRED. USED DJANGO_JINJA INSTEAD OF PLAIN JINJA2


def environment(**options):
    env = Environment(**options)
    env.globals.update({
       'static': staticfiles_storage.url,
       'url': reverse,
    })
    return env
