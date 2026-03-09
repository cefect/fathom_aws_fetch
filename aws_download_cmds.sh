#!/usr/bin/env bash
#
# Sync Fathom flood-map S3 prefixes into a provided output directory.
# Usage: aws_download_cmds.sh <out_dir>
#
set -uo pipefail

# Resolve destination root from the first script argument.
OUT_DIR="${1:?ERROR: Need out_dir as first arg}"
mkdir -p "${OUT_DIR}"

# Use the project-local AWS config so S3 tuning is explicit and reproducible.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export AWS_CONFIG_FILE="${SCRIPT_DIR}/aws_s3.config"
export AWS_PROFILE="${AWS_PROFILE:-fathom}"

S3_URIS=(
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in5-PLUVIAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in10-PLUVIAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in20-PLUVIAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in50-PLUVIAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in100-PLUVIAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in200-PLUVIAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in500-PLUVIAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in1000-PLUVIAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in5-FLUVIAL-UNDEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in10-FLUVIAL-UNDEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in20-FLUVIAL-UNDEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in50-FLUVIAL-UNDEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in100-FLUVIAL-UNDEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in200-FLUVIAL-UNDEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in500-FLUVIAL-UNDEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in1000-FLUVIAL-UNDEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in5-FLUVIAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in10-FLUVIAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in20-FLUVIAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in50-FLUVIAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in100-FLUVIAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in200-FLUVIAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in500-FLUVIAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in1000-FLUVIAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in5-COASTAL-UNDEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in10-COASTAL-UNDEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in20-COASTAL-UNDEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in50-COASTAL-UNDEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in100-COASTAL-UNDEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in200-COASTAL-UNDEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in500-COASTAL-UNDEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in1000-COASTAL-UNDEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in5-COASTAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in10-COASTAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in20-COASTAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in50-COASTAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in100-COASTAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in200-COASTAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in500-COASTAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
    "s3://fathom-products-flood/flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in1000-COASTAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1"
)

SCRIPT_START="${SECONDS}"
TOTAL="${#S3_URIS[@]}"
I=0
SUCCESS_COUNT=0
FAIL_COUNT=0
KNOWN_ACCESS_DENIED_MSG="An error occurred (AccessDenied) when calling the GetObject operation"

for s3_uri in "${S3_URIS[@]}"
do
    I=$((I + 1))
    ITER_START="${SECONDS}"
    tmp_err_fp="$(mktemp)"

    # Print each dataset name so sync progress is easy to follow in logs.
    echo "[${I}/${TOTAL}] syncing ${s3_uri##*/}"
    if aws s3 sync "${s3_uri}" "${OUT_DIR}/${s3_uri##*/}" --size-only --progress-multiline --progress-frequency 5 2>"${tmp_err_fp}"; then
        sync_status="finished"
    elif [[ -s "${tmp_err_fp}" ]] && ! grep -Fv "${KNOWN_ACCESS_DENIED_MSG}" "${tmp_err_fp}" >/dev/null; then
        sync_status="finished"
    else
        sync_status="failed"
    fi

    # Suppress only the known noisy GetObject AccessDenied message.
    if [[ -s "${tmp_err_fp}" ]]; then
        grep -Fv "${KNOWN_ACCESS_DENIED_MSG}" "${tmp_err_fp}" >&2 || true
    fi
    rm -f "${tmp_err_fp}"

    if [[ "${sync_status}" == "finished" ]]; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    ITER_ELAPSED=$((SECONDS - ITER_START))
    TOTAL_ELAPSED=$((SECONDS - SCRIPT_START))
    printf '[%s/%s] %s %s in %02d:%02d:%02d (total %02d:%02d:%02d)\n' \
        "${I}" "${TOTAL}" "${sync_status}" "${s3_uri##*/}" \
        $((ITER_ELAPSED / 3600)) $(((ITER_ELAPSED % 3600) / 60)) $((ITER_ELAPSED % 60)) \
        $((TOTAL_ELAPSED / 3600)) $(((TOTAL_ELAPSED % 3600) / 60)) $((TOTAL_ELAPSED % 60))
done

FINAL_ELAPSED=$((SECONDS - SCRIPT_START))
printf 'completed %s syncs with %s success(es) and %s failure(s) in %02d:%02d:%02d\n' \
    "${TOTAL}" "${SUCCESS_COUNT}" "${FAIL_COUNT}" \
    $((FINAL_ELAPSED / 3600)) $(((FINAL_ELAPSED % 3600) / 60)) $((FINAL_ELAPSED % 60))

if [[ "${FAIL_COUNT}" -gt 0 ]]; then
    exit 1
fi
