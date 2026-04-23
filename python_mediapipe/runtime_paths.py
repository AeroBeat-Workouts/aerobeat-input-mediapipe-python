from __future__ import annotations

import getpass
import hashlib
import json
import platform
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

PYTHON_MEDIAPIPE_DIR = Path(__file__).resolve().parent
REPO_ROOT = PYTHON_MEDIAPIPE_DIR.parent
ASSETS_DIR = PYTHON_MEDIAPIPE_DIR / "assets"
MODELS_DIR = ASSETS_DIR / "models"
RUNTIMES_DIR = ASSETS_DIR / "runtimes"
LEGACY_VENV_DIR = ASSETS_DIR / "venv"

RUNTIME_ENV_DIRNAME = "venv"
RUNTIME_MANIFEST_FILENAME = "runtime-manifest.json"
RUNTIME_SENTINEL_FILENAME = ".runtime-ready"
RUNTIME_CONTRACT_VERSION = "unified-desktop-runtime-v1"
RUNTIME_SCHEMA_VERSION = 1
RUNTIME_MODES = {"dev", "release"}

MODEL_FILENAMES = {
    0: "pose_landmarker_lite.task",
    1: "pose_landmarker_full.task",
    2: "pose_landmarker_heavy.task",
}

SUPPORTED_PLATFORM_KEYS = (
    "linux-x64",
    "macos-x64",
    "windows-x64",
)


def get_model_filename(model_complexity: int) -> str:
    return MODEL_FILENAMES.get(model_complexity, MODEL_FILENAMES[0])


def get_model_path(model_complexity: int) -> Path:
    return MODELS_DIR / get_model_filename(model_complexity)


def normalize_arch(machine: str | None = None) -> str:
    raw = (machine or platform.machine() or "").strip().lower()
    if raw in {"x86_64", "amd64", "x64"}:
        return "x64"
    if raw in {"arm64", "aarch64"}:
        return "arm64"
    if raw in {"x86", "i386", "i686"}:
        return "x86"
    return raw or "unknown"


def get_platform_key(system: str | None = None, machine: str | None = None) -> str:
    os_name = (system or platform.system() or "").strip().lower()
    arch = normalize_arch(machine)

    if os_name == "linux":
        os_key = "linux"
    elif os_name == "darwin":
        os_key = "macos"
    elif os_name == "windows":
        os_key = "windows"
    else:
        raise ValueError(f"Unsupported desktop platform: {system or platform.system()!r}")

    platform_key = f"{os_key}-{arch}"
    if platform_key not in SUPPORTED_PLATFORM_KEYS:
        raise ValueError(
            f"Unsupported desktop runtime platform key: {platform_key!r}. "
            f"Supported keys: {', '.join(SUPPORTED_PLATFORM_KEYS)}"
        )
    return platform_key


def get_current_platform_key() -> str:
    return get_platform_key()


def get_runtime_root(platform_key: str | None = None) -> Path:
    return RUNTIMES_DIR / (platform_key or get_current_platform_key())


def get_runtime_env_dir(platform_key: str | None = None, runtime_root: Path | None = None) -> Path:
    root = runtime_root or get_runtime_root(platform_key)
    return root / RUNTIME_ENV_DIRNAME


def get_runtime_python_path(platform_key: str | None = None, runtime_root: Path | None = None) -> Path:
    root = runtime_root or get_runtime_root(platform_key)
    key = platform_key or root.name
    if key.startswith("windows-"):
        return root / RUNTIME_ENV_DIRNAME / "Scripts" / "python.exe"
    return root / RUNTIME_ENV_DIRNAME / "bin" / "python"


def get_runtime_manifest_path(platform_key: str | None = None, runtime_root: Path | None = None) -> Path:
    root = runtime_root or get_runtime_root(platform_key)
    return root / RUNTIME_MANIFEST_FILENAME


def get_runtime_sentinel_path(platform_key: str | None = None, runtime_root: Path | None = None) -> Path:
    root = runtime_root or get_runtime_root(platform_key)
    return root / RUNTIME_SENTINEL_FILENAME


def get_runtime_entrypoint_path() -> Path:
    return PYTHON_MEDIAPIPE_DIR / "main.py"


def get_runtime_entrypoint_repo_relative() -> str:
    return str(get_runtime_entrypoint_path().relative_to(REPO_ROOT))


def get_runtime_python_relpath(platform_key: str) -> str:
    return str(get_runtime_python_path(platform_key=platform_key).relative_to(get_runtime_root(platform_key)))


def get_requirements_path() -> Path:
    return PYTHON_MEDIAPIPE_DIR / "requirements.txt"


def compute_requirements_hash() -> str:
    requirements_path = get_requirements_path()
    return hashlib.sha256(requirements_path.read_bytes()).hexdigest()


def get_model_inventory() -> list[dict[str, Any]]:
    inventory: list[dict[str, Any]] = []
    for name in sorted(MODEL_FILENAMES.values()):
        path = MODELS_DIR / name
        inventory.append(
            {
                "filename": name,
                "relative_path": str(path.relative_to(REPO_ROOT)),
                "exists": path.exists(),
                "size_bytes": path.stat().st_size if path.exists() else None,
            }
        )
    return inventory


