#!/usr/bin/env bash

#   CONFIGCLOUD INSTALLER 
#
#     This script is a component of ConfigCloud
#       https://github.com/robertpeteuil/configcloud
#
#     This installer links or copies included files/dirs into the current user's home directory.
#     It should be executed directly from the repo directory: ./install.sh -h (displays help)
#
#     Robert Peteuil (c) 2018
#

scriptname="install.sh"
scriptbuildnum="2.0.1"
scriptbuilddate="2018-01-21"

################################################################
### VARS INITS
os=$(uname | tr '[:upper:]' '[:lower:]')  # get OS name in all lowercase
settingsfilename="install-set"
logfilename="LOG-install.txt"

# INITIALIZE MODE FLAGS
customconfig=false
forcemode=false
testmode=false
detailsmode=false
verbosemode=false
quietmode=false
test_overwrite_flag=false
overwrite_flag=false
copy_recursion=false

# SET STRING FLAGS
temp_src=""
remove_item_type=""
report_indent="    " # set indent as (tab) may not be supported

# COUNTERS (set to be seen as integers in some shells)
test_copies=0
test_links=0
test_removing=0
test_mkdir=0
test_errors=0
new_copies=0
new_links=0
new_removals=0
new_dirs=0
error_copies=0
error_links=0
error_removals=0
error_mkdirs=0
warning_skipped=0
warning_removals=0

# Reporting Strings
test_copies_names=""
test_links_names=""
test_removing_names=""
test_mkdir_names=""
test_errors_names=""
new_copies_names=""
new_links_names=""
new_removals_names=""
new_dirs_names=""
error_copies_names=""
error_links_names=""
error_removals_names=""
error_mkdirs_names=""
warning_skipped_names=""
warning_removals_names=""

############################################################
###     PRE-EXECUTION

# TURN ON COLOR IF POSSIBLE, SET THEME
if test -t 1; then            # check if stdout is a terminal
  ncolors=$(tput colors)    # see if it supports colors
  if test -n "$ncolors" && test "$ncolors" -ge 8; then
  # SET COLORS
    bold="$(tput bold)"
    underline="$(tput smul)"
    standout="$(tput smso)"
    normal="$(tput sgr0)"
    black="$(tput setaf 0)"
    red="$(tput setaf 1)"
    green="$(tput setaf 2)"
    yellow="$(tput setaf 3)"
    blue="$(tput setaf 4)"
    magenta="$(tput setaf 5)"
    cyan="$(tput setaf 6)"
    white="$(tput setaf 7)"
  # SET COLOR THEME - vars used by echo statements
    CLRnormal=${bold}${white}
    CLRheading=${bold}${green}
    CLRheading2=${bold}${blue}
    CLRtitle=${bold}${cyan}
    CLRtitle2=${bold}${magenta}
    CLRsuccess=${bold}${green}
    CLRwarning=${bold}${yellow}
    CLRerror=${bold}${red}
  fi
fi

################################################################
### FUNCTIONS

processExit () {
  local var="$*"
  if [[ -n "$EXITMESSAGE" ]]; then
    echo -e "$EXITMESSAGE" >&2
  fi
  if [[ -n "$var" ]]; then
    echo -e "$var" >&2
    [[ "$EXITSTATUS" == 0 ]] && EXITSTATUS=1
  fi
  exit $EXITSTATUS
}

processAbort () {
  local var=$*
  [[ -n $var ]] && EXITMESSAGE="${CLRerror}ABORT${CLRnormal} - ${CLRtitle}${var}${CLRnormal}"
  EXITSTATUS=2
  processExit ""
}

