#!/bin/sh

BINARY="jq"
USER_BIN=$HOME/bin
OS="$1"

link=$(curl -s https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64)

echo "downloading ${BINARY} from $link"

curl -L -o ${BINARY} ${link}
chmod +x ${BINARY}

if [ ! -d "$USER_BIN" ]; then
  mkdir -p ${USER_BIN}
  echo "created $USER_BIN directory, don't forget to add it to PATH environment variable"
fi

echo "moving ${BINARY} to ${USER_BIN}/${BINARY}"

mv ${BINARY} ${USER_BIN}/${BINARY}

echo "installation is done."