#!/usr/bin/env python2.7

import os
import shutil
import jinja2
import re
import sys
import boto3
import subprocess
import json
import errno
import hcl
import glob
import hashlib
import shutil

from botocore.client import ClientError
from botocore.client import Config
from blessings import Terminal
from yaml import load, dump
try:
    from yaml import CLoader as Loader, CDumper as Dumper
except ImportError:
    from yaml import Loader, Dumper

validatation_data_filename = 'etc/run_terraform_validation.yml'
config_data_filename = 'etc/run_terraform_config.yml'
term = Terminal()

class OurTemplate:
    """Class to implement templating"""
    def __init__(self, template_filename, output_filename, context):
        """Constructor"""
        self.template_filename    = template_filename
        self.output_filename      = output_filename
        self.context              = context
        self.j2env                = jinja2.Environment()
        self.j2env.filters['md5'] = self.md5_string

    def md5_string(self, value):
        """Return md5 hash of a given value"""
        return hashlib.md5(value).hexdigest()

    def render(self):
        """Render jinja2 template to text"""
        path, filename = os.path.split(self.template_filename)
        self.j2env.loader = jinja2.FileSystemLoader(path or './')
        return self.j2env.get_template(filename).render(self.context)

    def render_to_file(self):
        """Render jinja2 template to file"""
        if os.path.isfile(self.template_filename):
            self.output_file = open(self.output_filename, 'w')
            self.output_file.write(self.render())
            self.output_file.close()
        else:
            status_line(message="Path not found", result_msg=self.template_filename, result_bool=False)
            sys.exit(1)

def ensure_dir(directory):
    """Create a directory if it doesn't exist"""
    if not os.path.exists(directory):
        os.makedirs(directory)
    return directory

def remove_dir(directory):
    """Remove a directory structure"""
    shutil.rmtree(directory)

def check_exists(type, pathname, fail_if_missing=True):
    """Returns true of false if file or dir exists"""
    # TODO should be able to check if file is a file, dir is a dir too
    if (type == 'file' and os.path.isfile(pathname)) or (type == 'dir' and os.path.isdir(pathname)):
        status_line(message="Found " + type, result_msg=pathname, result_bool=True)
        return True
    else:
        status_line(message="Pathname NOT found", result_msg=pathname, result_bool=False)
        if fail_if_missing:
            sys.exit(12)
        else:
            return False

