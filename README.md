# Forest Service ePermit Migration

[![FS ePermits Badge](https://img.shields.io/badge/-ePermit-006227.svg?colorA=FFC526&logo=data%3Aimage%2Fpng%3Bbase64%2CiVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAMAAAAolt3jAAACFlBMVEUAAAD%2F%2FyXsvSW8qiXLsCXjuSXyvyX7wiX2wSXqvCXUsyXBrCXvviX%2F%2FyX8yCWUmyVliSV%2FkyV7kSWIlyV0jiWZnSX9yCXNsSXRsiXWtCVWgyVYhCXZtiX%2FyCV8kiV%2BkiX%2FyiX%2FzCWIliWElSX%2FzSX2wiVniSV3kCX2wiXUtCU5eCVujCXWtCW%2FqyXDrSWtpCWwpSWmoiWypiXeuCWJlyWPmSXiuiX%2F1CXsvSXFriW4qSWrpCWElCVdhiWSmiW3qCXCrSXQsiXyvyX%2F1CX%2F%2FyP%2F5yX%2F0iX%2FxCXrvCX%2FxiX%2F0iX%2F5yUcbCU6eCVAeiUfbiVEfCVEfCVZhCVEfCUzdSUtcyVAeyVNfyVZhCVGfSVEfCUqciUSaSUIZCUYayWPmSUUaiUCYiUVaiU1diVjiCUjcCVNfyVFfCXnuyU%2FeiUqciVliSVPgCWQmSUlcCVQgSV7kSX%2FxiWHliVPgCWPmSUtcyWLlyUibyVXgyWzpyX%2FxyXJryUXayVahCWIliWOmCU4eCV2jyXBrCXcuCXMsSVbhSUYaiV1jyU4eCVOgCVujCU6eCUudCWAkyUlcCVEfCVehiVYhCU%2FeiVvjSUSaSUAYiUAYiU1diWAlCUxdSUAYSUBYiUTaSVvjSVqiyVGfSUcbCUQaCUPaCUNZyULZiURaSUYayU6eCVehiVehiV1jyVmiSVOgCVRgSVSgSV2jyVxjSVvjSVMulUvAAAATHRSTlMAAGrao3NYUFdvndVtADfb%2Ffn2%2BP3cOMHAl%2F39lT7v7jsx6eozTPT2UoT%2B%2F4%2FGz%2FL46ut68%2FJ4B1Kau9Pu%2F%2BzQt5NMBgAKGUikQxYIJokgEwAAAFtJREFUCNdjZGBEBiwMvIy2jIcZGRkZrRiPMTIyiFsiJPcxMkgyOsJ4OxhZGFgYOeE6SeMyMuhGI0yew8LAxI3gMqFxGRmMGUthvBZGRgZzFEczMDC4QJlbGRgA3KAIv74V5FUAAAAASUVORK5CYII%3D)](https://github.com/18F/fs-online-permitting)

This migration script is to port over the [U.S.F.S. Online Permit system](https://github.com/18F/fs-online-permitting) to
a new organization in cloud.gov. It consists of three applications with
code in two separate repositories.

The repositories are the [https://github.com/18f/fs-permit-platform] and the [https://github.com/18f/fs-middlelayer-api].

Each repository, has both a `staging` and `production` housed in a separate space in the org.

At this point the migration does not include any migration of the data from either database.

## Running the script

Enter all of your envs in `env.sh` (env-sample.sh) includes all the necessary variables.
In bash shell script run:

`./migration.sh`

If you would like to not run the migration tasks and just create the new apps and corresponding services within an org run:

`./migration.sh false`

## Afterwards
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

## Authenication
### Eauth Certs
#### X509
`cert`: From the SAML provider from the ICAM partnership in the `<ds:X509Certificate>` key. This should be the same across environments.
`private_key`: contents of the key from the following command:

```
openssl req -days 3650 -newkey rsa:2048 -nodes -keyout keys/saml.key.enc.usdaforestserviceepermitENVNAME \
  -x509 -out certs/saml.crt.usdaforestserviceepermitENVNAME -config openssl-ENVNAME.conf
```

The cert will be proivded to the service provider via email.
`issuer`: the service provider ID submitted via email to ICAM.

`whitelist`: list of eAuth IDs that can access the admin interface.

### Login.gov
Generated with the following command

```
openssl req -days 3650 -newkey rsa:2048 -nodes -keyout keys/saml.key.enc.usdaforestserviceepermitENVNAME \
  -x509 -out certs/saml.crt.usdaforestserviceepermitENVNAME -config openssl-login-tree.conf
  ```

Then convert the `saml.key.enc.FILE` or `pem` to a jwk.
The public certificate will have to be registered in the int.idp.login.gov dashboard.
`issuer`: the SPID for login.gov partnership registered in the dashboard.
`idp_username` & `idp_password`: Basic auth for the login.gov dev service provider.


## Intake service
The url for the frontend in the environment
and the corresponding jwt_secret for the - verify.

## SMTP service
SMTP credentials and or just email to permit `node-mailer` to send emails.
`admins`: an array of admins to recieve administrator emails from the system.

# Middlelayer service
URL and credentials of the middlelayer.



## Contributing

See [CONTRIBUTING](CONTRIBUTING.md) for additional information.

## Public Domain

This project is in the worldwide [public domain](LICENSE.md). As stated in [CONTRIBUTING](CONTRIBUTING.md):

> This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
>
> All contributions to this project will be released under the CC0 dedication. By submitting a pull request, you are agreeing to comply with this waiver of copyright interest.
