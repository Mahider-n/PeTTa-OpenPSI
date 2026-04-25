import os
from pathlib import Path

from dotenv import load_dotenv


OPENCLAW_DIR = Path(__file__).resolve().parent
ENV_PATH = OPENCLAW_DIR / ".env"

load_dotenv(dotenv_path=ENV_PATH, override=False)


def get_env(name: str, default: str | None = None) -> str | None:
    return os.getenv(name, default)