def check_env_vars(vdata):
    """Check required environment vars are set correctly"""
    # Validate Env-var AWS_PROFILE
    if not os.environ.has_key('AWS_PROFILE'):
        status_line(message="Env-var AWS_PROFILE must be set", result_bool=False)
        sys.exit(2)
    elif os.environ['AWS_PROFILE'] in vdata['aws_profiles']:
        status_line(message="Env-var AWS_PROFILE is valid", result_msg=os.environ['AWS_PROFILE'], result_bool=True)
    else:
        status_line(message="Env-var AWS_PROFILE must be one of...", result_bool=False)
        for item in vdata['aws_profiles']:
            print >> sys.stderr, '  - ' + item
        sys.exit(3)

    # Validate Env-var RES_CLASS
    if not os.environ.has_key('RES_CLASS'):
        status_line(message="Env-var RES_CLASS must be set", result_bool=False)
        sys.exit(4)
    elif os.environ['RES_CLASS'] in vdata['res_classes']:
        status_line(message="Env-var RES_CLASS is valid", result_msg=os.environ['RES_CLASS'], result_bool=True)
    else:
        status_line(message="Env-var RES_CLASS must be one of...", result_bool=False)
        for item in vdata['res_classes']:
            print >> sys.stderr, '  - ' + item
        sys.exit(5)

    # Validate Env-var AWS_REGION/AWS_DEFAULT_REGION
    if not os.environ.has_key('AWS_REGION'):
        if os.environ.has_key('AWS_DEFAULT_REGION'):
            select_region = os.environ['AWS_DEFAULT_REGION']
        else:
            status_line(message="Env-var AWS_DEFAULT_REGION must be set", result_bool=False)
            sys.exit(6)
    else:
        select_region = os.environ['AWS_REGION']

    if select_region in vdata['aws_regions']:
        status_line(message="Env-var AWS_REGION or AWS_DEFAULT_REGION is valid", result_msg=select_region, result_bool=True)
    else:
        status_line(message="Env-var AWS_REGION or AWS_DEFAULT_REGION must be one of...", result_bool=False)
        for item in vdata['aws_regions']:
            print >> sys.stderr, '  - ' + item
        sys.exit(7)

    # Validate Env-var DEPLOY_ENV
    if os.environ['RES_CLASS'] in ['account']:
        if os.environ.has_key('DEPLOY_ENV'):
            status_line(message="Env-var DEPLOY_ENV must NOT be set when RES_CLASS == account", result_bool=False)
            sys.exit(8)
    else:
        if not os.environ.has_key('DEPLOY_ENV'):
            status_line(message="Env-var DEPLOY_ENV must be set unless RES_CLASS == account", result_bool=False)
            sys.exit(9)
        elif re.split('\.*[-_]', os.environ['DEPLOY_ENV'])[0] in vdata['deploy_env_prefixes']:
            status_line(message="Env-var DEPLOY_ENV is valid", result_msg=os.environ['DEPLOY_ENV'], result_bool=True)
        else:
            status_line(message="Env-var DEPLOY_ENV prefix must be one of...", result_bool=False)
            for item in vdata['deploy_env_prefixes']:
                print >> sys.stderr, '  - ' + item
            sys.exit(10)

def enforce_terraform_version(config):
    """Only our specified version of terraform to be used"""
    try:
        tf_version = subprocess.check_output([config['terraform']['executable'], '--version'])
    except OSError:
        status_line(message="Terraform " + config['terraform']['executable'] + " not found in PATH", result_msg="enforcing " + config['terraform']['enforce_version'], result_bool=False)
        sys.exit(101)

    tf_version_required = "Terraform {0}".format(config['terraform']['enforce_version'])
    if tf_version_required not in tf_version:
        status_line(message="Enforcing Terraform " + config['terraform']['enforce_version'], result_msg="got {0}".format(tf_version), result_bool=False)
        sys.exit(50)
    else:
        status_line(message="Found " + tf_version, result_msg=config['terraform']['executable'], result_bool=True)


def write_terraform_backends(config):
    """Write out the terraform backend.tf files"""
    context = config['terraform_template']
    context.update(config['env_vars'])
    context.update(config['terraform'])
    ensure_dir(config['terraform']['backend_dir'])

    # Do this for all sub-dirs of terraform except: bin, vars, .terraform
    status_line(message="Generating backend", result_msg=config['terraform']['backend_varsfile'], result_bool=True)
    backend_template = OurTemplate(
        config['terraform']['backend_template_filename'],
        config['terraform']['backend_varsfile'],
        context)
    backend_template.render_to_file()

def check_we_have_params():
    """Count calling params and print usage"""
    if len(sys.argv) <= 1:
        os.system('terraform --help')
        sys.exit(11)

def check_current_backend_correct(config):
    """Check the state file to ensure the current backend is correct for the selected aws_profile/res_class/deploy_env"""
    state_file_path = os.path.join(os.getcwd(),'.terraform/terraform.tfstate')

    if check_exists('file', state_file_path, False):
        with open(state_file_path) as json_data:
            d = json.load(json_data)
            json_data.close()
            desired_bucket_name = config['env_vars']['aws_profile'] + '-' + config['terraform_template']['bucket_suffix']
            desired_bucket_key  = "{0}-{1}.tfstate".format(
                    config['env_vars']['aws_profile'] if not config['env_vars'].has_key('deploy_env') else config['env_vars']['deploy_env'],
                    config['env_vars']['res_class']
            )
            if 'backend' in d:
                if d['backend']['config']['bucket'] == desired_bucket_name and d['backend']['config']['key'] == desired_bucket_key:
                    status_line(message="Backend is already configured", result_msg="{0}/{1}".format(d['backend']['config']['bucket'], d['backend']['config']['key']), result_bool=True)
                    return True
            elif 'remote' in d:
                if d['remote']['config']['bucket'] == desired_bucket_name and d['remote']['config']['key'] == desired_bucket_key:
                    status_line(message="Backend is already configured", result_msg="{0}/{1}".format(d['backend']['config']['bucket'], d['backend']['config']['key']), result_bool=True)
                    return True

    else:
        status_line(message="A state file exists", result_msg=state_file_path, result_bool=False)

    return False