def build_runtime_manifest(
    mode: str = "dev",
    *,
    platform_key: str | None = None,
    validation_status: str = "scaffolded",
    preparation_warnings: list[str] | None = None,
    notes: list[str] | None = None,
    prepared_by: str | None = None,
) -> dict[str, Any]:
    if mode not in RUNTIME_MODES:
        raise ValueError(f"Unsupported runtime mode: {mode!r}")

    resolved_platform_key = platform_key or get_current_platform_key()
    os_family, arch = resolved_platform_key.split("-", 1)

    return {
        "contract_version": RUNTIME_CONTRACT_VERSION,
        "schema_version": RUNTIME_SCHEMA_VERSION,
        "mode": mode,
        "platform_key": resolved_platform_key,
        "os_family": os_family,
        "arch": arch,
        "python_version": platform.python_version(),
        "entrypoint": get_runtime_entrypoint_repo_relative(),
        "python_executable": get_runtime_python_relpath(resolved_platform_key),
        "requirements_hash": compute_requirements_hash(),
        "prepared_at": datetime.now(timezone.utc).isoformat(),
        "prepared_by": prepared_by or getpass.getuser(),
        "model_assets": get_model_inventory(),
        "validation_status": validation_status,
        "preparation_warnings": preparation_warnings or [],
        "notes": notes or [],
    }


def ensure_asset_dirs() -> None:
    MODELS_DIR.mkdir(parents=True, exist_ok=True)
    RUNTIMES_DIR.mkdir(parents=True, exist_ok=True)


def ensure_runtime_root(platform_key: str | None = None) -> Path:
    ensure_asset_dirs()
    runtime_root = get_runtime_root(platform_key)
    runtime_root.mkdir(parents=True, exist_ok=True)
    return runtime_root


def write_runtime_contract_files(
    manifest: dict[str, Any],
    *,
    platform_key: str | None = None,
    runtime_root: Path | None = None,
) -> Path:
    resolved_root = runtime_root or ensure_runtime_root(platform_key or manifest.get("platform_key"))
    manifest_path = get_runtime_manifest_path(runtime_root=resolved_root)
    sentinel_path = get_runtime_sentinel_path(runtime_root=resolved_root)

    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    sentinel_payload = {
        "contract_version": manifest.get("contract_version", RUNTIME_CONTRACT_VERSION),
        "platform_key": manifest.get("platform_key", resolved_root.name),
        "mode": manifest.get("mode"),
        "validation_status": manifest.get("validation_status"),
    }
    sentinel_path.write_text(json.dumps(sentinel_payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return resolved_root


def load_runtime_manifest(platform_key: str | None = None, runtime_root: Path | None = None) -> dict[str, Any]:
    manifest_path = get_runtime_manifest_path(platform_key=platform_key, runtime_root=runtime_root)
    return json.loads(manifest_path.read_text(encoding="utf-8"))


def validate_runtime_contract(
    platform_key: str | None = None,
    *,
    runtime_root: Path | None = None,
    require_python: bool = False,
) -> list[str]:
    resolved_root = runtime_root or get_runtime_root(platform_key)
    expected_platform_key = platform_key or resolved_root.name
    errors: list[str] = []

    manifest_path = get_runtime_manifest_path(runtime_root=resolved_root)
    sentinel_path = get_runtime_sentinel_path(runtime_root=resolved_root)

    if not resolved_root.exists():
        errors.append(f"Runtime root is missing: {resolved_root}")
        return errors

    if not manifest_path.exists():
        errors.append(f"Runtime manifest is missing: {manifest_path}")
    if not sentinel_path.exists():
        errors.append(f"Runtime sentinel is missing: {sentinel_path}")

    if errors:
        return errors

    manifest = load_runtime_manifest(runtime_root=resolved_root)

    if manifest.get("contract_version") != RUNTIME_CONTRACT_VERSION:
        errors.append(
            "Runtime contract_version mismatch: "
            f"expected {RUNTIME_CONTRACT_VERSION!r}, got {manifest.get('contract_version')!r}"
        )

    if manifest.get("schema_version") != RUNTIME_SCHEMA_VERSION:
        errors.append(
            "Runtime schema_version mismatch: "
            f"expected {RUNTIME_SCHEMA_VERSION!r}, got {manifest.get('schema_version')!r}"
        )

    if manifest.get("platform_key") != expected_platform_key:
        errors.append(
            "Runtime platform_key mismatch: "
            f"expected {expected_platform_key!r}, got {manifest.get('platform_key')!r}"
        )

    mode = manifest.get("mode")
    if mode not in RUNTIME_MODES:
        errors.append(f"Runtime mode must be one of {sorted(RUNTIME_MODES)}, got {mode!r}")

    if manifest.get("requirements_hash") != compute_requirements_hash():
        errors.append("Runtime requirements_hash does not match python_mediapipe/requirements.txt")

    if manifest.get("entrypoint") != get_runtime_entrypoint_repo_relative():
        errors.append(
            "Runtime entrypoint mismatch: "
            f"expected {get_runtime_entrypoint_repo_relative()!r}, got {manifest.get('entrypoint')!r}"
        )

    python_executable = manifest.get("python_executable")
    if not python_executable:
        errors.append("Runtime manifest missing python_executable")
    elif require_python and not (resolved_root / python_executable).exists():
        errors.append(f"Runtime python executable is missing: {resolved_root / python_executable}")

    model_assets = manifest.get("model_assets")
    if not isinstance(model_assets, list) or not model_assets:
        errors.append("Runtime manifest missing model_assets inventory")
    else:
        for model in model_assets:
            relative_path = model.get("relative_path")
            if not relative_path:
                errors.append(f"Runtime model entry missing relative_path: {model}")
                continue
            model_path = REPO_ROOT / relative_path
            if not model_path.exists():
                errors.append(f"Required model asset is missing: {model_path}")

    return errors