remove_formatting () {
local var="$*"
  if [[ -n "$var" ]]; then
    var=${var//${CLRnormal}/}
    var=${var//${CLRheading}/}
    var=${var//${CLRheading2}/}
    var=${var//${CLRtitle}/}
    var=${var//${CLRtitle2}/}
    var=${var//${CLRsuccess}/}
    var=${var//${CLRwarning}/}
    var=${var//${CLRerror}/}
    echo "$var"
  fi
}

display_ver() {
  printed_title="${CLRheading}${scriptname}${CLRnormal}  ver ${CLRtitle}${scriptbuildnum} ${CLRnormal}- ${CLRtitle}${scriptbuilddate}${CLRnormal}"
  echo -e "$printed_title"
}

display_help_text () {

  display_ver
  echo
  echo -e "Copies/links files and directories from the current dir to the user's home dir"
  echo -e
  echo -e "USAGE: install.sh [OPTIONS] [-c CONFIG-FILE] [SOURCE-DIR] [DEST-DIR]"
  echo -e "    SOURCE-DIR defaults to the current directory"
  echo -e "    DEST-DIR defaults to the current user's home directory"
  echo -e
  echo -e "OPTIONS (default to false):"
  echo -e "  -f (--force)    : force mode - overwrite existing items"
  echo -e "  -d (--details)  : details mode - display details results in categories"
  echo -e "  -q (--quiet)    : quiet mode - don't display any output"
  echo -e "  -t (--test)     : test mode - display changes but don't make any"
  echo -e "  -v (--verbose)  : verbose mode - display exact commands to be performed"
  echo -e
  echo -e "  -h (--help)     : display help info and exit"
  echo -e "  -V (--version)  : display version info and exit"
  echo -e
  echo -e "  -c (--config)   : specify a configuration file"
  echo -e "                      (default configuration file is 'conf-settings')"
  echo -e "                      Example config file contents:"
  echo -e "                        # Settings (can use globs)"
  echo -e "                        # ignore these files (modifies include)"
  echo -e "                        ignore='Icon* *.md *.sh *.txt scripts'"
  echo -e "                        # create dir (not contents), then sym-link children (contents)"
  echo -e "                        link_children='config'"
  echo -e "                        # copy these files"
  echo -e "                        copitem_message=''"
  echo -e "                        # sym-link these files"
  echo -e "                        link='*'"
  echo -e
  echo -e "  SOURCE-DIR      : directory containing dotfiles to be copied and/or linked"
  echo -e "                    (default is current directory)"
  echo -e "                      files should NOT have leading '.'"
  echo -e "                      example: '.bashrc' should be named 'bashrc' in SOURCE-DIR"
  echo -e
  echo -e "  DEST-DIR        : target directory where copies and links will be placed"
  echo -e "                    (default is '~')"
}

print_output() {
  if [ $verbosemode = true ]; then
    echo "$@"
  fi
  return 0
}

list_contains() {
  for word in $1; do
    [ "$word" = "$2" ] && return 0
  done
  return 1
}

remove_dupes() {
  unset new_list
  for i in $1; do
    list_contains "$2" "$i" || new_list="$new_list $i"
  done
  echo "$new_list"
}

remove_item() {
  if [ "$testmode" = true ]; then
    print_output "rm $1"
    test_removing=$((test_removing=test_removing+1))
    test_removing_names="$test_removing_names $1"
    test_overwrite_flag=true
    return 0
  fi
  if [ "$forcemode" = true ]; then
    if [ -d "$1" ]; then
      remove_command="rmdir $1"
      remove_item_type="dir"
    else
      remove_command="rm $1"
      remove_item_type="non-dir"
    fi
    if $($remove_command 2> /dev/null); then
      print_output "REMOVAL SUCCESS: $1"
      new_removals=$((new_removals=new_removals+1))
      new_removals_names="$new_removals_names $1"
      overwrite_flag=true
      return 0
    else
      if [ "$remove_item_type" = "dir" ]; then
        print_output "REMOVAL WARNING: $1"
        warning_removals=$((warning_removals=warning_removals+1))
        warning_removals_names="$warning_removals_names $1"
        remove_item_type=""
        return 1
      fi
      print_output "REMOVAL FAILED: $1"
      error_removals=$((error_removals=error_removals+1))
      error_removals_names="$error_removals_names $1"
      return 1
    fi
  else   # FORCE MODE not enabled
    print_output "NOT OVERWRITTEN: $1"
    warning_skipped_names="$warning_skipped_names $1"
    warning_skipped=$((warning_skipped=warning_skipped+1))
    return 1
  fi
}

link_item() {
  if [ "$testmode" = true ]; then
    if [ "$prefail" = true ]; then
      print_output "ERROR LINKING: $2"
      test_errors=$((test_errors=test_errors+1))
      test_errors_names="$test_errors_names Error_Linking:$2"
      return 0
    fi
    print_output "ln -s $1 $2"
    if [ "$test_overwrite_flag" = false ]; then
      test_links=$((test_links=test_links+1))
      test_links_names="$test_links_names $2"
    fi
    test_overwrite_flag=false
    return 0
  fi
  if $(ln -s "$1" "$2" 2> /dev/null); then
    print_output "LINK SUCCESS: $2"
    if [ "$overwrite_flag" = false ]; then
      new_links=$((new_links=new_links+1))
      new_links_names="$new_links_names $2"
    fi
    overwrite_flag=false
    return 0
  else
    print_output "ERROR LINKING: $2"
    error_links=$((error_links=error_links+1))
    error_links_names="$error_links_names $2"
    return 1
  fi
}

copy_item() {
  if [ "$testmode" = true ]; then
    if [ "$prefail" = true ]; then
      print_output "ERROR COPYING: $2"
      test_errors=$((test_errors=test_errors+1))
      test_errors_names="$test_errors_names Error_Copying:$2"
      return 0
    fi
    print_output "cp $1 $2"
    if [ "$test_overwrite_flag" = false ]; then
      test_copies=$((test_copies=test_copies+1))
      test_copies_names="$test_copies_names $2"
    fi
    test_overwrite_flag=false
    return 0
  fi
  if [ "$copy_recursion" = true ]; then
    copy_command="cp -R $1 $2"
  else
    copy_command="cp $1 $2"
  fi
  if $($copy_command 2> /dev/null); then
    print_output "COPY SUCCESS: $2"
    if [ "$overwrite_flag" = false ]; then
      new_copies=$((new_copies=new_copies+1))
      new_copies_names="$new_copies_names $2"
    fi
    overwrite_flag=false
    return 0
  else
    print_output "ERROR COPYING: $2"
    error_copies=$((error_copies=error_copies+1))
    error_copies_names="$error_copies_names $2"
    return 1
  fi
}

make_dir() {
  if [ "$testmode" = true ]; then
    print_output "mkdir -p $1"
    if [ "$test_overwrite_flag" = false ]; then
      test_mkdir=$((test_mkdir=test_mkdir+1))
      test_mkdir_names="$test_mkdir_names $1"
    fi
    test_overwrite_flag=false
    return 0
  fi
  if $(mkdir -p "$1" 2> /dev/null); then
    print_output "MKDIR SUCCESS: $1"
    if [ "$overwrite_flag" = false ]; then
      new_dirs=$((new_dirs=new_dirs+1))
      new_dirs_names="$new_dirs_names $1"
    fi
    overwrite_flag=false
    return 0
  else
    print_output "ERROR MKDIR: $1"
    error_mkdirs=$((error_mkdirs=error_mkdirs+1))
    error_mkdirs_names="$error_mkdirs_names $1"
    return 1
  fi
}

make_links() {
  for s in $1; do
    target="$dest_dir/.$s"
    src="$source_dir/$s"
    if [ -e "$target" ]; then
      remove_item "$target" && link_item "$src" "$target"
    else
      link_item "$src" "$target"
    fi
  done
}

make_copies () {
  if [ -e "$dest_dir/.$1" ]; then
    remove_item "$dest_dir/.$1" && copy_item "${temp_src}${1}" "$dest_dir/.$1"
  else
    copy_item "${temp_src}${1}" "$dest_dir/.$1"
  fi
}

report_grammar () {
  if [ "$1" = "1" ]; then
    correctnoun="item"
    dirnoun="directory"
    lnnoun="link"
    correctverb2="exists"
    warntext="WARNING:"
    errortext="ERROR:"
    waswere="was"
  else
    correctnoun="items"
    dirnoun="directories"
    lnnoun="links"
    correctverb2="exist"
    warntext="WARNINGS:"
    errortext="ERRORS:"
    waswere="were"
  fi
}

report_print () {
  echo -e "$report_indent $item_message"
  for temp_name in $item_names; do
    [ "$detailsmode" = true ] && echo -e "${report_indent} ${report_indent} ${CLRtitle}${temp_name}${CLRnormal}"
  done
  [ "$detailsmode" = true ] && echo
  return 0
}

report_data_test () {
  case "$1" in
    test_copies)
      item_num=$test_copies; report_grammar $item_num; item_names=$test_copies_names
      log_message="$item_num $correctnoun will be copied"
      item_message="${CLRtitle2}$item_num $correctnoun${CLRnormal} ${CLRsuccess}will be copied${CLRnormal}" ;;
    test_links)
      item_num=$test_links; report_grammar $item_num; item_names=$test_links_names
      log_message="$item_num $lnnoun will be created"
      item_message="${CLRtitle2}$item_num $lnnoun${CLRnormal} ${CLRsuccess}will be created${CLRnormal}" ;;
    test_mkdir)
      item_num=$test_mkdir; report_grammar $item_num; item_names=$test_mkdir_names
      log_message="$item_num $dirnoun will be created"
      item_message="${CLRtitle2}$item_num $dirnoun${CLRnormal} ${CLRsuccess}will be created${CLRnormal}" ;;
    test_removing)
      item_num=$test_removing; report_grammar $item_num; item_names=$test_removing_names
      log_message="$warntext  $item_num $correctnoun already $correctverb2 and require '-f' or '--force' to overwrite"
      item_message="${CLRwarning}$warntext  ${CLRtitle2}$item_num $correctnoun${CLRnormal} ${CLRwarning}already $correctverb2 and require '-f' or '--force' to overwrite${CLRnormal}" ;;
    test_errors)
      item_num=$test_errors; report_grammar $item_num; item_names=$test_errors_names
      log_message="$errortext  $item_num $correctnoun will fail - see Error Details"
      item_message="${CLRerror}$errortext  ${CLRtitle2}$item_num $correctnoun${CLRnormal} ${CLRerror}will fail - see Error Details${CLRnormal}" ;;
    esac
    report_print
}

report_data () {
  case "$1" in
    error_copies)
      item_num=$error_copies; report_grammar $item_num; item_names=$error_copies_names
      log_message="$item_num $correctnoun encountered errors while copying"
      item_message="${CLRtitle2}$item_num $correctnoun ${CLRerror}encountered errors while copying${CLRnormal}" ;;
    error_links)
      item_num=$error_links; report_grammar $item_num; item_names=$error_links_names
      log_message="$item_num $correctnoun encountered errors while linking"
      item_message="${CLRtitle2}$item_num $correctnoun ${CLRerror}encountered errors while linking${CLRnormal}" ;;
    error_mkdirs)
      item_num=$error_mkdirs; report_grammar $item_num; item_names=$error_mkdirs_names
      log_message="$item_num $correctnoun encountered errors during mkdir"
      item_message="${CLRtitle2}$item_num $correctnoun ${CLRerror}encountered errors during mkdir${CLRnormal}" ;;
    error_removals)
      item_num=$error_removals; report_grammar $item_num; item_names=$error_removals_names
      log_message="$item_num $correctnoun encountered errors during removal"
      item_message="${CLRtitle2}$item_num $correctnoun ${CLRerror}encountered errors during removal${CLRnormal}" ;;
    warning_skipped)
      item_num=$warning_skipped; report_grammar $item_num; item_names=$warning_skipped_names
      log_message="$item_num $correctnoun already $correctverb2 and $waswere NOT overwritten (use '-f' or '--force' to overwrite)"
      item_message="${CLRtitle2}$item_num $correctnoun ${CLRwarning}already $correctverb2 and $waswere NOT overwritten (use '-f' or '--force' to overwrite)${CLRnormal}" ;;
    warning_removals)
      item_num=$warning_removals; report_grammar $item_num; item_names=$warning_removals_names
      log_message="$item_num $dirnoun $correctverb2 and $waswere NOT deleted - child items were still processed"
      item_message="${CLRtitle2}$item_num $dirnoun ${CLRwarning}$correctverb2 and $waswere NOT deleted - child items were still processed${CLRnormal}" ;;
    new_copies)
      item_num=$new_copies; report_grammar $item_num; item_names=$new_copies_names
      log_message="$item_num $correctnoun copied"
      item_message="${CLRtitle2}$item_num $correctnoun ${CLRsuccess}copied${CLRnormal}" ;;
    new_links)
      item_num=$new_links; report_grammar $item_num; item_names=$new_links_names
      log_message="$item_num $lnnoun created"
      item_message="${CLRtitle2}$item_num $lnnoun ${CLRsuccess}created${CLRnormal}" ;;
    new_dirs)
      item_num=$new_dirs; report_grammar $item_num; item_names=$new_dirs_names
      log_message="$item_num $dirnoun created"
      item_message="${CLRtitle2}$item_num $dirnoun ${CLRsuccess}created${CLRnormal}" ;;
    new_removals)
      item_num=$new_removals; report_grammar $item_num; item_names=$new_removals_names
      log_message="$item_num $correctnoun overwritten"
      item_message="${CLRtitle2}$item_num $correctnoun ${CLRsuccess}overwritten${CLRnormal}" ;;
  esac
  report_print
}


