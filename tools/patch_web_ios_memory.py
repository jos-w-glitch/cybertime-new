#!/usr/bin/env python3
"""Lower Godot web WASM heap max so iOS Safari can finish starting after 100%."""

from __future__ import annotations

import sys
from pathlib import Path

# 512 MiB — low enough for iPhone, high enough for this 2D game.
HEAP_MAX_BYTES = 512 * 1024 * 1024
# WASM memory pages (64 KiB). Keep 3-byte LEB128 so section size stays valid.
# 8192 pages = 512 MiB → bytes 0x80 0xC0 0x00
HEAP_MAX_PAGES_LEB = bytes([0x80, 0xC0, 0x00])
# Official Godot template uses 32768 pages (2 GiB) → 0x80 0x80 0x02
STOCK_MAX_PAGES_LEB = bytes([0x80, 0x80, 0x02])


def patch_wasm(path: Path) -> bool:
	data = bytearray(path.read_bytes())
	# Memory section payload starts with: count=1, flags=has_max, initial, maximum
	# Observed: 01 01 80 04 80 80 02
	needle = bytes([0x01, 0x01, 0x80, 0x04]) + STOCK_MAX_PAGES_LEB
	replacement = bytes([0x01, 0x01, 0x80, 0x04]) + HEAP_MAX_PAGES_LEB
	count = data.count(needle)
	if count == 0:
		# Already patched?
		if data.count(bytes([0x01, 0x01, 0x80, 0x04]) + HEAP_MAX_PAGES_LEB):
			print(f"{path.name}: wasm already patched")
			return False
		raise SystemExit(f"{path.name}: memory-limits pattern not found")
	data = data.replace(needle, replacement, 1)
	path.write_bytes(data)
	print(f"{path.name}: wasm max heap -> {HEAP_MAX_BYTES // (1024 * 1024)} MiB")
	return True


def patch_js(path: Path) -> bool:
	text = path.read_text(encoding="utf-8", errors="ignore")
	old = "var getHeapMax=()=>2147483648;"
	new = f"var getHeapMax=()=>{HEAP_MAX_BYTES};"
	if new in text:
		print(f"{path.name}: js already patched")
		return False
	if old not in text:
		# Try alternate formatting
		alt = "getHeapMax=()=>2147483648"
		if alt not in text:
			raise SystemExit(f"{path.name}: getHeapMax pattern not found")
		text = text.replace(alt, f"getHeapMax=()=>{HEAP_MAX_BYTES}", 1)
	else:
		text = text.replace(old, new, 1)
	path.write_text(text, encoding="utf-8")
	print(f"{path.name}: getHeapMax -> {HEAP_MAX_BYTES // (1024 * 1024)} MiB")
	return True


def main() -> None:
	root = Path(sys.argv[1] if len(sys.argv) > 1 else "deploy-site/cybertime")
	patch_wasm(root / "index.wasm")
	patch_js(root / "index.js")


if __name__ == "__main__":
	main()
