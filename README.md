# U.S. Forest Service Open Forest Migration and Configuration

[![FS ePermits Badge](https://img.shields.io/badge/-ePermit-006227.svg?colorA=FFC526&logo=data%3Aimage%2Fpng%3Bbase64%2CiVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAMAAAAolt3jAAACFlBMVEUAAAD%2F%2FyXsvSW8qiXLsCXjuSXyvyX7wiX2wSXqvCXUsyXBrCXvviX%2F%2FyX8yCWUmyVliSV%2FkyV7kSWIlyV0jiWZnSX9yCXNsSXRsiXWtCVWgyVYhCXZtiX%2FyCV8kiV%2BkiX%2FyiX%2FzCWIliWElSX%2FzSX2wiVniSV3kCX2wiXUtCU5eCVujCXWtCW%2FqyXDrSWtpCWwpSWmoiWypiXeuCWJlyWPmSXiuiX%2F1CXsvSXFriW4qSWrpCWElCVdhiWSmiW3qCXCrSXQsiXyvyX%2F1CX%2F%2FyP%2F5yX%2F0iX%2FxCXrvCX%2FxiX%2F0iX%2F5yUcbCU6eCVAeiUfbiVEfCVEfCVZhCVEfCUzdSUtcyVAeyVNfyVZhCVGfSVEfCUqciUSaSUIZCUYayWPmSUUaiUCYiUVaiU1diVjiCUjcCVNfyVFfCXnuyU%2FeiUqciVliSVPgCWQmSUlcCVQgSV7kSX%2FxiWHliVPgCWPmSUtcyWLlyUibyVXgyWzpyX%2FxyXJryUXayVahCWIliWOmCU4eCV2jyXBrCXcuCXMsSVbhSUYaiV1jyU4eCVOgCVujCU6eCUudCWAkyUlcCVEfCVehiVYhCU%2FeiVvjSUSaSUAYiUAYiU1diWAlCUxdSUAYSUBYiUTaSVvjSVqiyVGfSUcbCUQaCUPaCUNZyULZiURaSUYayU6eCVehiVehiV1jyVmiSVOgCVRgSVSgSV2jyVxjSVvjSVMulUvAAAATHRSTlMAAGrao3NYUFdvndVtADfb%2Ffn2%2BP3cOMHAl%2F39lT7v7jsx6eozTPT2UoT%2B%2F4%2FGz%2FL46ut68%2FJ4B1Kau9Pu%2F%2BzQt5NMBgAKGUikQxYIJokgEwAAAFtJREFUCNdjZGBEBiwMvIy2jIcZGRkZrRiPMTIyiFsiJPcxMkgyOsJ4OxhZGFgYOeE6SeMyMuhGI0yew8LAxI3gMqFxGRmMGUthvBZGRgZzFEczMDC4QJlbGRgA3KAIv74V5FUAAAAASUVORK5CYII%3D)](https://github.com/18F/fs-online-permitting)

## Overview
This migration script is to port over the [U.S.F.S. Open Forest system](https://github.com/18F/fs-open-forest) to
a new organization within cloud.gov, or presumably another cloud foundry instance. It consists of three applications with
code in two separate repositories.

The repositories are the [https://github.com/18f/fs-open-forest-platform] and the [https://github.com/18f/fs-open-forest-middlelayer-api].

Each application is deployed in `development`, `staging`, and `production` environments housed in separate corresponding spaces within the cloud.gov org. For more on cloud.gov orgs and spaces, please see the [cloud foundry docs](https://docs.cloudfoundry.org/concepts/roles.html)

This migration script does not provide any data held in the `s3` buckets or databases.

This repo may also help you manage the [connected services of the application](https://github.com/18F/fs-open-forest/wiki/Ongoing-site-architecture#connected-services), bound within [VCAP_SERVICE](https://docs.cloudfoundry.org/buildpacks/node/node-service-bindings.html#creds) in the environment variables.

## Table of contents

- [Overview](#overview)
- [Table of contents](#table-of-contents)
- [Migration Requirements](#migration-requirements)
  - [Bash](#bash)
  - [Cloud Foundry CLI](#cloud-foundry-cli)
  - [Cloud Foundry Plugins](#cloud-foundry-plugins)
  - [JQ](#jq)
- [Environment Variables](#environment-variables)
  - [User Provided Services](#user-provided-services)
  - [Organization](#organization)
  - [Format](#format)
  - [Values](#values)
  - [Fetching](#fetching)
- [Migration](#migration)
- [After Migration](#after-migration)
  - [Update CI Keys](#update-ci-keys)
  - [Generate Middlelayer Users](#generate-middlelayer-users)
- [Updating Environment Variables](#updating-environment-variables)
- [Utilities](#utilities)
  - [Utilities Requirements](#utilities-requirements)
- [Notes](#notes)
- [Contributing](#contributing)
- [Public Domain](#public-domain)

## Migration Requirements

### Bash
All scripts in this repository are written using BASH. If you are using MacOS, Linux, Unix, this will be available in your default shell. If you are using Windows, please contact your IT support to determine the best way to run BASH scripts.

### Cloud Foundry CLI
- [CF CLI](https://github.com/cloudfoundry/cli)

### Cloud Foundry Plugins
- [multi-cups-plugin](https://github.com/18F/cf-multi-cups-plugin)
- [zero-downtime-deploy](https://github.com/contraband/autopilot)

### JQ
- [jq](https://stedolan.github.io/jq/)

## Environment variables
Prior to running the migration, you will need a local copy of the environment variables for each application.

### User provided services
The [user provided services a cloud foundry feature](https://docs.cloudfoundry.org/devguide/services/user-provided.html) to help manage external 3rd party services. This ecosystem makes heavy use of them in order to manage the credentials of integrated services.

These user provided services are parsed as environment variables in a vcap-constant file in both the [platform definitions](https://github.com/18F/fs-open-forest-platform/blob/dev/wiki/development/environment-variables.md) and [middlelayer services](https://github.com/18F/fs-open-forest-middlelayer-api#environment-variables). While each repository will give a better indication of the services use, here are some of the expected values and how to generate them.

[For more on why we use then instead of environment variables](https://github.com/18F/fs-open-forest-platform/blob/dev/docs/development/environment-variables.md#required-environment-variables).

### Organization
These should be organized in a group of `json` files, one per application: 
* `json-envs/intake/intake-services-dev.json`
* `json-envs/intake/intake-services-staging.json`
* `json-envs/intake/intake-services-production.json`
* `json-envs/middlelayer/middlelayer-services-dev.json`
* `json-envs/middlelayer/middlelayer-services-staging.json`
* `json-envs/middlelayer/middlelayer-services-production.json`

### Format
Each file should contain an array of the required services and credentials in the format below. See [VCAP_SERVICES](https://docs.cloudfoundry.org/devguide/deploy-apps/environment-variable.html#VCAP-SERVICES) for more information.
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
    "name":"servicename2",
    "credentials" : {
      "key3": "anytype",
      "key4": "anytype"
  },
  ...
]
```

### Values
For details on the required values see the documentation in the respective repository for each application:
- [Platform](https://github.com/18f/fs-open-forest-platform)
- [Middlelayer](https://github.com/18f/fs-open-forest-middlelayer-api)

### Fetching
To obtain all environment variables programmatically from existing Cloud Foundry infrastructure:
- Make sure you are in the root of this repository and have installed of the [requirements](#requirements)
- Log into the correct `org` with the Cloud Foundry CLI Ex. `cf login -a api.fr.cloud.gov -o usda-forest-service --sso`
- `./bin/get-credentials.sh` -- **Note** this will overwrite existing local files so save a copy if necessary.

## Migration

`./migration.sh`

If you would like to not run the migration tasks and just create the new apps and corresponding services within an org run:

`./migration.sh false`

## After Migration

### Update CI Keys
For each environment, a set of "deployer credentials" is generated for use in other systems that need to interact with Cloud[.]gov programmatically. Circle CI is configured with these credentials in order to trigger deploys to `staging` and `production` environments on the successful completion of automatic tests. In addition, certain other credentials, such as those for additional S3 buckets, are generated in Cloud[.]gov to leverage their brokered services. If any of these change, they will need to be updated in the Circle CI user interface as well:
- [Platform](https://circleci.com/gh/18F/fs-open-forest-platform/edit#env-vars)
- [Middlelayer](https://circleci.com/gh/18F/fs-open-forest-middlelayer-api/edit#env-vars)

### Generate Middlelayer Users
See [Middlelayer](https://github.com/18F/fs-open-forest-middlelayer-api) for instructions on how to generate a user. After a user is generated, the configuration for the 'platform' in the corresponding environment will have to be updated with the generated authentication credentials. See [Updating Environment Variables](#updating-environment-variables) for details.

## Updating environment variables
When credentials change, the environment variables in Cloud[.]gov will need to be updated and the corresponding application restaged. For the example below, we will assume a credential changed for the staging intake application. **WARNING** these changes are **IRREVERSABLE** so make sure to use the appropriate Cloud[.]gov `space`, `application`, and `env variable file`.

- Update your local copy by following the instructions [here](#fetching)
- Update the value in `json-envs/<env variable file>.json`
- `cf t -s <space>`
- `cf multi-cups-plugin -p json-envs/<env variable file>.json`
- `cf restage <application>`
- where
  - env variable file: `intake/intake-services-staging`
  - space: `open-forest-platform-staging`
  - application: `open-forest-platform-staging`

## Utilities
For our vendor integrations we are required to generate and provide certificates in order to sign and/or encrypt the transactions. We provide some useful scripts and instructions to help with this process.

### Utilities Requirements

#### OpenSSL
- [OpenSSL](https://www.openssl.org/)

#### Node
- [Node](https://nodejs.org/en/) (Prefer installing using a version manager such as [NVM](https://github.com/nvm-sh/nvm))

### X509 Certificate Generation
Login[.]gov and EAuth require X509 certificates to integrate. Generate a unique public certificate and private key for each integration and environment:

- Create a configuration file named `openssl-<integration-environment>.conf` in the `certificates/conf` folder where "integration-environment" is one of:
  - `login-tree` (-> Open Forest staging)
  - `login-prod`
  - `eauth-dev` (-> Open Forest staging)
  - `eauth-prod`

- Populate the configuration file with the following:
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

where "API_APP_URL" is the URL of the application.

- run `./certificate-generation/make.sh <integration-environment>` where "integration-environment" corresponds to the configuration file

  This will generate the following files:
  - `./certificates/keys/saml.key.enc.usda-forest-service-epermit-<integration-environment>`
  - `./certificates/certs/saml.crt.usda-forest-service-epermit-<integration-environment>`

- If necessary, create a Json Web Key (JWK) from the private key by following the steps in [JWK Generation](#jwk-generation).

- The appropriate public certificates in `certificates/certs` should be shared with the Eauth/Login[.]gov while the private keys (or corresponding JWK) will be used in our application configuration.

### JWK Generation
The Login[.]gov integration requires that the private key be provided in the form of a [Json Web Key](https://tools.ietf.org/html/rfc7517) or JWK.
- `npm install`
- `node certificate-generation/jwkmaker.js ./certificates/keys/saml.key.enc.usda-forest-service-epermit-<integration-environment>"`

### Certificate Generation
Pay[.]gov requires a Public Key Certificate to integrate. This section is not verified...
- obtain `paygov.pfx` FROM Pay[.]gov?
- run `openssl pkcs12 -in paygov.pfx -out outfile.pem -nodes`

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


## Notes
`cf ssh` is currently disabled for the production Cloud[.]gov `middlelayer-production` and `public-production` spaces.

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md) for additional information.

## Public Domain

This project is in the worldwide [public domain](LICENSE.md). As stated in [CONTRIBUTING](CONTRIBUTING.md):

> This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
>
> All contributions to this project will be released under the CC0 dedication. By submitting a pull request, you are agreeing to comply with this waiver of copyright interest.
