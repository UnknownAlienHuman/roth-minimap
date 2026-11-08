#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = {
    "media/mask_square.tga": (256, 256),
    "media/RM_DIABLO_BORDER_512.tga": (512, 512),
    "media/RM_DIABLO_CHAR_512.tga": (512, 512),
    "media/RM_DIABLO_RUNES_512.tga": (512, 512),
    "media/RM_DIABLO_FIRE_GLOW_512.tga": (512, 512),
    "media/RM_VIGNETTE_SQUARE_512.tga": (512, 512),
    "media/RM_DIABLO_FIRE_ATLAS_512_HOLE_THIN.tga": (512, 512),
}


def read_tga(relative: str, expected_size: tuple[int, int]) -> tuple[bytes, bytes, int, int]:
    path = ROOT / relative
    data = path.read_bytes()
    assert len(data) >= 18, f"{relative}: truncated TGA header"

    id_length, color_map_type, image_type = struct.unpack_from("<BBB", data, 0)
    width, height = struct.unpack_from("<HH", data, 12)
    pixel_depth = data[16]
    descriptor = data[17]

    assert color_map_type == 0, f"{relative}: color-mapped TGA is unsupported"
    assert image_type == 2, f"{relative}: expected uncompressed true-color TGA, got type {image_type}"
    assert (width, height) == expected_size, (
        f"{relative}: expected {expected_size[0]}x{expected_size[1]}, got {width}x{height}"
    )
    assert pixel_depth == 32, f"{relative}: expected 32 bpp, got {pixel_depth}"
    assert descriptor & 0x0F == 8, f"{relative}: expected an 8-bit alpha channel"

    offset = 18 + id_length
    byte_count = width * height * 4
    pixels = data[offset : offset + byte_count]
    assert len(pixels) == byte_count, f"{relative}: truncated pixel data"

    alpha = pixels[3::4]
    assert max(alpha) > 0, f"{relative}: fully transparent"
    assert len(set(pixels)) > 1, f"{relative}: constant pixel data"
    return pixels, alpha, width, height


def alpha_at(alpha: bytes, width: int, x: int, y: int) -> int:
    return alpha[y * width + x]


def alpha_bounds(alpha: bytes, width: int, height: int, threshold: int = 8) -> tuple[int, int, int, int]:
    points = [
        (index % width, index // width)
        for index, value in enumerate(alpha)
        if value > threshold
    ]
    assert points, "alpha bounds: no visible pixels"
    xs = [point[0] for point in points]
    ys = [point[1] for point in points]
    return min(xs), min(ys), max(xs), max(ys)


def validate_mask(alpha: bytes, width: int, height: int) -> None:
    corners = (
        alpha_at(alpha, width, 0, 0),
        alpha_at(alpha, width, width - 1, 0),
        alpha_at(alpha, width, 0, height - 1),
        alpha_at(alpha, width, width - 1, height - 1),
    )
    center = alpha_at(alpha, width, width // 2, height // 2)
    assert max(corners) <= 16, f"mask_square.tga: opaque corner {corners}"
    assert center >= 240, f"mask_square.tga: transparent center {center}"
    assert min(alpha) < max(alpha), "mask_square.tga: alpha channel has no shape"


def validate_alpha_shape(relative: str, alpha: bytes) -> None:
    assert min(alpha) < max(alpha), f"{relative}: alpha channel is constant"


def validate_atlas(pixels: bytes, width: int, height: int) -> None:
    assert width % 4 == 0 and height % 4 == 0
    tile_width, tile_height = width // 4, height // 4
    hashes: set[str] = set()

    for row in range(4):
        for column in range(4):
            tile = bytearray()
            for y in range(row * tile_height, (row + 1) * tile_height):
                start = (y * width + column * tile_width) * 4
                tile.extend(pixels[start : start + tile_width * 4])

            frame_index = row * 4 + column
            frame_alpha = tile[3::4]
            assert max(frame_alpha) > 0, f"fire atlas: frame {frame_index} has no visible alpha"
            hashes.add(hashlib.sha256(tile).hexdigest())

    assert len(hashes) > 1, "fire atlas: all 16 frames are byte-identical"


def main() -> None:
    actual = {
        path.relative_to(ROOT).as_posix()
        for path in (ROOT / "media").glob("*.tga")
    }
    assert actual == set(EXPECTED), (
        f"unexpected TGA manifest: missing={sorted(set(EXPECTED) - actual)} "
        f"unexpected={sorted(actual - set(EXPECTED))}"
    )

    loaded: dict[str, tuple[bytes, bytes, int, int]] = {}
    for relative, size in EXPECTED.items():
        loaded[relative] = read_tga(relative, size)

    _, mask_alpha, mask_width, mask_height = loaded["media/mask_square.tga"]
    validate_mask(mask_alpha, mask_width, mask_height)

    for relative, (_, alpha, _, _) in loaded.items():
        if relative != "media/mask_square.tga":
            validate_alpha_shape(relative, alpha)

    atlas_pixels, _, atlas_width, atlas_height = loaded[
        "media/RM_DIABLO_FIRE_ATLAS_512_HOLE_THIN.tga"
    ]
    validate_atlas(atlas_pixels, atlas_width, atlas_height)

    for relative, (_, alpha, width, height) in loaded.items():
        visible = sum(value > 0 for value in alpha)
        center = alpha_at(alpha, width, width // 2, height // 2)
        bounds = alpha_bounds(alpha, width, height)
        print(
            f"{relative}: visible_alpha={visible}/{len(alpha)} "
            f"center_alpha={center} bounds={bounds}"
        )

    print("PASS: TGA manifest, dimensions, alpha channels, mask shape and thin fire atlas structure")


if __name__ == "__main__":
    main()
