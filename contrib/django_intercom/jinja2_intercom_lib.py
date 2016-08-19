# -*- coding: utf-8 -*-
import logging

from intercom.templatetags import intercom as _intercom
from GRVTY.settings import IN_DEVELOPMENT
from django_jinja import library
from django.template.loader import render_to_string
from functools import wraps
import jinja2

logger = logging.getLogger(__name__)


def debug_silence(error_output=''):
    def inner(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            try:
                return fn(*args, **kwargs)
            except Exception as exc:
                if not IN_DEVELOPMENT:
                    raise
                logger.error('Error: %s', exc)
                return error_output
        return wrapper
    return inner


    # @debug_silence(error_output=None)
@library.global_function
@library.render_with('intercom/intercom_tag.jinja')
def intercom_tag(*args, **kwargs):
    intercom_data = _intercom.intercom_tag(kwargs)
    return intercom_data


@library.filter
@jinja2.contextfilter
def intercom_render(context, value):
    return render_to_string(
        'intercom/intercom_tag.jinja',
        _intercom.intercom_tag(context)
    )
