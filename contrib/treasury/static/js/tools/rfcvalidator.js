var RFC_INCONVENIENT_WORDS = [
  'BUEI', 'BUEY', 'CACA', 'CACO', 'CAGA', 'CAGO', 'CAKA', 'CAKO',
  'COGE', 'COJA', 'COJE', 'COJI', 'COJO', 'CULO', 'FETO', 'GUEY',
  'JOTO', 'KACA', 'KACO', 'KAGA', 'KAGO', 'KOGE', 'KOJO', 'KAKA',
  'KULO', 'MAME', 'MAMO', 'MEAR', 'MEAS', 'MEON', 'MION', 'MOCO',
  'MULA', 'PEDA', 'PEDO', 'PENE', 'PUTA', 'PUTO', 'QULO', 'RATA',
  'RUIN',
];

var RFC_ERROR_MESSAGES = {
  empty: 'RFC está vacío.',
  invalid: 'El RFC tiene una composición inválida',
  invalid_length: 'El RFC no tiene una longitud correcta.',
  invalid_checksum: 'El RFC no tiene un checksum correcto.',
  validation_error: 'El RFC no es válido.',
};

function validarRFC(rfc) {
  if (!rfc) {
    return [false, RFC_ERROR_MESSAGES.empty];
  }

  rfc = rfc.toUpperCase();
  if (12 > rfc.length > 14) {
    return [false, RFC_ERROR_MESSAGES.invalid_length];
  }

  if (tieneHomoclave(rfc)) {
    if (rfc.slice(-1) != checksum(rfc.slice(0, -1))) {
      return [false, RFC_ERROR_MESSAGES.validation_error];
    }
  }

  if (tienePalabraInconveniente(rfc)) {
    return [false, RFC_ERROR_MESSAGES.invalid];
  }

  return [true, rfc];
};

function tieneHomoclave(rfc) {
  return !rfcSinHomoclave(rfc);
};

function rfcSinHomoclave(rfc) {
  var patronFecha = '\d{2}((01|03|05|07|08|10|12)(0[1-9]|[12]\d|3[01])|02(0[1-9]|[12]\d)|(04|06|09|11)(0[1-9]|[12]\d|30))';
  var patronRFC = '^[A-Z&Ññ]{3,4}' + patronFecha + '$';
  var regex = new RegExp(patronRFC, 'i');
  var matches = regex.exec(rfc);
  return matches;
};

function checksum(rfc) {
  var chars = '0123456789ABCDEFGHIJKLMN&OPQRSTUVWXYZ-Ñ';
  var sum_ = 0;
  if (rfc.length == 11) {
    rfc = '-' + rfc;
  }

  for (var i = 13, j = 0; i > 0 && j < rfc.length; i--, j++) {
    sum_ += i * chars.indexOf(rfc[j]);
  }

  var checksum = 11 - sum_ % 11;

  if (checksum == 10) {
    return 'A';
  } else if (checksum == 11) {
    return '0';
  }

  return checksum.toString();
};

function tienePalabraInconveniente(rfc) {
  var firstFour = rfc.slice(0, 4);
  return RFC_INCONVENIENT_WORDS.indexOf(firstFour) != -1 ? true : false;
};

module.exports = validarRFC;