################################################################
### EXECUTION - Setup

# Parse COMMAND-TAIL Arguments
for arg in "$@"; do
  case "$arg" in
    -f|--force)         forcemode=true; shift ;;
    -d|--details)       detailsmode=true; shift ;;
    -t|--testing)       testmode=true; forcemode=false; shift ;;
    -h|--help)          display_help_text; processExit ;;
    -v|--verbose)       verbosemode=true; shift ;;
    -q|--quiet)         quietmode=true; verbosemode=false; shift ;;
    -c|--config-file)   shift; . "$1"; shift; customconfig=true ;;
    -V|--version)       display_ver; processExit ;;
  esac
done

# Set default dirs (must occur after command-tail parsing)
source_dir="${1:-$(pwd)}"
dest_dir="${2:-$HOME}"

# Read Settings File (must occur after command-tail parsing)
settingsfile="${source_dir}/${settingsfilename}"  # General Settings File
settingsfileOS="${settingsfile}-${os}"            # Specific OS Settings File

if [ "$customconfig" = false ]; then  # custom settings not loaded
  if [ -f "${settingsfileOS}" ]; then # use OS-Specific
    . "${settingsfileOS}" 2>/dev/null
    [[ "$?" != 0 ]] && processAbort "Cannot read ${settingsfileOS}"
  elif [ -f "${settingsfile}" ]; then # else use default
    . "${settingsfile}" 2>/dev/null
    [[ "$?" != 0 ]] && processAbort "Cannot read ${settingsfile}"
  else  # ERROR - no settings file found
    processAbort "No settings file found"
  fi
