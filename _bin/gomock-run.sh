#!/bin/sh

mocks="$1"

if [ -z "$mocks" ]; then
    echo "setting mocks to mocks/mock.json"
    mocks="mocks/mock.json"
fi

(which -s gomock)
gomockCode=$?
if [ $gomockCode -eq 1 ]; then
    echo "gomock is not installed"
    ./_bin/gomock-install.sh
fi

# (which -s jq)
# jqCode=$?
# if [ $jqCode -eq 1 ]; then
#     echo "jq is not installed"
#     ./_bin/jq-install.sh
# fi

# version=$($HOME/bin/gomock -version)
# latest=$(curl https://api.github.com/repos/smeshkov/gomock/releases/latest | jq -r '.tag_name')
# if [ "$version" != "$latest" ]; then
#     echo "current gomock version is $version, updating to $latest..."
#     ./_bin/gomock-install.sh
# fi

$HOME/bin/gomock -verbose -mock $mocks