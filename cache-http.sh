#! /bin/sh

set -e
echo "Cache HTTP started"
echo RUNNER_OS: $RUNNER_OS
echo INPUT_VERSION: $INPUT_VERSION
echo INPUT_HTTP_PROXY: $INPUT_HTTP_PROXY
echo INPUT_DESTINATION_FOLDER: $INPUT_DESTINATION_FOLDER
echo INPUT_LOCK_FILE: $INPUT_LOCK_FILE
echo INPUT_INSTALL_COMMAND: $INPUT_INSTALL_COMMAND
echo INPUT_CACHE_HTTP_API: $INPUT_CACHE_HTTP_API

if [ -z $INPUT_LOCK_FILE ]; then
    echo "no lock file given"
    exit;
fi

shaLockfile=`openssl sha1 $INPUT_LOCK_FILE |awk '{print $2}'`
shaInstallCommand=`echo $INPUT_INSTALL_COMMAND|openssl sha1|awk '{print $2}'`

tarFile=$RUNNER_OS-$INPUT_VERSION-$shaInstallCommand-$shaLockfile.tar.gz

echo tarfile: $tarFile

response=`curl \
    -u $INPUT_BASIC_AUTH_USERNAME:$INPUT_BASIC_AUTH_PASSWORD \
    -X GET \
    -x "$INPUT_HTTP_PROXY" \
    -skI \
    $INPUT_CACHE_HTTP_API/assets/$tarFile \
    | head -n 1 | awk -F" " '{print $2}'`


if [ $response == 200 ]; then
    echo "Cache hit"
    curl \
        -u $INPUT_BASIC_AUTH_USERNAME:$INPUT_BASIC_AUTH_PASSWORD \
        -X GET \
        -x "$INPUT_HTTP_PROXY" \
        -k \
        $INPUT_CACHE_HTTP_API/assets/$tarFile \
        --output $tarFile && \
    tar xzf $tarFile
    echo "Cache hit untar success"
else
    echo "Cache hit miss"
    $INPUT_INSTALL_COMMAND && \
    tar zcf $tarFile $INPUT_DESTINATION_FOLDER && \

    echo "Cache hit uploading" && \

    curl \
        -u $INPUT_BASIC_AUTH_USERNAME:$INPUT_BASIC_AUTH_PASSWORD \
        -X POST \
        -x "$INPUT_HTTP_PROXY" \
        -k \
        --form file=@$tarFile \
        $INPUT_CACHE_HTTP_API/upload && \

    echo "Cache hit upload success"
fi