fi

# Config file glob expansion
link_sources="${link}"
ignore_sources="${ignore}"
copy_sources="${copy}"
link_children_sources="${link_children}"

link_sources=$(remove_dupes "$link_sources" "$ignore_sources")
link_sources=$(remove_dupes "$link_sources" "$copy_sources")
link_sources=$(remove_dupes "$link_sources" "$link_children_sources")
copy_sources=$(remove_dupes "$copy_sources" "$ignore_sources")
copy_sources=$(remove_dupes "$copy_sources" "$link_children_sources")
link_children_sources=$(remove_dupes "$link_children_sources" "$ignore_sources")

# CHECK IF DEST-DIR EXISTS AND IS A DIRECTORY
if [ ! -e "$dest_dir" ]; then
  make_dir "$dest_dir"
  if [ "$?" -eq "0" ]; then
    print_output "Destination Dir: $dest_dir created"
  else
    processAbort "Destination Dir: $dest_dir didn't exist and cannot be created"
  fi
elif [ ! -d "$dest_dir" ]; then
  processAbort "Destination Dir: $dest_dir exists, but is not a directory"
fi


################################################################
### EXECUTION - Make Links & Copy Files

# OUTPUT EXECUTION TYPE
if [ "$testmode" = true ]; then
  print_output "TEST MODE - displaying changes but not making any"; print_output
