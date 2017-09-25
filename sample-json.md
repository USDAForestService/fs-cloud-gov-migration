[
  {
    "name":"middlelayer-service",
    "credentials": {
      "middlelayer_base_url": "",
      "middlelayer_password": "",
      "middlelayer_username": ""
    }
  },
  {
    "name":"intake-client-service",
    "credentials": {
      "intake_client_base_url": ""
    }
  },
  {
    "name":"login-service-provider",
    "credentials": {
      "issuer":"",
      "idp_username":"",
      "idp_password":"",
      "jwk":
        {"kty":"RSA",
        "e":"",
        "n":"",
        "d":"",
        "p":"",
        "q":"",
        "dp":"",
        "dq":"",
        "qi":"",
        "kid":""
        },
      "discovery_url":"https://idp.int.login.gov/.well-known/openid-configuration"
      }
  },
  {
    "name":"eauth-service-provider",
    "credentials": {
      "issuer":"",
      "cert":"",
      "private_key":"",
      "entrypoint":"https://www.cert.eauth.usda.gov/affwebservices/public/saml2sso",
      "whitelist":["sampleemailadmin@fs.fed.us"]
    }
  },
  {
    "name":"smtp-service",
    "credentials": {
      "smtp_server":"smtp-relay.gmail.com",
      "username": "",
      "admins": [""]
    }
  }

]