def format_as_vars_file_param(pathname):
    """Accepts a pathname and returns a string formatted as a valid terraform var-file include argument"""
    return "-var-file={pn}".format(pn=pathname)

def calculate_included_vars_file(config, fail_if_not_found=True):
    """Returns a tfvar file to use based on account, environment, etc"""

    # Standard tfvars files
    env_specific_tfvars_pathname = "{vfdir}/{ap}/{rc}-{on}.tfvars".format(
        vfdir=config['terraform']['vars_dir'],
        ap=config['env_vars']['aws_profile'],
        rc=config['env_vars']['res_class'],
        on=config['env_vars']['aws_profile'] if config['env_vars']['res_class'] in ['account'] else config['env_vars']['deploy_env']
    )

    if check_exists('file', env_specific_tfvars_pathname, False):
        return env_specific_tfvars_pathname
    else:
        env_default_tfvars_pathname = "{vfdir}/{ap}/{rc}.tfvars".format(
            vfdir=config['terraform']['vars_dir'],
            ap=config['env_vars']['aws_profile'],
            rc=config['env_vars']['res_class']
        )

        if check_exists('file', env_default_tfvars_pathname, True):
            return env_default_tfvars_pathname


def run_devised_command(config, force_init=False):
    """Run terraform with all the params"""
    # Change to env_class directory before running terraform

    executable         = config['terraform']['executable']
    backend_varsfile   = config['terraform']['backend_varsfile']
    res_class          = config['env_vars']['res_class']
    tfvars_file_params = calculate_included_vars_file(config)

    # Remember which directory we are in
    status_line(message="FORCE INIT", result_msg=force_init, result_bool=force_init)
    status_line(message="Record current directory", result_msg=os.getcwd(), result_bool=True)

    if config['env_vars'].has_key('deploy_env'):
        deploy_env_include = "-var deploy_env={e}".format(e=config['env_vars']['deploy_env'])
    else:
        deploy_env_include = ""

    if sys.argv[1] in ['init'] or force_init:
        devised_cmd = "{cmd} {args} {ifp} -var aws_profile={awsp} -var aws_region={rg} -var res_class={rc} {e} -var 'key_name={k}' -var 'public_key_path={pkp}' {vfs} -backend-config={bc} -get-plugins=true 1>&2".format(
            cmd  = executable,
            args = 'init',
            ifp  = config['terraform']['init_fixed_params'],
            rg   = config['env_vars']['aws_region'],
            awsp = config['env_vars']['aws_profile'],
            rc   = res_class,
            e    = deploy_env_include,
            k    = config['terraform']['public_key_name'],
            pkp  = config['terraform']['public_key_path'],
            p    = config['terraform']['parallelism'],
            vfs  = ' '.join([format_as_vars_file_param(tfvars_file_params)]),
            bc   = backend_varsfile)

    elif sys.argv[1] in ['plan', 'apply', 'destroy', 'refresh']:
        if sys.argv[1] == 'refresh':
            force_refresh = ''
        elif config['terraform']['force_refresh']:
            force_refresh = '-refresh=true'
        else:
            force_refresh = ''

        devised_cmd       = "{cmd} {args} {force_refresh} {auto_approve} -var aws_region={rg} -var aws_profile={awsp} -var res_class={rc} {e} -var 'key_name={k}' -var 'public_key_path={pkp}' -parallelism={p} {vfs} 1>&2".format(
            cmd           = executable,
            args          = ' '.join(sys.argv[1:]),
            force_refresh = force_refresh,
            auto_approve  = '-auto-approve=true' if sys.argv[1] == 'apply' else '',
            rg            = config['env_vars']['aws_region'],
            awsp          = config['env_vars']['aws_profile'],
            rc            = res_class,
            e             = deploy_env_include,
            k             = config['terraform']['public_key_name'],
            pkp           = config['terraform']['public_key_path'],
            p             = config['terraform']['parallelism'],
            vfs           = ' '.join([format_as_vars_file_param(tfvars_file_params)]))
    else:
        devised_cmd = "{cmd} {args}".format(
            cmd     = executable,
            args    = ' '.join(sys.argv[1:]))

    if sys.argv[1] in ['init'] or force_init:
        modules_get_cmd = "{cmd} get -update=true 1>&2".format(cmd  = executable)

        # Get any Terraform modules used
        print >> sys.stderr, "\nRunning the following command in `{pwd}` to get modules... \n\n{t.yellow}{t.bold}{cmd}{t.normal}\n".format(t=term, pwd=os.getcwd(), cmd=modules_get_cmd)
        # terminate if `get` fails
        ret_code = os.system(modules_get_cmd)
        if ret_code > 0:
            status_line(message="Get Terraform modules failed", result_msg=ret_code, result_bool=False)
            sys.exit(120)

    # Run the requested Terraform command
    print >> sys.stderr, "Running the following requested command in `{pwd}`... \n\n{t.yellow}{t.bold}{cmd}{t.normal}\n".format(t=term, pwd=os.getcwd(), cmd=devised_cmd)
    os.system(devised_cmd)
    print >> sys.stderr, ""