elif [ "$forcemode" = true ]; then
  print_output "FORCE MODE - overwriting existing items"; print_output
else
  print_output "NORMAL MODE - will NOT overwritte existing items"; print_output
fi

# CREATE LINKS
make_links "$link_sources"

# CREATE COPIES (WITH RECURSION)
for s in $copy_sources; do
  if [ ! -e "$s" ]; then 
    continue
  fi
  target="$dest_dir/.$s"
  children=$(echo $s/*)
  if [ -d "$s" ]; then 
    if [ ! -e "$target" ]; then
      make_dir "$target"
    elif  [ ! -d "$target" ]; then
      prefail=true
      script_error_message="$script_error_message \tCopy Error: The item '$s' is a directory in the source.\n\tBut the target '$target' already exists and is NOT a directory.\n\tAttempts to create copy items to it will fail until it is removed.\n"
    else
      warning_removals=$((warning_removals=warning_removals+1))
      warning_removals_names="$warning_removals_names $target"
    fi
    for t in $children; do
      if [ "$t" = "$s/*" ]; then
        continue
      fi
      temp_src="${source_dir}/"
      copy_recursion=true
      make_copies "$t"
      copy_recursion=false
    done
    prefail=false
  else
    temp_src=""
    make_copies "$s"
  fi
done

# LINK CHILDREN (WITH RECURSION) AND MKDIR IF NEEDED
#   manually perform recursive functions for 
#     1st and 2nd levels to get error info & count
for s in $link_children_sources; do
  if [ ! -e "$s" ]; then
    continue 
  fi
  target="$dest_dir/.$s"
  children=$(echo $s/*)
  # WILL NOT delete an existing DIR
  #   if TARGET exists as a DIR - make links in it
  #   if TARGET doesnt exist, create it - then make links in it
  #   if TARGET exists but not a DIR -
  #       log error, attempt link creation to generate logging info
  #       these failures will not be revealed during test-mode
  if [ ! -e "$target" ]; then
    make_dir "$target"
  elif  [ ! -d "$target" ]; then  # $target' exists but is NOT a Dir
    prefail=true
    script_error_message="$script_error_message \tLink_Children Error: The item '$s' exists and is NOT a directory.\n\tAttempts to create links in it will fail until it is removed or renamed.\n"
  fi
  for t in $children; do    # MAKE LINKS FOR THE DIR CONTENTS
    make_links "$t"
  done
  prefail=false
done

[ "$quietmode" = true ] && processExit # if in quiet mode - bail without report

################################################################
###   REPORT (POST EXECUTION)

[ "$verbosemode" = true ] && echo

if [ "$new_copies" -gt "0" ] || [ "$new_removals" -gt "0" ] || [ "$new_links" -gt "0" ] || [ "$new_dirs" -gt "0" ]; then
  success_occured=true
fi

if [ "$error_copies" -gt "0" ] || [ "$error_links" -gt "0" ] || [ "$error_removals" -gt "0" ] || [ "$error_mkdirs" -gt "0" ]; then
  errors_occured=true
fi

# TEST REULTS
if [ "$testmode" = true ]; then
  echo "Test-mode results:"
  if [ "$detailsmode" = true ]; then
    echo -e "\n${CLRnormal}source dir:\t${CLRtitle}${source_dir}${CLRnormal}"
    echo -e "${CLRnormal}dest dir:\t${CLRtitle}${dest_dir}${CLRnormal}\n"
  fi
  [ "$test_mkdir" -gt "0" ] && report_data_test "test_mkdir"
  [ "$test_copies" -gt "0" ] && report_data_test "test_copies"
  [ "$test_links" -gt "0" ] && report_data_test "test_links"
  [ "$test_removing" -gt "0" ] && report_data_test "test_removing"
  [ "$test_errors" -gt "0" ] && report_data_test "test_errors"
fi

# SUCCESSFUL REULTS
if [ "$success_occured" = true ]; then
  echo "The following actions were sucessfull:"
  [ "$detailsmode" = true ] && echo
  [ "$new_dirs" -gt "0" ] && report_data "new_dirs"
  [ "$new_copies" -gt "0" ] && report_data "new_copies"
  [ "$new_links" -gt "0" ] && report_data "new_links"
  [ "$new_removals" -gt "0" ] && report_data "new_removals"
fi

# WARNINGS
  if [ "$warning_skipped" -gt "0" ] || [ "$warning_removals" -gt "0" ]; then
    echo "The following warnings occured:"
    [ "$detailsmode" = true ] && echo
    [ "$warning_removals" -gt "0" ] && report_data "warning_removals"
    [ "$warning_skipped" -gt "0" ] && report_data "warning_skipped"
  fi

# ERRORS
if [ "$errors_occured" = true ]; then
  echo "The following errors occured:"
  [ "$detailsmode" = true ] && echo
  [ "$error_mkdirs" -gt "0" ] && report_data "error_mkdirs"
  [ "$error_copies" -gt "0" ] && report_data "error_copies"
  [ "$error_links" -gt "0" ] && report_data "error_links"
  [ "$error_removals" -gt "0" ] && report_data "error_removals"
fi


# ERROR DETAILS
if [ -n "$script_error_message" ]; then
  echo "Error Details:"
  echo "$script_error_message"
fi

processExit

# this should never execute
exit 0
