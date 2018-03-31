#!/bin/bash

if [ $# -lt 1 ]; then
  echo "       ./compile.sh <folder> to compile all vhd files in the specified folder"
  echo "        The script compiles automatically all vhd files in alphabetical order."
  echo "        Be sure all files are named in the correct way."
  exit 0
fi

#compiling all vhd files


if [ -d $1 ]; then
  for vhd_file in `find $1 -mindepth 1 -name "*.vhd" | sort`; do
        echo "Compiling " $vhd_file" ..."
        ret=`vcom $vhd_file`
	error=`echo $ret | grep -ci error`
	if [ $error -ne 0 ]; then
		vcom $vhd_file
		echo "       ERROR while compiling $vhd_file"
		echo "       compilation stops"
		break;
	fi
  done
else
        echo "       Invalid folder. Please specify an existing folder name"
        exit 1
fi

exit 0