def create_state_bucket(config):
    """Check/create state bucket in s3"""
    s3 = boto3.resource('s3', config['env_vars']['aws_region'], config=Config(s3={'addressing_style': 'auto'}))

    bucket_name = config['env_vars']['aws_profile'] + '-' + config['terraform_template']['bucket_suffix']
    try:
        s3.create_bucket(Bucket=bucket_name, CreateBucketConfiguration={
        'LocationConstraint': config['env_vars']['aws_region']
        })
        status_line(message="Created s3 bucket", result_msg="{b} in region {r}".format(b=bucket_name, r=config['env_vars']['aws_region']), result_bool=True)
    except ClientError as e:
        if e.response['Error']['Code'] == 'BucketAlreadyOwnedByYou':
            status_line(message="Found s3 bucket", result_msg="{b} in region {r}".format(b=bucket_name, r=config['env_vars']['aws_region']), result_bool=True)
        else:
            e.response['Error']['Code']
            status_line(message="Create s3 bucket", result_msg="{b} in region {r}".format(b=bucket_name, r=config['env_vars']['aws_region']), result_bool=False)
            sys.exit(30)

def create_lock_table(config):
    """Check/Create lock table in DynamoDB"""
    client = boto3.client('dynamodb')
    response = client.list_tables()
    table_name = config['terraform_template']['table_name']

    if table_name in response['TableNames']:
        status_line(message="Found DynamoDB locks table", result_msg=table_name, result_bool=True)
    else:
        try:
            response = client.create_table(
                AttributeDefinitions=[
                    {
                        'AttributeName': 'LockID',
                        'AttributeType': 'S',
                    },
                ],
                TableName=table_name,
                KeySchema=[
                    {
                        'AttributeName': 'LockID',
                        'KeyType': 'HASH',
                    },
                ],
                ProvisionedThroughput={
                    'ReadCapacityUnits': 1,
                    'WriteCapacityUnits': 1,
                }
            )
            waiter = client.get_waiter('table_exists')
            waiter.wait(
                TableName=table_name
            )
        except ClientError as e:
            status_line(message="Create DynamoDB locks table", result_msg=table_name, result_bool=False)
            sys.exit(40)

        status_line(message="Create DynamoDB locks table", result_msg=table_name, result_bool=True)


