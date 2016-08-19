import re
from django.core.validators import EMPTY_VALUES
from django.utils import six


RFC_INCONVENIENT_WORDS = [
    'BUEI', 'BUEY', 'CACA', 'CACO', 'CAGA', 'CAGO', 'CAKA', 'CAKO',
    'COGE', 'COJA', 'COJE', 'COJI', 'COJO', 'CULO', 'FETO', 'GUEY',
    'JOTO', 'KACA', 'KACO', 'KAGA', 'KAGO', 'KOGE', 'KOJO', 'KAKA',
    'KULO', 'MAME', 'MAMO', 'MEAR', 'MEAS', 'MEON', 'MION', 'MOCO',
    'MULA', 'PEDA', 'PEDO', 'PENE', 'PUTA', 'PUTO', 'QULO', 'RATA',
    'RUIN',
]

DATE_RE = r'\d{2}((01|03|05|07|08|10|12)(0[1-9]|[12]\d|3[01])|02(0[1-9]|[12]\d)|(04|06|09|11)(0[1-9]|[12]\d|30))'
rfc_without_homoclave_re = re.compile(r'^[A-Z&Ññ]{3,4}%s$' % DATE_RE,
                                      re.IGNORECASE)


class RFCValidator(object):
    def __init__(self, rfc):
        self.rfc = rfc
        self.error_messages = {
            'empty': ('Empty RFC string'),
            'invalid': ('RFC with invalid substring'),
            'invalid_length': ('RFC with invalid length'),
            'invalid_checksum': ('Invalid checksum for RFC.'),
            'validation_error': ('Not a valid RFC.'),
        }

    def is_valid(self):
        if self.rfc in EMPTY_VALUES:
            return False, self.error_messages['empty']
        self.rfc = self.rfc.upper()
        if (len(self.rfc) < 12 and len(self.rfc) > 14):
            return False, self.error_messages['invalid_length']
        if self._has_homoclave(self.rfc):
            if not self.rfc[-1] == self._checksum(self.rfc[:-1]):
                return False, self.error_messages['validation_error']
        if self._has_inconvenient_word():
            return False, self.error_messages['invalid']
        return True, self.rfc

    def _has_homoclave(self, rfc):
        return not rfc_without_homoclave_re.match(rfc)

    def _checksum(self, rfc):
        """
        More info about this procedure:
            www.sisi.org.mx/jspsi/documentos/2005/seguimiento/06101/0610100162005_065.doc
        """
        chars = '0123456789ABCDEFGHIJKLMN&OPQRSTUVWXYZ-Ñ'
        if len(rfc) == 11:
            rfc = '-' + rfc

        sum_ = sum(i * chars.index(c)
                   for i, c in zip(reversed(range(14)), rfc))
        checksum = 11 - sum_ % 11

        if checksum == 10:
            return 'A'
        elif checksum == 11:
            return '0'

        return six.text_type(checksum)

    def _has_inconvenient_word(self):
        first_four = self.rfc[:4]
        return first_four in RFC_INCONVENIENT_WORDS
