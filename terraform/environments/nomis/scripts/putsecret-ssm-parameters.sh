#!/bin/bash
# Upload parameters to secretsmanager
# For example, first call describe-ssm-parameters.sh and get-ssm-parameters.sh
# to get existing parameters.  Create new parameters as required and add into
# the ssm-parameters/profile.txt file.  Then use this script to upload them to secretsmanager

MODE=safe # force
PROFILE=$1
PREFIX=$2

if [[ -z $PROFILE ]]; then
  echo "Usage: $0 <profile> [<prefix>]" >&2
  exit 1
fi

if [[ ! -e ssm-parameters/$PROFILE.txt ]]; then
  echo "Could not find ssm-parameters/$PROFILE.txt" >&2
  exit 1
fi

params=$(cat ssm-parameters/$PROFILE.txt | grep -v '^$' | grep "^$PREFIX")

if [[ $MODE == "force" ]]; then
  for param in $params; do
    if [[ ! -e ssm-parameters/$PROFILE/$param ]]; then
      echo "skipping $param as file does not exist" >&2
    else
      value=$(cat ssm-parameters/$PROFILE/$param)
      echo aws secretsmanager put-secret-value --secret-id $param --secret-string "$value" --profile $PROFILE >&2
    fi
  done
  echo Press RETURN to put secrets, CTRL-C to cancel
  read

  for param in $params; do
    if [[ ! -e ssm-parameters/$PROFILE/$param ]]; then
      echo "skipping $param as file does not exist" >&2
    else
      value=$(cat ssm-parameters/$PROFILE/$param)
      echo aws secretsmanager put-secret-value --secret-id $param --secret-string "$value" --profile $PROFILE >&2
      aws secretsmanager put-secret-value --secret-id $param --secret-string "$value" --profile $PROFILE
    fi
  done
elif [[ $MODE == "safe" ]]; then
  for param in $params; do
    if [[ ! -e ssm-parameters/$PROFILE/$param ]]; then
      echo "skipping $param as file does not exist" >&2
    else
      echo aws secretsmanager get-secret-value --secret-id $param --query SecretString --output text --profile $PROFILE >&2
      oldvalue=$(aws secretsmanager get-secret-value --secret-id $param --query SecretString --output text --profile $PROFILE)
      newvalue=$(cat ssm-parameters/$PROFILE/$param)
      if [[ "$oldvalue" == "$newvalue" ]]; then
        echo "No change"
      else
        echo "Change from $oldvalue to $newvalue"
        echo aws secretsmanager put-secret-value --secret-id $param --secret-string "$newvalue" --profile $PROFILE >&2
        echo Press RETURN to put secrets, CTRL-C to cancel
        read
        aws secretsmanager put-secret-value --secret-id $param --secret-string "$newvalue" --profile $PROFILE
      fi
    fi
  done
fi
