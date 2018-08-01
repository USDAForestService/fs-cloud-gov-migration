'use strict';

// Load dependencies
const assert = require('assert')
const fs = require('fs')
const pem2jwk = require('pem-jwk').pem2jwk

const pemFileName = process.argv.slice(2,3)[0];
console.log(pemFileName);

var str = fs.readFileSync(pemFileName);
var jwk = pem2jwk(str);
console.log("JWK")
console.log(jwk);