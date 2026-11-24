# Changelog

## v1.0.0

- Initial release.
- Syncs user CA certificates from `/data/misc/user/0/cacerts-added` (and optional `extra_certs/`) into `/system/etc/security/cacerts` and `/apex/com.android.conscrypt/cacerts` via NoMount VFS redirection.
- Sets `u:object_r:system_security_cacerts_file:s0` SELinux labels and standard `0755/0644` permissions.
- Adds `post-fs-data.sh` staging, `service.sh` boot sync + `inotifyd` live watcher, `action.sh` manual sync, and `uninstall.sh` cleanup.
