#!/bin/bash

set -eo pipefail

echo "Job started: $(date)"

DATE=$(date +%Y%m%d_%H%M%S)
FILENAME=backup-$DATE.tar.gz
S3_KEY=${TARGET_S3_FOLDER%/}/$FILENAME

if [[ -z "$TARGET_FOLDER" ]]; then
    # dump directly to AWS S3

    if [[ -z "$TARGET_S3_FOLDER" ]]; then
        >&2 echo "If TARGET_FOLDER is null/unset, TARGET_S3_FOLDER must be set"
        exit 1
    fi

    mongodump --uri "$MONGO_URI" --gzip --archive | /usr/local/bin/aws s3 cp - $S3_KEY
    echo "Mongo dump uploaded to $TARGET_S3_FOLDER"
else
    # save dump locally (and optionally to AWS S3)
    mkdir -p $TARGET_FOLDER
    cd $TARGET_FOLDER
    mongodump --uri "$MONGO_URI" --gzip --archive="$FILENAME"
    echo "Mongo dump saved to $FILENAME"

    if [[ -n "$TARGET_S3_FOLDER" ]]; then
        /usr/local/bin/aws s3 cp $FILENAME $S3_KEY
        echo "$FILENAME uploaded to $S3_KEY"
    fi
fi

echo "Job finished: $(date)"
