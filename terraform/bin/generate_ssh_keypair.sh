#!/bin/bash
set -e

die() {
  echo "$1 must be set"
  exit 1
}

[[ -z "${AWS_PROFILE}" ]] && die "AWS_PROFILE"
[[ -z "${AWS_REGION}" && -z "${AWS_DEFAULT_REGION}" ]] && die "AWS_REGION or AWS_DEFAULT_REGION"
[[ -z "${DEPLOY_ENV}" ]] && die "DEPLOY_ENV"

work_dir=$(/usr/bin/env mktemp -d)
purpose=$1
key_name="${DEPLOY_ENV}_id_rsa_${purpose}"
region=${AWS_REGION:-$AWS_DEFAULT_REGION}
passphrase=""

echo "Using temp key dir: ${work_dir}"
ssh-keygen -trsa -b2048 -C${purpose}@${DEPLOY_ENV}.${AWS_PROFILE} -N "${passphrase}" -f${work_dir}/${key_name}

sleep 10
credstash -r ${region} -p ${AWS_PROFILE} -t ${DEPLOY_ENV}-secrets put ${purpose}.ssh_key.private "$(base64 ${work_dir}/${key_name})" -a
credstash -r ${region} -p ${AWS_PROFILE} -t ${DEPLOY_ENV}-secrets put ${purpose}.ssh_key.public "$(base64 ${work_dir}/${key_name}.pub)" -a

# keep a copy for now
cp -f ${work_dir}/* ~/.ssh/

rm -rf ${work_dir}
