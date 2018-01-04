#!/bin/bash
#
## Returns a secret
#
# The order of presidence is:
#   - envvar
#   - pass
#   - random password
#
# required vars
password_length="${ trimspace(password_length) }"
secret_envar="${ trimspace(secret_envar) }"
pass_location="${ trimspace(pass_location) }"
credstash_location="${ trimspace(credstash_location) }"
aws_region="${ trimspace(aws_region) }"
aws_profile="${ trimspace(aws_profile) }"
deploy_env="${ trimspace(deploy_env) }"
secret_type="${ trimspace(secret_type) }"
b64encode="${ b64encode }"
#
# start
if [[ $${#secret_envar} -gt 0 ]]; then
  secret=$${secret_envar}
else
  if [[ $${#pass_location} -gt 0 ]]; then
    # catch these errors (#2) and retry: `gpg: decryption failed: No secret key`
    return_code=2
    retries=10
    while [[ $${return_code} -eq 2 ]] && [[ $${retries} -gt 0 ]]; do
      secret=$(pass $${pass_location})
      return_code=$?
      if [[ $${return_code} -ne 0 ]]; then
        sleep 1
      fi
      ((retries--))
    done
  else
    return_code=9999
  fi
  if [[ $${return_code} -ne 0 ]]; then
    if [[ $${secret_type} == "private_key" ]]; then
      # if we need a private key then generate an rsa key
      secret=$(openssl genrsa $${password_length})
    else
      # for everything else we just generate a random hex string
      secret=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | fold -w $${1:-$${password_length}} | head -n 1)
    fi
  fi
fi

# base64 encode if requested
[[ $${b64encode} == 'true' ]] && secret=$(echo -n $${secret}} | base64)

credstash -r $${aws_region} -p $${aws_profile} -t $${deploy_env}-secrets put --autoversion $${credstash_location} "$${secret}"
