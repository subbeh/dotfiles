#!/bin/sh

MACPREFS_BACKUP_DIR="${XDG_WORKSPACE_DIR:?not set}/misc/macprefs/$(date +%Y%m%d)/"
export MACPREFS_BACKUP_DIR
