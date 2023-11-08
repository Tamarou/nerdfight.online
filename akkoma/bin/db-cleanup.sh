#!/bin/sh +x

# prune old objects from the DB
/opt/akkoma/bin/pleroma_ctl database prune_objects --prune-orphaned-activities --keep-threads

# prune stale things from the DB
/opt/akkoma/bin/pleroma_ctl database prune_task
