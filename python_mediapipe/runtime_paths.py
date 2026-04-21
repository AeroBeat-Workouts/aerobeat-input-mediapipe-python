from pathlib import Path

PYTHON_MEDIAPIPE_DIR = Path(__file__).resolve().parent
ASSETS_DIR = PYTHON_MEDIAPIPE_DIR / "assets"
MODELS_DIR = ASSETS_DIR / "models"
VENV_DIR = ASSETS_DIR / "venv"

MODEL_FILENAMES = {
    0: "pose_landmarker_lite.task",
    1: "pose_landmarker_full.task",
    2: "pose_landmarker_heavy.task",
}


def get_model_filename(model_complexity: int) -> str:
    return MODEL_FILENAMES.get(model_complexity, MODEL_FILENAMES[0])


def get_model_path(model_complexity: int) -> Path:
    return MODELS_DIR / get_model_filename(model_complexity)


def ensure_asset_dirs() -> None:
    MODELS_DIR.mkdir(parents=True, exist_ok=True)
    VENV_DIR.mkdir(parents=True, exist_ok=True)
