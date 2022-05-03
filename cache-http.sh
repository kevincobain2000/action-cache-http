#! /bin/sh

set -e
echo "Cache HTTP started"
echo RUNNER_OS: "$RUNNER_OS"
echo INPUT_VERSION: "$INPUT_VERSION"
echo INPUT_HTTP_PROXY: "$INPUT_HTTP_PROXY"
echo INPUT_DESTINATION_FOLDER: "$INPUT_DESTINATION_FOLDER"
echo INPUT_LOCK_FILE: "$INPUT_LOCK_FILE"
echo INPUT_INSTALL_COMMAND: "$INPUT_INSTALL_COMMAND"
echo INPUT_CACHE_HTTP_API: "$INPUT_CACHE_HTTP_API"
echo INPUT_OPERATING_DIR: "$INPUT_OPERATING_DIR"
echo INPUT_DISABLE_COMPRESSION: "$INPUT_DISABLE_COMPRESSION"

if [ -z "$INPUT_LOCK_FILE" ]; then
    echo "no lock file given"
    exit;
fi

if [ -n "$INPUT_OPERATING_DIR" ]; then
    cd "$INPUT_OPERATING_DIR"
fi

COMPRESS_FLAG='z'

if [ -n "$INPUT_DISABLE_COMPRESSION" ]; then
  COMPRESS_FLAG=''
fi


echo "check connection"
curl \
    -u "$INPUT_BASIC_AUTH_USERNAME:$INPUT_BASIC_AUTH_PASSWORD" \
    -X GET \
    -x "$INPUT_HTTP_PROXY" \
    "$INPUT_CACHE_HTTP_API/health"

shaLockfile=$(openssl sha1 "$INPUT_LOCK_FILE" |awk '{print $2}')
shaInstallCommand=$(echo "$INPUT_INSTALL_COMMAND"|openssl sha1|awk '{print $2}')
shaDestinationFolder=$(echo "$INPUT_DESTINATION_FOLDER"|openssl sha1|awk '{print $2}')

tarFile="$RUNNER_OS-$INPUT_VERSION-$shaInstallCommand-$shaLockfile-$shaDestinationFolder.tar.gz"

echo tarfile: "$tarFile"

response=$(curl \
    -u "$INPUT_BASIC_AUTH_USERNAME:$INPUT_BASIC_AUTH_PASSWORD" \
    -X GET \
    -x "$INPUT_HTTP_PROXY" \
    -skI \
    "$INPUT_CACHE_HTTP_API/assets/$tarFile" \
    | head -n 1 | awk -F" " '{print $2}')

if [ "$response" = "200" ] || [ "$response" -eq 200 ]; then
    echo "Cache hit"
    curl \
        -u "$INPUT_BASIC_AUTH_USERNAME:$INPUT_BASIC_AUTH_PASSWORD" \
        -X GET \
        -x "$INPUT_HTTP_PROXY" \
        -k \
        "$INPUT_CACHE_HTTP_API/assets/$tarFile" \
        --output "$tarFile" && \
    tar "${COMPRESS_FLAG}xf" "$tarFile"
    echo "Cache hit, untar success"
else
    echo "Cache miss"
    $INPUT_INSTALL_COMMAND && \
    tar "${COMPRESS_FLAG}cf" "$tarFile" "$INPUT_DESTINATION_FOLDER" && \

    echo "Cache miss, uploading" && \

    curl \
        -u "$INPUT_BASIC_AUTH_USERNAME:$INPUT_BASIC_AUTH_PASSWORD" \
        -X POST \
        -x "$INPUT_HTTP_PROXY" \
        -k \
        --form "file=@$tarFile" \
        "$INPUT_CACHE_HTTP_API/upload" && \

    echo "Cache miss, upload success"
fi