class ValidationData:
    """Validation Data Object"""
    def __init__(self, config, yaml_filename):
        """Constructor"""
        self.yaml_filename = yaml_filename
        self.config = config
        self.data = self.load_validation_data_from_yaml(yaml_filename)

    def load_validation_data_from_yaml(self, yaml_filename):
        """Check validation data file exists and load"""
        if check_exists('file', self.yaml_filename, False):
            return load(open(self.yaml_filename, 'r'))
        else:
            empty_hash = {}
            for h in self.config['terraform']['validation_hashes']:
                empty_hash[h] = []
            return empty_hash

    def save_validation_data_to_yaml(self, vd, yaml_filename):
        """Save validation data to yaml file"""
        with open(yaml_filename, 'w') as yaml_file:
            dump(vd, yaml_file, default_flow_style=False)

class ConfigData:
    """Configuration Data Object"""
    def __init__(self, yaml_filename, caller = 'anonymous'):
        """Constructor"""
        self.caller = caller
        self.yaml_filename = yaml_filename
        self.data = self.load_config_data_from_yaml()
        if self.caller == 'run_terraform':
            self.merge_env_vars()
            self.add_calcs()

    def load_config_data_from_yaml(self):
        """Check config data file exists and load"""
        if check_exists('file', self.yaml_filename):
            return load(open(self.yaml_filename, 'r'))

    def merge_env_vars(self):
        """Merge selected env_vars into config data"""
        self.data['env_vars']                = {}
        self.data['env_vars']['aws_profile'] = os.environ['AWS_PROFILE'] if os.environ.has_key('AWS_PROFILE') else ''
        self.data['env_vars']['res_class']   = os.environ['RES_CLASS'] if os.environ.has_key('RES_CLASS') else ''

        if os.environ.has_key('AWS_REGION'):
            self.data['env_vars']['aws_region'] = os.environ['AWS_REGION']
        elif os.environ.has_key('AWS_DEFAULT_REGION'):
            self.data['env_vars']['aws_region'] = os.environ['AWS_DEFAULT_REGION']
        else:
            status_line(message="Env-var AWS_REGION or AWS_DEFAULT_REGION must be set", result_bool=False)

        self.data['env_vars']['deploy_env'] = os.environ['DEPLOY_ENV'] if os.environ.has_key('DEPLOY_ENV') else ''

        if os.environ.has_key('TF_KEEP_STATE'):
            if os.environ['TF_KEEP_STATE'].lower() == 'true':
                self.data['env_vars']['tf_keep_state'] = True
            else:
                self.data['env_vars']['tf_keep_state'] = False
        else:
            self.data['env_vars']['tf_keep_state'] = False

    def add_calcs(self):
        """Add a calculated vars"""
        if self.data['env_vars']['res_class'] in ['account']:
            self.data['terraform']['backend_varsfile'] = self.data['terraform']['backend_dir'] + '/' + self.data['env_vars']['res_class'] + '-' + self.data['env_vars']['aws_profile'] + '-' + self.data['terraform']['backend_varsfile_suffix']
        else:
            self.data['terraform']['backend_varsfile'] = self.data['terraform']['backend_dir'] + '/' + self.data['env_vars']['res_class'] + '-' + self.data['env_vars']['aws_profile'] + '-' + self.data['env_vars']['deploy_env'] + '-' + self.data['terraform']['backend_varsfile_suffix']

