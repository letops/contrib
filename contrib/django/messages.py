from django.contrib import messages
from django.utils.translation import ugettext as _ug

GREEN = 'green'
BLUE = 'blue'
YELLOW = 'yellow'
RED = 'red'

SUCCESS = _ug('Success')
ERROR = _ug('Error')
WARNING = _ug('We are sorry')

errors_list = {
    'title': {
        '400': _ug('Bad Request'),
        '401': _ug('Unauthorized'),
        '403': _ug('Forbidden'),
        '404': _ug('Not Found'),
        '405': _ug('Method not allowed'),
        '406': _ug('Not Acceptable'),
        '409': _ug('Conflict'),
        '415': _ug('Unsupported Media Type'),
        '500': _ug('Internal Server Error'),
        '503': _ug('Service Unavailable'),
    },
    'body': {
        'no_action': _ug('We are sorry. You are trying to execute an unknown or prohibited action.'),
        'incorrect_method': _ug('We are sorry. You are trying to execute an action with an incorrect header or method.'),
        'missing_step': _ug('We are sorry. You must complete the previous steps to execute this action.'),
        'bad_login': _ug('The user/password combination is invalid. Please try again.'),
        'no_perm': _ug('You do not have enough permissions to execute this action. If this is a mistake, '
                       'please contact the administrator.'),
        'ticket': _ug('An internal error has occurred. The administrator has been notified.'),
        'encryption': 'Ha ocurrido un error interno. La combinación de cer, key y contraseña es incorrecta.',
    }
}


def generate_msg(request, state=BLUE, title='Empty', body='Empty'):
    mtype = None
    if state == GREEN:
        mtype = messages.SUCCESS
    elif state == BLUE:
        mtype = messages.INFO
    elif state == YELLOW:
        mtype = messages.WARNING
    elif state == RED:
        mtype = messages.ERROR

    messages.add_message(
        request,
        mtype,
        extra_tags=title,
        message=body,
        fail_silently=True
    )
