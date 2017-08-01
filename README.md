# Forest Service ePermit Migration
This migration script is to port over the [U.S.F.S. Online Permit system](https://github.com/18F/fs-online-permitting) to
a new organization in cloud.gov. It consists of three applications with
code in two separate repositories.

The repositories are the [https://github.com/18f/fs-intake-module] and the [https://github.com/18f/fs-middlelayer-api].

Each repository, has both a `staging` and  `production` housed in a separate space in the org.

At this point the migration does not include any migration of the data from either database.

## Running the script

Enter all of your envs in `env.sh` (env-sample.sh) includes all the necessary variables.
In bash shell script run:

`./migration.sh`

If you would like to not run the migration tasks and just create the new apps and corresponding services within an org run:

`./migration.sh `

## Afterwards
Deployer credentials on `circle ci` should be updated to the new deployer accounts.

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md) for additional information.

## Public Domain

This project is in the worldwide [public domain](LICENSE.md). As stated in [CONTRIBUTING](CONTRIBUTING.md):

> This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
>
> All contributions to this project will be released under the CC0 dedication. By submitting a pull request, you are agreeing to comply with this waiver of copyright interest.