def status_line(message = u"", result_msg = u"", result_bool = True, filler = u" ", result_good = u"\U0001F60E", result_bad = u"\U0001F62C"):
    """Prints a fixed length formatted line of output in color with status to stderr"""
    try:
        width = os.popen('stty size 2>/dev/null', 'r').read().split()[1]
    except:
        width = 80

    _msg_max_len  = int((float(width)/100)*50)-6
    _rslt_max_len = int((float(width)/100)*50)
    _message      = unicode(message).split("\n")[0]
    _result_msg   = unicode(result_msg).split("\n")[0]

    print >> sys.stderr, u"{mcolor}{m:<{mm}}{normal} {rcolor}{r:<{rm}}{normal} {scolor}{s:<2.2}{normal}".format(
        mcolor = term.cyan,
        scolor = term.green if result_bool else term.red,
        rcolor = term.yellow,
        normal = term.normal,
        m      = _message+filler*(_msg_max_len-len(_message)) if len(_message)<_msg_max_len else _message[:_msg_max_len-1] + u"\u2026",
        r      = _result_msg+filler*(_rslt_max_len-len(_result_msg)) if len(_result_msg)<_rslt_max_len else _result_msg[:_rslt_max_len-1] + u"\u2026",
        s      = result_good if result_bool else result_bad,
        mm     = _msg_max_len,
        rm     = _rslt_max_len,
    ).encode('utf-8')

def import_tfvars(config, tfvars_pathname):
    """Import the tfvars"""
    config['tfvars_pathname'] = tfvars_pathname
    if check_exists('file', tfvars_pathname, False):
        try:
            with open(tfvars_pathname, 'r') as fp:
                config['tfvars'] = hcl.load(fp)
        except:
            config['tfvars'] = {}
    else:
        config['tfvars'] = {}

def process_pre_terraform_templates(config):
    for hclfile in os.listdir('.'):
        if hclfile.endswith(config['pre_terraform']['source_file_suffix']):
            dest_filename =  ''.join(
                [
                    config['pre_terraform']['dest_file_prefix'],
                    hclfile.replace(config['pre_terraform']['source_file_suffix'],
                    config['pre_terraform']['dest_file_suffix'])
                ]
            )
            tf_template = OurTemplate(
                hclfile,
                os.path.join(config['pre_terraform']['dest_directory'], dest_filename),
                config)
            tf_template.render_to_file()
            status_line(message="Pre-terraform: processed file", result_msg=dest_filename, result_bool=True)

# Main: The program starts here
if __name__ == '__main__':
    config = ConfigData(config_data_filename, caller='run_terraform')
    check_env_vars(ValidationData(config, validatation_data_filename).data)
    check_we_have_params()
    enforce_terraform_version(config.data)
    wdir = os.getcwd()
    selected_res_class_directory = os.path.join(wdir, config.data['terraform']['res_class_base_directory'], config.data['env_vars']['res_class'])
    os.chdir(ensure_dir(selected_res_class_directory))
    import_tfvars(config.data, calculate_included_vars_file(config.data, False))

    if config.data['pre_terraform']['clean_before_use']:
        status_line(message="Pre-terraform: remove prevously generated files", result_msg='True', result_bool=True)

        for f in glob.glob(''.join([config.data['pre_terraform']['dest_file_prefix'], '*', config.data['pre_terraform']['dest_file_suffix']])):
            os.remove(f)
    if config.data['pre_terraform']['enable']:
        status_line(message="Pre-terraform: templating enabled", result_msg='True', result_bool=True)
        pre_terraform_template_dir = os.path.join(selected_res_class_directory, config.data['pre_terraform']['source_directory'])
        if check_exists('dir', pre_terraform_template_dir, fail_if_missing=False):
            os.chdir(os.path.join(selected_res_class_directory, config.data['pre_terraform']['source_directory']))
            process_pre_terraform_templates(config.data)
    else:
        status_line(message="Pre-terraform: templating enabled", result_msg='False', result_bool=True)

    if os.getcwd() != selected_res_class_directory:
        os.chdir(selected_res_class_directory)

    if not check_current_backend_correct(config.data):
        status_line(message="check_current_backend_correct returned", result_bool=False)
        write_terraform_backends(config.data)
        create_state_bucket(config.data)
        create_lock_table(config.data)
        run_devised_command(config.data, force_init=True)

    run_devised_command(config.data)
    os.chdir(wdir)
