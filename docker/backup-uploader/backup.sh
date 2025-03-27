#!/bin/bash
readonly BACKUP_UPLOADER_BUCKET_1
readonly BACKUP_UPLOADER_BUCKET_2

function pretty_print() {
    local date
    local message
    date=$(date '+%Y-%m-%d %H:%M:%S')
    message=$(echo "$1" | jq -Rs .)
    echo "{\"date\":\"$date\", \"message\":'$message'}"
}

function exit_with_failure() {
    pretty_print "ERROR $1"
    exit 1
}

if [ -z "${BACKUP_UPLOADER_BUCKET_1}" ]; then
    exit_with_failure "BACKUP_UPLOADER_BUCKET_1 is not defined"
fi

saved_dir="/opt/hgcapp/services-hedera/HapiApp2.0/data/saved/com.hedera.services.ServicesMain"
node_id=$(ls $saved_dir)

if [ ! -d "$saved_dir/$node_id/123/" ]; then
  exit_with_failure "SAVED STATE DIRECTORY DOES NOT EXIST"
else
   readonly node_id
   readonly saved_dir
fi

cd "$saved_dir/$node_id/123/" || exit_with_failure "COULD NOT cd TO $saved_dir/$node_id/123/"
mapfile -t all_states < <(ls)

backup_hostname=$(cat /etc/hostname); readonly backup_hostname

rclone_cmd="rclone --bwlimit 51200K --log-level INFO --use-json-log"; readonly rclone_cmd

if [ -n "${BACKUP_UPLOADER_BUCKET_2}" ]; then
  if [ "$node_id" = "0" ] || [ "$node_id" = "9" ]; then
    bucket="${BACKUP_UPLOADER_BUCKET_1}"
  else
    bucket="${BACKUP_UPLOADER_BUCKET_2}"
  fi
else
bucket="${BACKUP_UPLOADER_BUCKET_1}"
fi
readonly bucket

# Take the next to last backup. We do not currently have a way
# to ensure the backup has finished writing, so taking the second oldest
# is the safest method we can currently use.
second_to_last_state=${all_states[-2]}
if [ -z "$second_to_last_state" ]; then
  # This can happen if no states have been written
  exit_with_failure "ERROR - No Second to Last State found! Nothing to back up. Found states: ${all_states[*]}"
else
  readonly second_to_last_state
fi

backup_latest="$bucket/nodes/$backup_hostname/latest"; readonly backup_latest
backup_destination="$bucket/$backup_hostname/$second_to_last_state"

# add in VERSION file for humans so we know what this state is about

pretty_print "ATTEMPTING SYNC $second_to_last_state TO $backup_latest"

# shellcheck disable=SC2086
if $rclone_cmd sync $second_to_last_state backups:$backup_latest; then
    pretty_print "SUCCESSFULLY SYNCED TO $backup_latest"
else
    exit_with_failure "ERROR SYNCING TO $backup_latest"
fi

# copy in version file
# shellcheck disable=SC2086
version_source=/opt/hgcapp/services-hedera/HapiApp2.0/VERSION; readonly version_source
version_dest=$backup_latest/; readonly version_dest

pretty_print "ATTEMPTING COPY $version_source TO $version_dest"
if $rclone_cmd copy $version_source backups:$version_dest; then
    pretty_print "COPY SUCCESSFUL $version_dest"
else
    exit_with_failure "ERROR DURING COPY TO $version_dest"
fi

pretty_print "BACKING UP TO $backup_destination"
# shellcheck disable=SC2086
if $rclone_cmd sync backups:$backup_latest backups:$backup_destination; then
    pretty_print "BACKUP SUCCESSFUL $backup_destination"
else
    exit_with_failure "ERROR BACKING UP TO $backup_destination"
fi

current_round_number="/$backup_hostname.txt"
echo $second_to_last_state > $current_round_number
$rclone_cmd copy $current_round_number backups:$bucket/current_round/
pretty_print "LATEST ROUND ${second_to_last_state} WRITTEN TO $bucket/current_round/$current_round_number"

# only backup stats file on the midnight backup
if [ "$(date +%H)" = "00" ] && [ "$(date +%H%M%S)" -lt "001000" ]; then
  stats_bucket="${BACKUP_UPLOADER_BUCKET_1}"; readonly stats_bucket
  # shellcheck disable=SC2046,SC2086
  rclone copy /opt/hgcapp/services-hedera/HapiApp2.0/data/stats/MainNetStats${node_id}.csv backups:$stats_bucket/stats/$backup_hostname/MainNetStats${node_id}-$(date --iso-8601).csv
  pretty_print "SUCCESSFULLY BACKED STATS CSV FILE"
fi
