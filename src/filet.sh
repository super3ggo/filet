#!/bin/sh
#
# Filename: filet.sh
# Note:     A POSIX compliant shell script to setup and teardown symbolic links
#           for a set of files outlined by an argument configuration file.
#
#           Note, this file contains the previous POSIX shell script
#           implementation, which this project aims to port to something more
#           maintainable.

#
# Variables
#

# These allow for a more manageable way to read this file's parent Git directory
# so that we can validate the script runs in the correct specified location.
pathExec="$( cd "$(dirname -- "$0")" || exit 1 ; pwd -P )"
thisRepoName="dotfiles"
thisRepoPath="$(dirname "$pathExec")"
thisRepoPathBaseName="$(basename "$thisRepoPath")"

# Arguments
flagHelp="--help"
flagHelpAbbrev="-h"
flagLink="--link"
flagLinkAbbrev="-l"
flagUnlink="--unlink"
flagUnlinkAbbrev="-u"

# Configuration file
configurationFile="dotfiles.txt"

# Link Actions
link_action_link="link"
link_action_unlink="unlink"

# Printing
delimiter="--------------------------------------------------"

#
# Functions
#

link() {
  # This function will parse the $configurationFile, and create a symbolic link
  # for each file per line at the specified directory.
  #
  # It short circuits the script upon encountering an error, and prints the
  # cause of error to STDOUT.
  #
  # It assumes that the $configurationFile exists and its contents, parsable.

  # Detect whether the host has link, ln, installed and set the respective flags
  # for creating symbolic links.
  if ! command -v ln > /dev/null
  then
    echo "Error: Unable to find link binary on system."
    echo "Exiting with nonzero code.."
    exit 1
  fi

  # TODO: Add support for Windows (or WSL).
  case "$(uname -s)" in
    "Darwin")
      echo "BSD/Mac system detected."
      echo "Setting flags.."
      ln_flags="-shfv"
      ;;
    "Linux")
      echo "Linux system detected."
      echo "Setting flags.."
      ln_flags="-sTfv"
      ;;
    *)
      echo "Error: Incompatible system detected."
      echo "Exiting with nonzero code.."
      exit 1
  esac

  echo "Done."
  echo "Linking.."
  echo "$delimiter"

  while IFS="," read -r filetype filepath linkpath
  do
    filepath_full="$HOME/$filepath"
    linkpath_full="$HOME/$linkpath"

    ln "$ln_flags" "$filepath_full" "$linkpath_full"
  done < "$1"

  echo "$delimiter"
  echo "Done."
}

print_help() {
  # This function prints the help documentation for properly running this
  # script.

  echo "Usage:  filet [options] [file]

  Options: $flagHelpAbbrev, $flagHelp
  Print help, i.e. this output.

  $flagLinkAbbrev, $flagLink [file]
  Parse the contents of the configuration file, and if it
  contains no errors, i.e. the relevant directories and files
  exist on disk, create symbolic links for the file(s) listed
  per line.

  $flagUnlinkAbbrev, $flagUnlink [file]
  Parse the contents of the configuration file, and if it
  contains no errors, i.e. the relevant directories and files
  exist on disk, destroy the symbolic links for the file(s)
  listed per line.

  File:    A plain text configuration file named $configurationFile. It can
  exist anywhere within the user home directory insofar as the
  host filesystem has access. It must have the format below:

  filetype + , + path_to_file + , + path_to_symbolic_link

  The filetype specifies either a directory or file. Any string
  of characters beginning with d specifies that the path points
  to a directory and with f, that the path points to a file.

  Paths must be fully written so their location from the user
  home directory is clear.

  E.g. file,foo/.bashrc,.bashrc
  Conveys the file ~/foo/.bashrc and the respective symbolic link
  at ~/.bashrc.

  E.g. f,foo/.bash_profile,.bash_profile
  Conveys the file ~/foo/.bash_profile and the respective
  symbolic link at ~/.bash_profile.

  E.g. dir,foo/.config.d,.config.d
  Conveys the directory ~/foo/.config.d and the respective
  symbolic link at ~/.config.d.
  "
}

unlink() {
  # This function will parse the $configurationFile, and will remove the
  # symbolic link for each file, i.e. the rightmost comma separated value.
  #
  # It short circuits the script upon encountering an error, and prints the
  # cause of error to STDOUT.
  #
  # It assumes that the $configurationFile exists and its contents, parsable.

  echo "Unlinking.."
  echo "$delimiter"
  echo "Removing.."

  while IFS="," read -r filetype filepath linkpath
  do
    linkpath_full="$HOME/$linkpath"
    linkpath_full_noexpand="${HOME:?}/$linkpath"

    rm -rf "$linkpath_full_noexpand"
    echo "-> $linkpath_full"
  done < "$1"

  echo "$delimiter"
  echo "Done."
}

