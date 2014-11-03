#!/bin/sh

if [ $# -lt 1 ]; then
    echo "Usage:  make_commands.sh Commands.h"
    exit 1
fi

FILENAME=$1
PREFIX='#define COMMAND_'

echo "commands_dict = {"
grep "^${PREFIX}" $FILENAME | sed "s/^${PREFIX}\([A-Z]\+\)\([ 0-9a-fA-Fx]\+\)$/    '\1': \2,/"
echo "}"
echo "Command = type('Command', (object,), commands_dict)"
echo "del commands_dict"
