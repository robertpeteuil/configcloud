#!/bin/bash

#   BASH Profile
#
#     CLOUD Specific - LINUX ONLY VERSION
#
#     Robert Peteuil (c) 2018
#

export profilename=".bash_profile"   # shellcheck disable=SC2034
export profilenum="2.0.0"            # shellcheck disable=SC2034
export profiledate="2018-01-21"      # shellcheck disable=SC2034

if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
