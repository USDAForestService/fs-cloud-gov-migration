# U.S. Forest Service Open Forest Migration

[![FS ePermits Badge](https://img.shields.io/badge/-ePermit-006227.svg?colorA=FFC526&logo=data%3Aimage%2Fpng%3Bbase64%2CiVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAMAAAAolt3jAAACFlBMVEUAAAD%2F%2FyXsvSW8qiXLsCXjuSXyvyX7wiX2wSXqvCXUsyXBrCXvviX%2F%2FyX8yCWUmyVliSV%2FkyV7kSWIlyV0jiWZnSX9yCXNsSXRsiXWtCVWgyVYhCXZtiX%2FyCV8kiV%2BkiX%2FyiX%2FzCWIliWElSX%2FzSX2wiVniSV3kCX2wiXUtCU5eCVujCXWtCW%2FqyXDrSWtpCWwpSWmoiWypiXeuCWJlyWPmSXiuiX%2F1CXsvSXFriW4qSWrpCWElCVdhiWSmiW3qCXCrSXQsiXyvyX%2F1CX%2F%2FyP%2F5yX%2F0iX%2FxCXrvCX%2FxiX%2F0iX%2F5yUcbCU6eCVAeiUfbiVEfCVEfCVZhCVEfCUzdSUtcyVAeyVNfyVZhCVGfSVEfCUqciUSaSUIZCUYayWPmSUUaiUCYiUVaiU1diVjiCUjcCVNfyVFfCXnuyU%2FeiUqciVliSVPgCWQmSUlcCVQgSV7kSX%2FxiWHliVPgCWPmSUtcyWLlyUibyVXgyWzpyX%2FxyXJryUXayVahCWIliWOmCU4eCV2jyXBrCXcuCXMsSVbhSUYaiV1jyU4eCVOgCVujCU6eCUudCWAkyUlcCVEfCVehiVYhCU%2FeiVvjSUSaSUAYiUAYiU1diWAlCUxdSUAYSUBYiUTaSVvjSVqiyVGfSUcbCUQaCUPaCUNZyULZiURaSUYayU6eCVehiVehiV1jyVmiSVOgCVRgSVSgSV2jyVxjSVvjSVMulUvAAAATHRSTlMAAGrao3NYUFdvndVtADfb%2Ffn2%2BP3cOMHAl%2F39lT7v7jsx6eozTPT2UoT%2B%2F4%2FGz%2FL46ut68%2FJ4B1Kau9Pu%2F%2BzQt5NMBgAKGUikQxYIJokgEwAAAFtJREFUCNdjZGBEBiwMvIy2jIcZGRkZrRiPMTIyiFsiJPcxMkgyOsJ4OxhZGFgYOeE6SeMyMuhGI0yew8LAxI3gMqFxGRmMGUthvBZGRgZzFEczMDC4QJlbGRgA3KAIv74V5FUAAAAASUVORK5CYII%3D)](https://github.com/18F/fs-online-permitting)

## Overview
This migration script is to port over the [U.S.F.S. Open Forest system](https://github.com/18F/fs-open-forest) to
a new organization within cloud.gov, or presumably another cloud foundry instance. It consists of three applications with
code in two separate repositories.

The repositories are the [https://github.com/18f/fs-open-forest-platform] and the [https://github.com/18f/fs-open-forest-middlelayer-api].

Each application is deployed in both a `staging` and `production` environment housed in a separate space within the org cloud.gov org. For more on cloud.gov orgs and spaces, please see the [cloud foundry docs](https://docs.cloudfoundry.org/concepts/roles.html)

This migration script does not provide of either production or staging data held in the `s3` buckets or databases.

This repo may also help you manage the [connected services of the application](https://github.com/18F/fs-open-forest/wiki/Ongoing-site-architecture#connected-services), bound within [VCAP_SERVICE](https://docs.cloudfoundry.org/buildpacks/node/node-service-bindings.html#creds) in the environment variables.

## Running the script

### Prepare environment variables
Fill the following files with the appropriate credientials per environment. Please refer to (/#user-provided-services) to see what should be in each file:
* `json-envs/intake/intake-services-trees.json` # Staging for the platform
* `json-envs/intake/intake-services-production.json` # Production for the platform
* `json-envs/middlelayer/middlelayer-services-staging.json` # Staging for the middlelayer
* `json-envs/middlelayer/middlelayer-services-production.json` # Production for the middlelayer

Services themselves should be declared as such:
```
[
  {
    "name": "servicename1",
    "credentials": {
  	"key1": "anytype",
  	"key2": "anytype"
  	}
  },
  {
    "name":"servicename1",
    "credentials" : {
          "key3": "anytype",
          "key4": "anytype"
  }
]
```

Please make sure you have the [cf multi-cups plugin](https://github.com/18F/cf-multi-cups-plugin) installed. 

`./migration.sh`

If you would like to not run the migration tasks and just create the new apps and corresponding services within an org run:

`./migration.sh false`


### Tasks following completion of the script:
### Update CI Keys
Deployer credentials on `circle ci` should be updated to the new deployer accounts.

### migrate middlelayer users
Create users on the middlelayer. Using this script.
```
cf t -s api-staging
cf ssh fs-middlelayer-api-staging
export HOME=/home/vcap/app
export TMPDIR=/home/vcap/tmp
cd /home/vcap/app
[ -d /home/vcap/app/.profile.d ] && for f in /home/vcap/app/.profile.d/*.sh; do source "$f"; done
source .profile.d/nodejs.sh
deps/0/bin/node app/cmd/createUser.js -u <MIDDLE_SERVICE_DEV_MIDDLELAYER_USERNAME> -p <MIDDLE_SERVICE_DEV_MIDDLELAYER_PASSWORD> -r admin

cf t -s api-production
cf ssh fs-middlelayer-api-staging
export HOME=/home/vcap/app
export TMPDIR=/home/vcap/tmp
cd /home/vcap/app
[ -d /home/vcap/app/.profile.d ] && for f in /home/vcap/app/.profile.d/*.sh; do source "$f"; done
source .profile.d/nodejs.sh
deps/0/bin/node app/cmd/createUser.js -u <MIDDLE_SERVICE_PROD_MIDDLELAYER_USERNAME> -p <MIDDLE_SERVICE_PROD_MIDDLELAYER_PASSWORD> -r admin
```

## Information in the connected services
### Authenication Certificates for eAuth and Login.gov
This section is more about how to generate some of the certificates for the services.

## Run the script
The easiest way to to generate certificates that will last one year is by running the following script:
```
./certificate-generation/make.sh <WHERE-TO-PUT-THE-OUTPUT>
```

Prerequisites:
`openssl` command line tool
`node.js`
`conf` files:
   - openssl-login-tree.conf
   - openssl-login-prod.conf
   - openssl-eauth-dev.conf
   - openssl-eauth-prod.conf
   
The `conf` file should just include the following information. (Please replace <VARIABLE> with your information).

```
[ req ]
default_bits           = 2048
distinguished_name     = req_distinguished_name
prompt                 = no

[ req_distinguished_name ]
commonName             = <API_APP_URL>
organizationName       = USDA
organizationalUnitName = FORESTSERVICE
localityName           = Washington
stateOrProvinceName    = DC
countryName            = US
emailAddress           = fs@fs.fed.us
```

This script will create 4 certificates and private keys for the identity providers that Open Forest uses.
The private keys will all go into the user-provided services `VCAP-SERVICES` with cloud.gov.

#### Eauth Certs and other eauth-service-provider information
```
environment: platform
name: eauth-service-provider
```

`cert`: From the SAML provider from the ICAM partnership in the `<ds:X509Certificate>` key. This should be the same across environments.
`private_key`: contents of the key from the following command:

```
openssl req -days 3650 -newkey rsa:2048 -nodes -keyout keys/saml.key.enc.usdaforestserviceepermitENVNAME \
  -x509 -out certs/saml.crt.usdaforestserviceepermitENVNAME -config openssl-ENVNAME.conf
```

The cert will be proivded to the service provider via email.
`issuer`: the service provider ID submitted via email to ICAM.

`whitelist`: an array of object names extracted from a successful eauth authenication that can access the admin interface.


`{"admin_username":"USERFIRSTNAME_USERLASTNAME","forests":["all"]}`
or 
`{"admin_username":"USERFIRSTNAME_USERLASTNAME","forests":["mthood"]}`.

### Login.gov and login-service-provider information
```
environment: platform
name: login-service-provider
```

Generated with the following command

```
openssl req -days 3650 -newkey rsa:2048 -nodes -keyout keys/saml.key.enc.usdaforestserviceepermitENVNAME \
  -x509 -out certs/saml.crt.usdaforestserviceepermitENVNAME -config openssl-login-tree.conf
  ```

Then convert the `saml.key.enc.FILE` or `pem` to a jwk.
The public certificate will have to be registered in the int.idp.login.gov dashboard.
`issuer`: the SPID for login.gov partnership registered in the dashboard.
`idp_username` & `idp_password`: Basic auth for the login.gov dev service provider.

## User provided services
The [user provided services a cloud foundry feature](https://docs.cloudfoundry.org/devguide/services/user-provided.html) to help manage external 3rd party services. This ecosystem makes heavy use of them in order to manage the credentials of integrated services.

These user provided services are parsed as environment variables in a vcap-constant file in both the [platform definitions](https://github.com/18F/fs-open-forest-platform/blob/dev/wiki/development/environment-variables.md) and [middlelayer services](https://github.com/18F/fs-open-forest-middlelayer-api#environment-variables). While each repsortoriy will give a better indication of the services use, here are some of the expected values and how to generate them.

### User provided services for the platform
#### Intake service
```
environment: platform
name: intake-client-service
```

The url for the frontend in the environment
and the corresponding jwt_secret for the - verify.

#### SMTP service
```
environment: platform
name: smtp-service
```

SMTP credentials and or just email to permit `node-mailer` to send emails.

`admins`: an array of admins to receive administrator emails from the system for the Special use applications.

#### Middlelayer service
```
environment: platform
name: middlelayer-service
```

URL and credentials of the middlelayer application.

#### Pay.gov
```
environment: platform
name: pay-gov
```

The certificates for pay.gov can be generated with the following commands:

```
openssl pkcs12 -in paygov.pfx -out outfile.pem -nodes
```

The resulting file will have the `cert`, the leveraged `certificate certs` and the private key. The `certificate` will need to be an array of the certificates as strings in the following format:
```
"certificate": [
        "-----BEGIN CERTIFICATE-----\ncert1-----END CERTIFICATE-----\n",
        "-----BEGIN CERTIFICATE-----\ncert2-----END CERTIFICATE-----\n",
        "-----BEGIN CERTIFICATE-----\ncert3-----END CERTIFICATE-----\n",
        "-----BEGIN CERTIFICATE-----\ncert4-----END CERTIFICATE-----\n",
        "-----BEGIN CERTIFICATE-----\ncert5-----END CERTIFICATE-----\n"
      ],
```

 The private key should be added to the `private_key` in the user-provided service. The `password` used to generate will need to be added as well.


#### New Relic monitor
```
environment: platform
name: new-relic
```

License key for new relic monitor

#### JWT 
```
environment: platform
name: jwt
```

Enables JWT for Christmas tree permit retrieval

### User Provided services for the middlelayer
#### Connecting safely to the platform
```
environment: middlelayer
name: auth-service
```

`JWT_SECRET_KEY`: string for generating signed tokens while connecting to the platform.

#### Connecting safely to USFS Natural Resource Manager Special Use Datasystem (NRM SUDS)
```
environment: middlelayer
name: nrm-suds-url-service
```

`SUDS_API_URL`: string of NRM SUDS API url the environment is to connect to provided by NRM.
`password`: string of NRM SUDS api authenication password.
`username`: string of NRM SUDS api authenication username.

#### New Relic monitor
```
environment: middlelayer
name: new-relic
```

License key for new relic monitor.


## Notes for the deployment configuration
`cf ssh` is currently disabled for the production cloud.gov `api-production` and `public-production` spaces.

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md) for additional information.

## Public Domain

This project is in the worldwide [public domain](LICENSE.md). As stated in [CONTRIBUTING](CONTRIBUTING.md):

> This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
>
> All contributions to this project will be released under the CC0 dedication. By submitting a pull request, you are agreeing to comply with this waiver of copyright interest.
