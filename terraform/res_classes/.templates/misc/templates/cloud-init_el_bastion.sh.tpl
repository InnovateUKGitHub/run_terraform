#!/bin/bash -x

cat <<EOF >/etc/motd.tail

Welcome to the bastion host for:

  AWS_REGION: ${aws_region}
  AWS_PROFILE: ${aws_profile}
  RES_CLASS: ${res_class}
  DEPLOY_ENV: ${deploy_env}

EOF
