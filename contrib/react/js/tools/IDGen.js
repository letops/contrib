// Obtained and edited from:
// https://goo.gl/hg2yDP
var lastId = 0;

function IDGen(prefix='id') {
  lastId++;
  return `${prefix}${lastId}`;
}

module.exports = IDGen;