validate_file_content() {
  # This function parses the $configurationFile, and validates whether the files
  # marked for linking and the directories where their respective links will get
  # created exist on disk.
  #
  # It short circuits the script upon encountering an error, and prints the
  # cause of error to STDOUT.
  #
  # It assumes that the $configurationFile exists.

  while IFS="," read -r filetype filepath linkpath
  do
    filepath_full="$HOME/$filepath"
    linkpath_directory="$HOME/$(dirname "$linkpath")"

    if [ -z "$filetype" ]
    then
      echo "Error:   Non-parsable content"
      echo "Content: $filetype"
      echo "Please make sure $configurationFile has correct formatting."
      echo "Exiting with nonzero code.."
      exit 1
    fi

    if [ -z "$filepath" ]
    then
      echo "Error:   Non-parsable content"
      echo "Content: $filepath"
      echo "Please make sure $configurationFile has correct formatting."
      echo "Exiting with nonzero code.."
      exit 1
    fi

    if [ -z "$linkpath" ]
    then
      echo "Error:   Non-parsable content"
      echo "Content: $linkpath"
      echo "Please make sure $configurationFile has correct formatting."
      echo "Exiting with nonzero code.."
      exit 1
    fi

    case "$filetype" in
      "d"*)
        if [ ! -d "$filepath_full" ]
        then
          echo "Error:     Could not find directory on disk."
          echo "Directory: $filepath_full"
          echo "Exiting with nonzero code.."
          exit 1
        fi
        ;;
      "f"*)
        if [ ! -f "$filepath_full" ]
        then
          echo "Error: Could not find file on disk."
          echo "File:  $filepath_full"
          echo "Exiting with nonzero code.."
          exit 1
        fi
        ;;
      *)
        echo "Error:   Non-parsable content"
        echo "Content: $filetype"
        echo "Please make sure $configurationFile has correct formatting."
        echo "Exiting with nonzero code.."
        exit 1
    esac

    if [ ! -d "$linkpath_directory" ]
    then

      echo "Error:     Could not find directory on disk."
      echo "Directory: $linkpath_directory"
      echo "Exiting with nonzero code.."
      exit 1
    fi

  done < "$1"
}

validate_file_path() {
  # This function accepts a file path as its only argument, and checks whether
  # the file exists on disk. The file must have the name of the variable
  # $configurationFile.
  #
  # It short circuits the script upon encountering an error, and prints the
  # cause of error to STDOUT.

  case "$(basename "$1")" in
    "$configurationFile")
      if [ ! -e "$1" ]
      then
        echo "Error:         Could not find file on disk!"
        echo "File argument: $1"
        echo "Exiting with nonzero code.."
        exit 1
      fi
      ;;
    *)
      echo "Error:         Non-parsable argument detected!"
      echo "File argument: $1"
      echo "Please provide the correct configuration file, i.e. $configurationFile."
      echo "Exiting with nonzero code.."
      exit 1
  esac
}

validate_link_argument() {
  # This function accepts a link argument as its only argument, and sets the
  # link action accordingly. Refer to the [options] section of the help
  # documentation, i.e. print_help, for more details.
  #
  # It short circuits the script upon encountering an error, and prints the
  # cause of error to STDOUT.

  case "$1" in
    "$flagHelp"|"$flagHelpAbbrev")
      echo "Error:    Non-parsable argument detected!"
      echo "Argument: $1"
      echo "Access the help documentation by only passing $flagHelp."
      echo "Exiting with nonzero code.."
      exit 1
      ;;
    "$flagLink"|"$flagLinkAbbrev")
      echo "Creating symbolic links.."
      link_action="$link_action_link"
      ;;
    "$flagUnlink"|"$flagUnlinkAbbrev")
      echo "Destroying symbolic links.."
      link_action="$link_action_unlink"
      ;;
    *)
      echo "Error:    Non-parsable argument detected!"
      echo "Argument: $1"
      echo "Exiting with nonzero code.."
      exit 1
  esac
}

#
# Script
#

# Make sure this script only runs from the bin directory of this particular Git
# repository.
if [ "$thisRepoPathBaseName" != "$thisRepoName" ]
then
  echo "Error: Invalid directory detected. Run within $thisRepoName."
  echo "Exiting with nonzero code.."
  exit 1
fi

case "$#" in
  1)
    case "$1" in
      "$flagHelp"|"$flagHelpAbbrev")
        print_help
        exit 0
        ;;
      "$flagLink"|"$flagLinkAbbrev")
        echo "Error:    Non-parsable argument detected!"
        echo "Argument: $1"
        echo "Passing $flagLink requires a file argument!"
        echo "Exiting with nonzero code.."
        exit 1
        ;;
      "$flagUnlink"|"$flagUnlinkAbbrev")
        echo "Error:    Non-parsable argument detected!"
        echo "Argument: $1"
        echo "Passing $flagUnlink requires a file argument!"
        echo "Exiting with nonzero code.."
        exit 1
        ;;
      *)
        echo "Error:    Non-parsable argument detected!"
        echo "Argument: $1"
        echo "Exiting with nonzero code.."
        exit 1
    esac
    ;;
  2)
    validate_link_argument "$1"
    validate_file_path "$2"
    validate_file_content "$2"

    if [ "$link_action" = "$link_action_link" ]
    then
      link "$2"
    else
      unlink "$2"
    fi
    ;;
  *)
    echo "Error:     Invalid number of arguments!"
    echo "Arguments: $# (expected 2)"
    echo "Run this script with the $flagHelp flag for more context."
    echo "Exiting with nonzero code.."
    exit 1
esac
