from __future__ import annotations

import argparse
import json
import shutil
import sys
import venv
from pathlib import Path

from runtime_paths import (
    RUNTIME_CONTRACT_VERSION,
    build_runtime_manifest,
    ensure_runtime_root,
    get_current_platform_key,
    get_platform_key,
    get_runtime_env_dir,
    validate_runtime_contract,
    write_runtime_contract_files,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Prepare or scaffold the unified desktop runtime root under "
            "python_mediapipe/assets/runtimes/<platform>/"
        )
    )
    parser.add_argument("--platform", dest="platform_key", help="Target platform key (defaults to current host platform)")
    parser.add_argument("--mode", choices=["dev", "release"], default="dev")
    parser.add_argument(
        "--create-venv",
        action="store_true",
        help="Create a local Python venv inside the runtime root. This only supports the current host platform.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Remove and recreate the runtime-local venv if it already exists.",
    )
    parser.add_argument(
        "--validate",
        action="store_true",
        help="Validate the runtime contract after writing manifest/sentinel files.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit the result payload as JSON.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    current_platform_key = get_current_platform_key()
    requested_platform_key = args.platform_key or current_platform_key

    # Reject obviously invalid keys early.
    get_platform_key(*_split_platform_key_for_validation(requested_platform_key))

    warnings: list[str] = []
    notes: list[str] = []
    validation_status = "scaffolded"

    if requested_platform_key != current_platform_key:
        if args.create_venv:
            raise SystemExit(
                "Refusing to create a foreign-platform runtime venv on this host. "
                f"Current host platform is {current_platform_key}, requested {requested_platform_key}."
            )
        warnings.append(
            "Manifest/sentinel scaffolding only. Foreign-platform runtime preparation is not validated in this pass."
        )
    else:
        notes.append(f"Prepared on host platform {current_platform_key}.")

    runtime_root = ensure_runtime_root(requested_platform_key)
    runtime_env_dir = get_runtime_env_dir(runtime_root=runtime_root)

    if args.create_venv:
        if runtime_env_dir.exists() and args.force:
            shutil.rmtree(runtime_env_dir)
        if not runtime_env_dir.exists():
            venv.EnvBuilder(with_pip=True).create(runtime_env_dir)
        validation_status = "venv_created"
        notes.append(f"Created local runtime venv at {runtime_env_dir}.")
    else:
        warnings.append("Python dependency installation is not part of this foundation pass unless --create-venv is requested.")

    manifest = build_runtime_manifest(
        mode=args.mode,
        platform_key=requested_platform_key,
        validation_status=validation_status,
        preparation_warnings=warnings,
        notes=notes,
    )
    write_runtime_contract_files(manifest, runtime_root=runtime_root)

    errors = validate_runtime_contract(
        requested_platform_key,
        runtime_root=runtime_root,
        require_python=args.create_venv,
    ) if args.validate else []

    result = {
        "contract_version": RUNTIME_CONTRACT_VERSION,
        "platform_key": requested_platform_key,
        "runtime_root": str(runtime_root),
        "runtime_env_dir": str(runtime_env_dir),
        "mode": args.mode,
        "create_venv": args.create_venv,
        "validation_status": validation_status,
        "warnings": warnings,
        "notes": notes,
        "validation_errors": errors,
    }

    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(f"Prepared runtime contract scaffold at {runtime_root}")
        for warning in warnings:
            print(f"WARNING: {warning}")
        for note in notes:
            print(f"NOTE: {note}")
        if errors:
            print("Validation errors:")
            for error in errors:
                print(f"- {error}")

    return 1 if errors else 0


def _split_platform_key_for_validation(platform_key: str) -> tuple[str, str]:
    if "-" not in platform_key:
        raise SystemExit(f"Invalid platform key {platform_key!r}; expected values like linux-x64")
    os_name, arch = platform_key.split("-", 1)
    if os_name == "linux":
        system = "Linux"
    elif os_name == "macos":
        system = "Darwin"
    elif os_name == "windows":
        system = "Windows"
    else:
        system = os_name
    return system, arch


if __name__ == "__main__":
    sys.exit(main())
