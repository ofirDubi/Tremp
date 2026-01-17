"""
Startup checks for Tremp server.
Verifies that required data files are present before starting.
"""

import os
import sys

# Required GTFS files for the app to function
REQUIRED_GTFS_FILES = [
    "stops.txt",
    "stop_times.txt",
    "trips.txt",
    "routes.txt",
    "calendar.txt",
    "shapes.txt"
]

def get_paths():
    """Get paths relative to this file's location."""
    gtfs_parser_folder = os.path.dirname(os.path.abspath(__file__))
    master_folder = os.path.dirname(gtfs_parser_folder)

    return {
        "gtfs_folder": os.path.join(master_folder, "is_gtfs"),
        "valhalla_tiles": os.path.join(master_folder, "valhalla", "custom_files", "valhalla_tiles.tar"),
        "artifacts_folder": os.path.join(gtfs_parser_folder, "artifacts"),
        "tlv_timetable": os.path.join(gtfs_parser_folder, "artifacts", "tlv_timetable_obj.obj"),
    }


def check_gtfs_files(paths, verbose=True):
    """Check if required GTFS files are present."""
    gtfs_folder = paths["gtfs_folder"]

    if not os.path.isdir(gtfs_folder):
        if verbose:
            print(f"[-] ERROR: GTFS folder not found: {gtfs_folder}")
        return False, f"GTFS folder not found: {gtfs_folder}"

    missing_files = []
    for filename in REQUIRED_GTFS_FILES:
        filepath = os.path.join(gtfs_folder, filename)
        if not os.path.isfile(filepath):
            missing_files.append(filename)

    if missing_files:
        if verbose:
            print(f"[-] ERROR: Missing GTFS files: {', '.join(missing_files)}")
        return False, f"Missing GTFS files: {', '.join(missing_files)}"

    if verbose:
        print(f"[+] GTFS files OK: {gtfs_folder}")
    return True, None


def check_valhalla_tiles(paths, verbose=True):
    """Check if Valhalla tiles are present."""
    valhalla_tiles = paths["valhalla_tiles"]

    if not os.path.isfile(valhalla_tiles):
        if verbose:
            print(f"[-] ERROR: Valhalla tiles not found: {valhalla_tiles}")
        return False, f"Valhalla tiles not found: {valhalla_tiles}"

    # Check file size (should be > 100MB for Israel tiles)
    size_mb = os.path.getsize(valhalla_tiles) / (1024 * 1024)
    if size_mb < 10:
        if verbose:
            print(f"[-] WARNING: Valhalla tiles seem too small ({size_mb:.1f}MB): {valhalla_tiles}")
        return False, f"Valhalla tiles seem too small ({size_mb:.1f}MB)"

    if verbose:
        print(f"[+] Valhalla tiles OK ({size_mb:.1f}MB): {valhalla_tiles}")
    return True, None


def check_cached_artifacts(paths, verbose=True):
    """Check if cached timetable artifacts exist (optional but speeds up startup)."""
    tlv_timetable = paths["tlv_timetable"]

    if os.path.isfile(tlv_timetable):
        size_mb = os.path.getsize(tlv_timetable) / (1024 * 1024)
        if verbose:
            print(f"[+] Cached timetable found ({size_mb:.1f}MB): {tlv_timetable}")
        return True, None
    else:
        if verbose:
            print(f"[!] WARNING: No cached timetable found. First startup will be slow.")
            print(f"    Expected location: {tlv_timetable}")
        return False, "No cached timetable (first startup will be slow)"


def run_startup_checks(bypass=False, verbose=True):
    """
    Run all startup checks.

    Args:
        bypass: If True, only warn about missing files but don't exit
        verbose: If True, print status messages

    Returns:
        True if all checks pass (or bypass=True), False otherwise
    """
    paths = get_paths()
    errors = []
    warnings = []

    if verbose:
        print("\n" + "="*60)
        print("TREMP SERVER STARTUP CHECKS")
        print("="*60)

    # Check GTFS files (required)
    ok, error = check_gtfs_files(paths, verbose)
    if not ok:
        errors.append(error)

    # Check Valhalla tiles (required for routing)
    ok, error = check_valhalla_tiles(paths, verbose)
    if not ok:
        errors.append(error)

    # Check cached artifacts (optional but recommended)
    ok, warning = check_cached_artifacts(paths, verbose)
    if not ok:
        warnings.append(warning)

    if verbose:
        print("="*60)

    if errors:
        if verbose:
            print(f"\n[-] STARTUP BLOCKED: {len(errors)} critical error(s)")
            for err in errors:
                print(f"    - {err}")
            print("\nTo bypass these checks, use --bypass-checks flag")
            print("="*60 + "\n")

        if bypass:
            if verbose:
                print("[!] BYPASS MODE: Continuing despite errors...")
            return True
        return False

    if warnings and verbose:
        print(f"\n[!] {len(warnings)} warning(s) (non-blocking)")

    if verbose:
        print("[+] All startup checks passed!")
        print("="*60 + "\n")

    return True


def parse_args_for_bypass():
    """Check if --bypass-checks flag is present in sys.argv."""
    return "--bypass-checks" in sys.argv


if __name__ == "__main__":
    # Run checks when executed directly
    bypass = parse_args_for_bypass()
    success = run_startup_checks(bypass=bypass)
    sys.exit(0 if success else 1)
