#!/bin/bash

return_with_error() {
    echo "Error: $1" >&2
    return 1
}

upload_file() {
    local file=$1
    local project_id=$2
    local token=$3
    local lang_iso="${BASE_LANG}"
    local additional_params="${CLI_ADD_PARAMS:-}"
    local attempt=0
    local max_retries="${MAX_RETRIES:-3}"
    local sleep_time="${SLEEP_TIME:-1}"
    local max_sleep_time=60
    local max_total_time=300
    local start_time=$(date +%s)
    local github_ref_name="${GITHUB_REF_NAME}"

    [[ -z "$project_id" ]] && return_with_error "project_id is required and cannot be empty."
    [[ -z "$token" ]] && return_with_error "token is required and cannot be empty."
    [[ -z "$lang_iso" ]] && return_with_error "lang_iso is required and cannot be empty."

    if [[ "$sleep_time" -lt 1 ]]; then
        sleep_time=1
    elif [[ "$sleep_time" -gt "$max_sleep_time" ]]; then
        sleep_time=$max_sleep_time
    fi

    if ! [[ "$max_retries" =~ ^[0-9]+$ ]] || [[ "$max_retries" -lt 1 ]]; then
        max_retries=3
    fi

    if ! [[ "$max_total_time" =~ ^[0-9]+$ ]] || [[ "$max_total_time" -lt $max_sleep_time ]]; then
        max_total_time=300
    fi

    echo "Starting upload for $file"
    while [ $attempt -lt $max_retries ]; do
        echo "Attempt $((attempt + 1)) of $max_retries"

        output=$(./bin/lokalise2 --token="$token" \
            --project-id="$project_id" \
            file upload \
            --file="$file" \
            --lang-iso="$lang_iso" \
            --replace-modified \
            --include-path \
            --distinguish-by-file \
            --poll \
            --poll-timeout=120s \
            --tag-inserted-keys \
            --tag-skipped-keys=true \
            --tag-updated-keys \
            --tags "$github_ref_name" \
            $additional_params 2>&1)

        exit_code=$?

        if [ $exit_code -eq 0 ]; then
            echo "Successfully uploaded $file"
            return 0
        elif echo "$output" | grep -q 'API request error 429'; then
            attempt=$((attempt + 1))
            current_time=$(date +%s)
            elapsed_time=$((current_time - start_time))
            if [ $elapsed_time -ge $max_total_time ]; then
                return_with_error "Max total retry time exceeded before sleeping ($max_total_time seconds) when uploading $file. Exiting."
            fi
            echo "Attempt $attempt failed with API request error 429 when uploading $file. Retrying in $sleep_time seconds..."
            sleep $sleep_time
            sleep_time=$((sleep_time * 2))
            if [ $sleep_time -gt $max_sleep_time ]; then
                sleep_time=$max_sleep_time
            fi
        else
            return_with_error "Permanent error encountered during file upload $file: $output"
        fi
    done

    return_with_error "Failed to upload file: $file after $max_retries attempts"
}