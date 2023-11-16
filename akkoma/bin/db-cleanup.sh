#!/bin/sh +x
set -e

export HOME=/opt/akkoma

while ! pg_isready -U "${DB_USER:-akkoma}" -d "postgres://${DB_HOST:-db}:${DB_PORT:-5432}/${DB_NAME:-akkoma}" -t 1; do
    sleep 1s
done

echo "-- prune old objects from the DB --"
"$HOME"/bin/pleroma_ctl database prune_objects --prune-orphaned-activities --keep-threads

echo "-- prune stale things from the DB --"
"$HOME"/bin/pleroma_ctl database prune_task
