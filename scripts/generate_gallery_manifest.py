#!/usr/bin/env python3
"""Generate the image manifest consumed by the SKLA Beroe gallery."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / "assets" / "gallery" / "gallery-manifest.json"
SUPPORTED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}

ALBUMS = (
    {
        "id": "kids-athletics",
        "title": "Детска атлетика",
        "subtitle": "Моменти от тренировките",
        "folder": Path("assets/gallery/kids-athletics"),
        "preferred_cover": "kids-03.jpg",
    },
    {
        "id": "training-process",
        "title": "Тренировъчен процес",
        "subtitle": "Подготовка и развитие на нашите атлети",
        "folder": Path("assets/gallery/Тренировъчен процес"),
        "preferred_cover": "training-01.jpg",
    },
    {
        "id": "competitions",
        "title": "Състезания",
        "subtitle": "Моменти от състезателния сезон",
        "folder": Path("assets/gallery/competitions"),
        "preferred_cover": "competition-01.jpg",
    },
    {
        "id": "kids-day",
        "title": "Клубен живот",
        "subtitle": "Събития и моменти от живота на клуба",
        "folder": Path("assets/gallery/club-life"),
        "preferred_cover": "club-01.jpg",
    },
)


def natural_sort_key(path: Path) -> list[object]:
    """Sort filenames case-insensitively while keeping numeric order intuitive."""
    return [
        int(part) if part.isdigit() else part
        for part in re.split(r"(\d+)", path.name.casefold())
    ]


def public_path(path: Path) -> str:
    """Return a browser-friendly path while preserving the original filename."""
    return f"./{path.relative_to(ROOT).as_posix()}"


def scan_album(album: dict[str, object]) -> dict[str, object]:
    folder = ROOT / album["folder"]

    if not folder.is_dir():
        raise FileNotFoundError(f"Gallery folder does not exist: {folder}")

    image_files = sorted(
        (
            path
            for path in folder.iterdir()
            if path.is_file() and path.suffix.casefold() in SUPPORTED_EXTENSIONS
        ),
        key=natural_sort_key,
    )

    if not image_files:
        raise RuntimeError(f"Gallery folder contains no supported images: {folder}")

    preferred_cover = folder / str(album["preferred_cover"])
    cover = preferred_cover if preferred_cover in image_files else image_files[0]

    return {
        "id": album["id"],
        "title": album["title"],
        "subtitle": album["subtitle"],
        "cover": public_path(cover),
        "images": [public_path(path) for path in image_files],
    }


def generate_manifest(output: Path) -> dict[str, object]:
    manifest = {
        "version": 1,
        "albums": [scan_album(album) for album in ALBUMS],
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return manifest


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=f"Manifest destination (default: {DEFAULT_OUTPUT})",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    output = args.output if args.output.is_absolute() else ROOT / args.output
    manifest = generate_manifest(output.resolve())
    counts = ", ".join(
        f"{album['id']}={len(album['images'])}" for album in manifest["albums"]
    )
    print(f"Generated {output.resolve()} ({counts})")


if __name__ == "__main__":
    main()
