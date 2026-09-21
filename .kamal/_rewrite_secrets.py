#!/usr/bin/env python3
"""Rewrite .kamal/secrets with generated values. Do not print secret values."""
import os
import secrets
from pathlib import Path

root = Path(__file__).resolve().parent.parent
secrets_path = root / ".kamal" / "secrets"

# Keep existing registry password if present.
registry_password = None
if secrets_path.exists():
    for line in secrets_path.read_text().splitlines():
        if line.startswith("KAMAL_REGISTRY_PASSWORD="):
            registry_password = line.split("=", 1)[1]
            break

if not registry_password:
    raise SystemExit("KAMAL_REGISTRY_PASSWORD missing from current secrets file")

db_password = secrets.token_hex(24)
lines = [
    f"KAMAL_REGISTRY_PASSWORD={registry_password}",
    f"SECRET_KEY_BASE={secrets.token_hex(64)}",
    f"RAILS_RUNNER_DATABASE_PASSWORD={db_password}",
    f"POSTGRES_PASSWORD={db_password}",
    f"ADMIN_PASSWORD={secrets.token_urlsafe(16)}",
]

secrets_path.write_text("\n".join(lines) + "\n")
os.chmod(secrets_path, 0o600)

for rel in ("bin/kamal", "bin/docker-entrypoint"):
    path = root / rel
    mode = path.stat().st_mode
    os.chmod(path, mode | 0o111)

print("secrets_rewritten=yes")
print("secrets_mode=%o" % (secrets_path.stat().st_mode & 0o777))
print("bin_kamal_executable=%s" % bool(os.access(root / "bin/kamal", os.X_OK)))
print("bin_entrypoint_executable=%s" % bool(os.access(root / "bin/docker-entrypoint", os.X_OK)))
print("has_rails_master_key=%s" % ("RAILS_MASTER_KEY=" in secrets_path.read_text()))
print("keys=" + ",".join(line.split("=", 1)[0] for line in lines))
