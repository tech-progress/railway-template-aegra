# Upgrade

Update `aegra-cli` in `requirements.in`, regenerate `requirements.lock` with hashes, and rebuild from an empty Docker cache. Review upstream migrations and release notes, then repeat clean-volume startup, authenticated execution, initialized restart, and mid-run crash recovery before changing `VERSION`.

Update PostgreSQL or Redis independently only after verifying the target image digest, volume layout, authentication, and Aegra compatibility. Back up PostgreSQL before a major-version change; replacing the image pin does not perform a safe database downgrade.
