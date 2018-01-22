#!/bin/bash

#   BASH Profile
#
#     This script is a component of ConfigCloud
#       https://github.com/robertpeteuil/configcloud
#
#     Robert Peteuil (c) 2018
#

profilename=".bash_profile"   # shellcheck disable=SC2034
profilenum="2.0.1"            # shellcheck disable=SC2034
profiledate="2018-01-21"      # shellcheck disable=SC2034

if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
