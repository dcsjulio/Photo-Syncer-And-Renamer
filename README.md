
[![Actions Status](https://github.com/juliodcs/Photo-Syncer-And-Renamer/workflows/tests/badge.svg)](https://github.com/juliodcs/Photo-Syncer-And-Renamer/actions)

# NAME

Photo-Renamer-And-Syncer - Script to sync exif dates and change file names according to those dates

# VERSION

Version 0.1

# SYNOPSIS

Syncs photos accross different camera directories. This is useful when different cameras have set up different clock times or dates.

For this, you need to specify a "sync" photo for each camera. You can usually do this by shooting a photo at the same time for every camera.

Once you specify the sync photos for the script, it will do the following:

  - Read all the photos contained at the directories where the sync photos reside
  - Copy or Move all the photos to some output directory
  - Update the exif information
  - Rename photos according to their exif date

Note that the first sync photo (and thus, directory) won't change their dates since this will be considered to have the "correct" dates used to sync all other directories.


# Arguments

## \-\-help

Print some help message and list of arguments

## \-\-syncphoto

Specifies sync photo. Its parent directory will be processed. All photos contained at the directory will be moved/copied, renamed and will update their exif date. 

First \-\-syncphoto will be considered to have the main/correct dates to use when syncing other photos on other directories.

## \-\-dirdepth

Depth of the directories to process (default 0, no subdirectories will be processed)

## \-\-outdir

Output directory

## \-\-action

Action when processing photos to output directory. Valid actions are "copy" and "move".

# Allowed formats

This script can process any *image* format supported by [*Image::ExifTool*](https://metacpan.org/pod/Image::ExifTool)

# Examples

    photo-syncer-and-renamer.pl \
        --syncphoto /tmp/camera1/sync.jpg \
        --syncphoto /tmp/camera2/sync.jpg \
        --dirdepth 2 \
        --outdir /tmp/output \
        --action move
