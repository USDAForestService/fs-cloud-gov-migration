sample json

login-service-provider
{
  "issuer":"",
  "IDP_USERNAME":"",
  "IDP_PASSWORD":"",
  "jwk":{},
  "discoveryurl":""
}

eauth-service-provider
{
  "issuer":"fs-intake-api-staging.app.cloud.gov",
  "cert":"",
  "privatekey":"",
  "entrypoint":"https://www.cert.eauth.usda.gov/affwebservices/public/saml2sso",
  "whitelist":["smokey@fs.fed.us"]
}

smtp-service
{
  "smtpserver":"",
  "username": ""
}
