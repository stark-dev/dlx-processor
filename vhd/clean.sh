#!/bin/bash

echo "Cleaning dir..."

rm -f *.bak
rm -f *transcript
rm -f *.wlf
rm -f *.vstf
rm -f *wlft*

# removing work dir
if [ -d work ]; then
  echo "Do you want to remove work directory? (y/n)"
  read answer
  if [ $answer = 'y' ]; then
    echo "  Removing work dir..."
    rm -rf work
    echo "  Done!"
    echo "  Remember to run setmentor and vlib work"
  fi
fi

echo "Clean! Enjoy ;-)"
