# Infrastructure As Code with `run_terraform`


## What is `run_terraform` ?

A wrapper script for [Hashicorp's `terraform`](https://www.terraform.io) written in Python.


## Features

- streamlines terraform use when used against AWS
- auto-creation of an s3 bucket for remote terraform state storage
- auto-creation of a DynamoDB table for terraform locking
- auto-configuration of the terraform backend configuration
- attempts to auto-sense when `terraform init` is needed, and calls it automatically
- gets/updates any terraform modules needed
- gets/updates any terraform providers used
- easily used against multiple AWS accounts, each referred to as an `AWS_PROFILE`
- encourages the splitting of terraform code into reasonable sized chunks, each known as a `RES_CLASS`
- strong validation of values for required environment variables to prevent running against the wrong account, etc
- multiple instances of a `RES_CLASS` can be instantiated as individual environments, each known as a `DEPLOY_ENV`
- terraform outputs are printed to `stdout`, all other screen output is via `stderr` so that outputs can be used by
  other processes such as CI or user scripts
- has colourful output scaled to the terminal window's width
- accompanied by `tfadmin` utility to manage validation options via the CLI
- supports pre-parsing of terraform scripts and interpolation using standard [jinja2](http://jinja.pocoo.org)
- due to [jinja2](http://jinja.pocoo.org) support, the
  '[cannot delete from mid-list](https://github.com/hashicorp/terraform/issues/15678)' terraform bug can be avoided
- supports storing encrypted secrets in DynamoDB leveraging [credstash](https://github.com/fugue/credstash)
- can generate ssh keypairs dynamically for each project, storing a copy in credstash and leaving a copy in `~/.ssh` too
- supplied with some sample `RES_CLASS` templates to get you up and running, add your own terraform code
  to `./terraform/res_classes/.templates/< your res class>/`, then use `tfadmin` to create working-copies from your
  template
- creates a specific (initially empty) `.tfvars` file under `./terraform/vars/` for each `AWS_PROFILE` and `RES_CLASS`
  ready for you to populate in order to override variable defaults where required
- has directory structure to encourage the use of terraform modules which can be vendored into
  `./terraform/modules/ours` for your home-grown modules, or into `./terraform/modules/theirs` for those you may wish
  to vendor from elsewhere (maybe the [terraform registry](https://registry.terraform.io))
- enforces not only a specific version of terraform, but also the name of the executable to easily support having
  multiple terraform binaries on the same machine


## Getting started

The first thing to do is to check out the project from [github.com](https://github.com/InnovateUKGitHub/run_terraform)
and change the working directory.

> :exclamation: Use your package manager to install `terrafrom`, `python`, `pip` and `virtualenv` before you begin.

```bash
$ git clone https://github.com/InnovateUKGitHub/run_terraform.git
$ cd run_terraform
$ virtualenv venv
$ . venv/bin/activate
$ pip install -r requirements.txt
```

> :warning: All `tfadmin` and `run_terraform` commands should be executed from the root of the repo as the paths to
> config files and directories are all referred to relative to this position in the filesystem.


### Managing validation

Initially no validation options are configured, so before we begin we must create some using the provided `tfadmin`
tool. For help try `tfadmin --help`:

```bash
$ bin/tfadmin --help
Found file                         etc/run_terraform_config.yml             😎
Usage:
    tfadmin (--help | -h)
    tfadmin (--version | -v)
    tfadmin list aws_regions
    tfadmin list aws_profiles
    tfadmin list res_classes
    tfadmin list deploy_env_prefixes
    tfadmin add aws_region <new_region_name>
    tfadmin add aws_profile <new_profile_name>
    tfadmin add res_class <new_res_class_name>
    tfadmin add deploy_env_prefix <new_deploy_env_prefix_name>
    tfadmin del aws_region <new_region_name>
    tfadmin del aws_profile <profile_name>
    tfadmin del res_class <res_class_name>
    tfadmin del deploy_env_prefix <deploy_env_prefix_name>

--help -h       show this
--version -v    show current tfadmin version
```

> :bulb: Note at the top of the output you can see that `tfadmin` referred to the config file
> `etc/run_terraform_config.yml`.  This file can be customised manually to affect how `tfadmin` and `run_terraform`
> behave.  A future enhancement may be the configuration of `./etc/run_terraform_config.yml` via `tfadmin` too, but in
> this release the file must be edited manually if required.


#### Maintaining AWS_REGIONs

The `tfadmin` tool can be used to maintain the AWS_REGIONs that you want your IAC to be ran against. It will maintain
the necessary validation entries in `./etc/run_terraform_validation.yml` under the `aws_regions` key.

```bash
$ bin/tfadmin list aws_regions
$ bin/tfadmin add aws_region eu-west-1
$ bin/tfadmin add aws_region eu-west-2
$ bin/tfadmin add aws_region eu-west-3
$ bin/tfadmin add aws_region us-east-1
$ bin/tfadmin del aws_region us-east-1
```

> :feet: Ensure you have *at least one* valid aws_region in the validation data


#### Maintaining AWS_PROFILEs

The `tfadmin` tool can be used to maintain AWS_PROFILEs.  It will maintain the `aws_profiles` key in
`./etc/run_terraform_validation.yml` and also directory structures for user-defined variables in `./vars`:

```bash
$ bin/tfadmin list aws_profiles
$ bin/tfadmin add aws_profile ${org_id}dev
$ bin/tfadmin add aws_profile ${org_id}test
$ bin/tfadmin add aws_profile ${org_id}prod
$ bin/tfadmin add aws_profile ${org_id}junk
$ bin/tfadmin del aws_profile ${org_id}junk
```

> :feet: replace `${org_id}` with a punchy TLA (Three Letter Acronym) for each organisation that you intend to use the
> `run_terraform` framework to manage


#### Maintaining RES_CLASSes

The `tfadmin` tool can be used to maintain RES_CLASSes.  It will maintain the `res_classes` key in
`./etc/run_terraform_validation.yml` and directory structures for user-defined variables in `./vars`.  It will also
create a copy of the template res_class of the same name from `/terraform/res_classes/.templates/<res_class>`.  Should
a template of the same name not exist, then a copy of the `misc` template will be used instead.

The example `account` template is special as it creates IAM users, policies, configures cloudwatch, internal and
external DNS zones for the account.  You will typically have one `account` style class with multiple `misc` style
classes built on top.

> :bulb: place your own templates under `/terraform/res_classes/.templates/`

```bash
$ bin/tfadmin list res_classes
$ bin/tfadmin add res_class account
$ bin/tfadmin add res_class mgmt
$ bin/tfadmin add res_class sales
$ bin/tfadmin add res_class project1
$ bin/tfadmin del res_class project1
$ bin/tfadmin del res_class sales
```

> :feet: create *only one* `account` class and at least one based on the `misc` class to get you up and running.  Check
> that they have been created in `/terraform/res_classes/` ready for customisation and execution.


#### Maintaining deploy_env_prefixes

The `tfadmin` tool can be used to maintain deploy_env_prefixes.  It will maintain the `deploy_env_prefixes` key in
`./etc/run_terraform_validation.yml`.  Validation will only allow a new `DEPLOY_ENV` to be created when its name begins
with a valid prefix.  This is to ensure some uniformity in your naming schemes.  For example, you might have like to
have a `RES_CLASS` called `mgmt` and enforce that all instances of that environment (`DEPLOY_ENVs`) should be prefixed
with `mgmt`, so names could be `mgmt-0`, `mgmt-nige-1`, `mgmt-junk`; however you can disallow names without the
prefix, such as arbitrary names like `testing-123`.

> :warning: at present any defined deploy_env_prefix may be used against any `RES_CLASS`

```bash
$ bin/tfadmin list deploy_env_prefixes
$ bin/tfadmin add deploy_env_prefix mgmt
$ bin/tfadmin add deploy_env_prefix sales
$ bin/tfadmin add deploy_env_prefix project1
$ bin/tfadmin del deploy_env_prefix project1
$ bin/tfadmin del deploy_env_prefix sales
```

> :feet: create *at least one* `deploy_env_prefix` perhaps called the same as your misc-based `res_class`.


### Check or edit `./etc/run_terraform_config.yml`

Before moving on to the `run_terraform` script, it's worth checking the options are set correctly for your environment
in `./etc/run_terraform_config.yml`.  At the very least you should ensure the settings for the executable version and
filename of your version of terraform are correct.

```yaml
...
terraform:
  enforce_version: v0.11
  executable: terraform
...
```

> :exclamation: changing some of the keys in the file without reading the source code first may have adverse affects


### The `run_terraform` Script

The `run_terraform` requires a number of environment variables (env-vars) be set when being called:


#### Environment Variables

- `AWS_PROFILE` (ALWAYS REQUIRED) should be set to the name of a corresponding section in `~/.aws/credentials`.  The
  format we have adopted for the profile name is `${org_id}XXXX` where XXXX is the account purpose, the whole string
  should be without any delimiters, just alphanumeric.  Validated against the settings managed via `tfadmin`.

- `RES_CLASS` is set to tell the script which collection of AWS resources to create.  Each AWS account will typically
  host multiple deployment environments, RES_CLASS is used to segment terraform state into small more manageable chunks
  (think VPCs).  See `./etc/run_terraform_validation.yml` for a list of implemented options.  It is recommended the
  first of such to create is the `account` RES_CLASS, which is intended for AWS account-wide stuff.  Then perhaps
  create a RES_CLASS per a project, eg: `mgmt`, `openshift`, `sales`, `projectx`, etc. Generally, we refer to the
  RES_CLASSES that sit on top of the _account level_ resource class as _environment level_ resource classes.  Validated
  against the settings managed via `tfadmin`.

- `DEPLOY_ENV` (NOT REQUIRED with the `account` RES_CLASS).  Set this to something to reflect the usage of the
  environment.  The format we have adopted for deployment environments is `${RES_CLASS}-XXXX-NN` where XXXX is the
  account purpose or owner, NN is an identifiable number, starting with 0 for the first environment in the series.
  Validated against the settings managed via `tfadmin`.

- `AWS_REGION` and/or `AWS_DEFAULT_REGION` (ALWAYS REQUIRED)


### Usage

> :exclamation: For initial bootstrap you can use the AWS root account keys (which you will need to login to the AWS
> web console to create).  You can delete them later.  This enables you to have a purist configuration where all your
> IAM users, keys, profiles and policies are entirely managed by terraform.

The format for running Terraform to deploy to AWS is along the lines of:

```bash
$ AWS_PROFILE=<aws account> AWS_REGION=<aws region> DEPLOY_ENV=<name of environment within account> \
  RES_CLASS=<resource class> bin/run_terraform <command> <options to pass to terraform>
```

#### Account level resources

For initial bootstrap, the account level resources should be created first:

```bash
$ AWS_PROFILE=${org_id}dev AWS_REGION=eu-west-2 RES_CLASS=account bin/run_terraform plan
$ AWS_PROFILE=${org_id}dev AWS_REGION=eu-west-2 RES_CLASS=account bin/run_terraform apply
```

The terraform code for account level resources should be placed in `terraform/account`, with variables assigned values
in `terraform/vars/account.tfvars`.  For a specific account, it is possible to override variables by defining a
`terraform/vars/${AWS_PROFILE}/account-${AWS_PROFILE}.tfvars` which will be used if it exists.

The account level resources include most IAM users, along with login profiles and AWS keys.  The secrets are outputs,
however, they are designed to not be seen accidentally.   Each IAM user's login password is PGP encrypted in the output
for the user defined in the `trusted_pgp_user` variable.  The output of the aws key and secret keys are both base64
encoded.  Furthermore, all three secrets are marked as `sensitive`, so will not show unless the attribute is set to
false to prevent the suppression of the output.

> :feet: temporarily set `sensitive = false` to reveal the secrets, then after an _apply_ copy them from the _outputs_
> and use `base64 --decode` or PGP to decode/decrypt them.

The account level resources will also create an external and internal DNS subdomain based upon the `AWS_PROFILE` name.

For example:

```
dev.<parent domain>
test.<parent domain>
prod.<parent domain>
```

> :warning: the default external parent domain is set to `example-domain.com`, the default internal parent domain is
> set to `example-domain.test`.

The parent domain is specified in the tfvars file, but that domain is not actually created via terraform.  Instead, we
often create and host the parent domain in another account.  If so, you must then _delegate_ the NS servers from your
new zone to be authoritative for your new parent external subdomain.


#### Environment level resources

For environment level resources:

```bash
$ AWS_PROFILE=${org_id}dev AWS_REGION=eu-west-2 RES_CLASS=mgmt DEPLOY_ENV=mgmt-0 bin/run_terraform plan
$ AWS_PROFILE=${org_id}dev AWS_REGION=eu-west-2 RES_CLASS=mgmt DEPLOY_ENV=mgmt-0 bin/run_terraform apply
$ AWS_PROFILE=${org_id}dev AWS_REGION=eu-west-2 RES_CLASS=mgmt DEPLOY_ENV=mgmt-0 bin/run_terraform destroy
```

The terraform for environment level resources should be placed in `./terraform/res_classes/<res_class>/`, with
variables assigned values in `./terraform/vars/${AWS_PROFILE}/<res_class>.tfvars` (default for all environments based
on that res_class) `./terraform/vars/${AWS_PROFILE}/<res_class>-<deploy_env>.tfvars`.  For a specific environment, it
is possible to override variables by defining a `terraform/vars/${AWS_PROFILE}/${RES_CLASS}-${DEPLOY_ENV}.tfvars` which
will be used if it exists.

> :pencil2: Secrets can then be read from the same environment level resource terraform runs, as well as subsequent
> Ansible runs too; however by default one environment can access another environments secrets. It is also possible to
> supply a context to `credstash` so that it further segment access to secrets stored in the same DynamoDB table.

To view the current secrets for a DEPLOY_ENV, try something like:

```bash
$ AWS_PROFILE=${org_id}dev credstash -t mgmt-0-secrets getall
```


#### Pre-Terraform templating

Terraform is only a relatively young product and lacks a few tricks here and there.  To bolster this, we've written a
jinja2-based python parser right into the `run_terraform` wrapper.  With the power of the jinja2 templating engine in
your hands you can create terraform resources using loops and conditional statements!

To use it, simply create a directory called `.pre` in the res_class directory (eg, `accounts/.pre`).  Next, create a
terraform file with a special `.tf.j2` extension inside the `.pre` directory.  This source file will be read and a new
destination file will be created in the parent res_class directory with the name `_pre_`<original filename less the
extension>`_override.tf`.  The resulting file will be consumed as part of the terraform run, but should not be edited
directly as it will be recreated from the template file each run.

The keys within the `pre_terraform` hash defined in `run_terraform_config.yml` can be used to enable/disable the
pre-terraform templating, or tweak how the feature operates.

> :warning: don't edit `_pre_*_override.tf` files directly as they are auto-generated each run

### Connecting to the bastion for your new environments

The scripts create a key based on the name of your `DEPLOY_ENV` which can be used to connect to the bastion. In this
example below, the deploy env is `mgmt-0` like this:

```bash
$ ssh-add ~/.ssh/mgmt-0_id_rsa_deploy

$ ssh -A -i ~/.ssh/mgmt-0_id_rsa_deploy ec2-user@$(AWS_PROFILE=${org_id}dev AWS_REGION=eu-west-2 RES_CLASS=mgmt DEPLOY_ENV=mgmt-0 bin/run_terraform output bastion_elb_dns_name)
```

> :muscle: alternatively, delegate your DNS and then you can SSH to your public DNS alias for your bastions

### Common errors and resolutions


#### Error configuring the backend "s3": 2 error(s) occurred

If you see an error like this:

```
Initializing the backend...
Error configuring the backend "s3": 2 error(s) occurred:

* "key": required field is not set
* "bucket": required field is not set
```

...then try a _terraform init_, eg:

```
$ AWS_PROFILE=${org_id}test AWS_REGION=eu-west-2 AWS_DEFAULT_REGION=eu-west-2 RES_CLASS=mgmt DEPLOY_ENV=mgmt-0 bin/run_terraform init
$ AWS_PROFILE=${org_id}test AWS_REGION=eu-west-2 AWS_DEFAULT_REGION=eu-west-2 RES_CLASS=mgmt DEPLOY_ENV=mgmt-0 bin/run_terraform plan
```


#### Error launching source instance: OptInRequired

If you see an error like this:

```
* aws_instance.scripts-server: Error launching source instance: OptInRequired: In order to use this AWS Marketplace product you need to accept terms and subscribe. To do so please visit http://aws.amazon.com/marketplace/pp?sku=aw0evgkw8e5c1q413zgy5pjce
	status code: 401, request id: 78288b03-91b0-4bca-98a2-187f4554afc3
```


#### Error launching source instance: InstanceLimitExceeded

...then follow the link and agree to the terms and conditions of the vendor to allow the use of their AMIs.


### Tainting selected instances for rebuild

Sometimes you may wish to blow away a node and rebuild it from scratch, whilst preserving the rest of the AWS
infrastructure.  Terraform taint can be used in such scenarios, for example:

```bash
$ AWS_PROFILE=${org_id}dev AWS_REGION=eu-west-2 RES_CLASS=mgmt DEPLOY_ENV=mgmt-0 bin/run_terraform taint aws_instance.webhost
$ AWS_PROFILE=${org_id}dev AWS_REGION=eu-west-2 RES_CLASS=mgmt DEPLOY_ENV=mgmt-0 bin/run_terraform plan
$ AWS_PROFILE=${org_id}dev AWS_REGION=eu-west-2 RES_CLASS=mgmt DEPLOY_ENV=mgmt-0 bin/run_terraform apply
```

Perhaps you might want to blow away all the instances at once, yet preserve the rest of the environment, then you could
try something like this:

```bash
$ while read instance; do
  echo "==== Tainting: ${instance}"
  AWS_PROFILE=${org_id}dev AWS_REGION=eu-west-2 RES_CLASS=mgmt DEPLOY_ENV=mgmt-0 bin/run_terraform taint ${instance}
done <<EOF
aws_instance.webhost
aws_instance.openshift-compute-node.0
aws_instance.openshift-compute-node.1
aws_instance.openshift-infra-node.0
aws_instance.openshift-infra-node.1
aws_instance.openshift-infra-node.2
aws_instance.openshift-master-node.0
aws_instance.openshift-master-node.1
aws_instance.openshift-master-node.2
aws_instance.scripts-server
EOF

$ AWS_PROFILE=${org_id}dev AWS_REGION=eu-west-2 RES_CLASS=mgmt DEPLOY_ENV=mgmt-0 bin/run_terraform plan
$ AWS_PROFILE=${org_id}dev AWS_REGION=eu-west-2 RES_CLASS=mgmt DEPLOY_ENV=mgmt-0 bin/run_terraform apply
```


### Stopping and starting instances


#### Stopping Instances

At home-time you should stop your development instances until the morning (although you may have scheduled autoscaling
groups for some already, so perhaps this is not so important).  You can craft a command similar to this one to do that
from the command-line:

> Remember to replace your AWS_PROFILE and tag Values to match your instances

```bash
$ AWS_PROFILE=${org_id}dev AWS_REGION=eu-west-2 aws ec2 describe-instances --query "Reservations[].Instances[].InstanceId" --filters="Name=tag:Environment,Values=mgmt-0"| ruby -e "require 'json'; JSON.parse(STDIN.read).each { |i| print i + ' ' }" | AWS_PROFILE=${org_id}dev xargs aws ec2 stop-instances --instance-ids
```

> Note the inline Ruby, `jq` sed, or python could also be used to convert the json output to a flat list
> of instance IDs for the `stop-instance` command


#### Starting Instances

Similarly, next morning you could run something like this to start the instances back up:

```bash
$ AWS_PROFILE=${org_id}dev AWS_REGION=eu-west-2 aws ec2 describe-instances --query "Reservations[].Instances[].InstanceId" --filters="Name=tag:Environment,Values=mgmt-0"| ruby -e "require 'json'; JSON.parse(STDIN.read).each { |i| print i + ' ' }" | AWS_PROFILE=${org_id}dev xargs aws ec2 start-instances --instance-ids
```

Give the instances a few minutes to spin up then run a _terraform apply_ to update any DNS entries, for example:

```bash
$ AWS_PROFILE=${org_id}dev AWS_REGION=eu-west-2 RES_CLASS=mgmt DEPLOY_ENV=mgmt-0 bin/run_terraform apply
```


### Contributing

Please contribute to this project and help us make `run_terraform` a better framework.  Simply fork the repo and submit
PRs in the usual manner.
