from django.contrib import messages
from django.utils.translation import ugettext_lazy as _ugl


GRAY = 'gray'
GREEN = 'green'
BLUE = 'blue'
YELLOW = 'yellow'
RED = 'red'

SUCCESS = _ugl('Success')
ERROR = _ugl('Error')
WARNING = _ugl('We are sorry')

errors_list = {
    'title': {
        '400': _ugl('Bad Request'),
        '401': _ugl('Unauthorized'),
        '403': _ugl('Forbidden'),
        '404': _ugl('Not Found'),
        '405': _ugl('Method not allowed'),
        '406': _ugl('Not Acceptable'),
        '409': _ugl('Conflict'),
        '415': _ugl('Unsupported Media Type'),
        '500': _ugl('Internal Server Error'),
        '503': _ugl('Service Unavailable'),
        'sorry': 'Lo sentimos',
    },
    'body': {
        'no_action': _ugl('We are sorry. You are trying to execute an unknown'
                          ' or prohibited action.'),
        'incorrect_method': _ugl('We are sorry. You are trying to execute an'
                                 ' action with an incorrect header or'
                                 ' method.'),
        'missing_step': _ugl('We are sorry. You must complete the previous'
                             ' steps to execute this action.'),
        'bad_login': _ugl('The user/password combination is invalid. Please'
                          ' try again.'),
        'no_perm': _ugl('You do not have enough permissions to execute this'
                        ' action. If this is a mistake, please contact the'
                        ' administrator.'),
        'ticket': _ugl('An internal error has occurred. The administrator has'
                       ' been notified.'),
        'encryption': 'La combinación de cer, key y contraseña es incorrecta.'
                      ' Los cambios en estos 3 campos se han descartado.',
        'verification_pending': 'Aún no ha verificado su correo electrónico.',
        'verification_error': 'El correo no existe en el sistema o ya fue'
                              ' verificado anteriormente.',
        'not_in_team': 'Usted no pertenece a este negocio.',
        'no_team': 'El negocio no existe en el sistema.',
        'already_claimed': 'Esta invitación ya fue procesada anteriormente.',
        'already_in_team': 'El usuario ya se encuentra en este negocio.',
    }
}


def generate_msg(request, state=GRAY, title='Debug', body='Empty'):
    mtype = None
    if state == GRAY:
        mtype = messages.DEBUG
    elif state == GREEN:
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
