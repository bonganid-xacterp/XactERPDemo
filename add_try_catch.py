#!/usr/bin/env python3
"""
Script to add try-catch blocks to 4GL files with database operations.
This script finds database calls and wraps them with TRY-CATCH blocks that call utils_globals.show_sql_error().
"""

import os
import re
import sys
from pathlib import Path

def has_try_catch_nearby(lines, line_idx, search_range=10):
    """Check if there's already a TRY statement within search_range lines before."""
    start = max(0, line_idx - search_range)
    for i in range(start, line_idx):
        if re.search(r'^\s*TRY\s*$', lines[i], re.IGNORECASE):
            return True
    return False

def find_end_of_block(lines, start_idx, keywords):
    """Find the end of a database operation block (e.g., FOREACH...END FOREACH)."""
    depth = 1
    for i in range(start_idx + 1, len(lines)):
        line_upper = lines[i].strip().upper()
        if any(kw in line_upper for kw in keywords['start']):
            depth += 1
        if any(kw in line_upper for kw in keywords['end']):
            depth -= 1
            if depth == 0:
                return i
    return None

def wrap_with_try_catch(lines, start_idx, end_idx, function_name, error_msg):
    """Wrap lines from start_idx to end_idx with TRY-CATCH block."""
    indent = re.match(r'^(\s*)', lines[start_idx]).group(1)

    # Build the try-catch wrapper
    new_lines = []
    new_lines.append(f"{indent}TRY\n")
    for i in range(start_idx, end_idx + 1):
        # Add extra indent to wrapped content
        if lines[i].strip():  # Only indent non-empty lines
            new_lines.append(f"    {lines[i]}")
        else:
            new_lines.append(lines[i])
    new_lines.append(f"{indent}CATCH\n")
    new_lines.append(f"{indent}    CALL utils_globals.show_sql_error(\"{function_name}: {error_msg}\")\n")
    new_lines.append(f"{indent}END TRY\n")

    return new_lines

def process_4gl_file(filepath):
    """Process a single 4GL file to add try-catch blocks."""
    print(f"Processing: {filepath}")

    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()

    # Find current function name
    current_function = "unknown"
    modifications = []
    skip_until = -1

    for i, line in enumerate(lines):
        if i < skip_until:
            continue

        # Track function names
        func_match = re.search(r'^\s*(?:FUNCTION|PRIVATE\s+FUNCTION)\s+(\w+)', line, re.IGNORECASE)
        if func_match:
            current_function = func_match.group(1)

        # Skip lines already in TRY blocks
        if has_try_catch_nearby(lines, i, 15):
            continue

        # Look for database operations
        line_upper = line.strip().upper()

        # Pattern 1: Simple SELECT INTO
        if re.search(r'\bSELECT\b.*\bINTO\b.*\bFROM\b', line, re.IGNORECASE):
            if not has_try_catch_nearby(lines, i, 5):
                modifications.append({
                    'start': i,
                    'end': i,
                    'function': current_function,
                    'msg': 'Error executing SELECT'
                })

        # Pattern 2: INSERT statements
        elif re.search(r'^\s*INSERT\s+INTO\b', line, re.IGNORECASE):
            if not has_try_catch_nearby(lines, i, 5):
                modifications.append({
                    'start': i,
                    'end': i,
                    'function': current_function,
                    'msg': 'Error executing INSERT'
                })

        # Pattern 3: UPDATE statements
        elif re.search(r'^\s*UPDATE\s+\w+\s+SET\b', line, re.IGNORECASE):
            # Find end of UPDATE (WHERE clause or next statement)
            end = i
            for j in range(i + 1, min(i + 10, len(lines))):
                if re.search(r'^\s*\w+', lines[j]) and 'WHERE' not in lines[j].upper():
                    break
                end = j
            if not has_try_catch_nearby(lines, i, 5):
                modifications.append({
                    'start': i,
                    'end': end,
                    'function': current_function,
                    'msg': 'Error executing UPDATE'
                })

        # Pattern 4: DELETE statements
        elif re.search(r'^\s*DELETE\s+FROM\b', line, re.IGNORECASE):
            if not has_try_catch_nearby(lines, i, 5):
                modifications.append({
                    'start': i,
                    'end': i,
                    'function': current_function,
                    'msg': 'Error executing DELETE'
                })

        # Pattern 5: DECLARE CURSOR + FOREACH
        elif re.search(r'^\s*DECLARE\s+\w+\s+CURSOR\b', line, re.IGNORECASE):
            # Find the FOREACH and its END FOREACH
            foreach_start = None
            foreach_end = None
            for j in range(i, min(i + 20, len(lines))):
                if re.search(r'^\s*FOREACH\b', lines[j], re.IGNORECASE):
                    foreach_start = j
                    break

            if foreach_start:
                depth = 1
                for j in range(foreach_start + 1, len(lines)):
                    if re.search(r'^\s*FOREACH\b', lines[j], re.IGNORECASE):
                        depth += 1
                    if re.search(r'^\s*END\s+FOREACH\b', lines[j], re.IGNORECASE):
                        depth -= 1
                        if depth == 0:
                            foreach_end = j
                            break

            # Include CLOSE/FREE after FOREACH if present
            if foreach_end:
                for j in range(foreach_end + 1, min(foreach_end + 5, len(lines))):
                    if re.search(r'^\s*(CLOSE|FREE)\b', lines[j], re.IGNORECASE):
                        foreach_end = j
                    else:
                        break

            if foreach_end and not has_try_catch_nearby(lines, i, 5):
                modifications.append({
                    'start': i,
                    'end': foreach_end,
                    'function': current_function,
                    'msg': 'Error executing cursor operation'
                })
                skip_until = foreach_end + 1

    # Apply modifications in reverse order to maintain line numbers
    if modifications:
        # Remove duplicates and sort by start position (reverse)
        unique_mods = []
        seen_ranges = set()
        for mod in modifications:
            range_key = (mod['start'], mod['end'])
            if range_key not in seen_ranges:
                seen_ranges.add(range_key)
                unique_mods.append(mod)

        unique_mods.sort(key=lambda x: x['start'], reverse=True)

        # Apply each modification
        for mod in unique_mods:
            wrapped = wrap_with_try_catch(
                lines,
                mod['start'],
                mod['end'],
                mod['function'],
                mod['msg']
            )
            lines[mod['start']:mod['end']+1] = wrapped

        # Write back
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(lines)

        print(f"  ✓ Added {len(unique_mods)} try-catch blocks")
        return True
    else:
        print(f"  - No changes needed (already has try-catch or no DB operations)")
        return False

def main():
    """Main function to process all 4GL files."""
    base_dir = Path(__file__).parent / 'src'

    # Modules to process
    modules = ['sy', 'st', 'pu', 'sa', 'cl', 'dl', 'wh', 'wb', 'gl', 'payt', 'utils', 'app']

    # Files already completed
    completed_files = ['sy101_user.4gl', 'st101_mast.4gl']

    total_processed = 0
    total_modified = 0

    for module in modules:
        module_dir = base_dir / module
        if not module_dir.exists():
            continue

        print(f"\n{'='*60}")
        print(f"Processing module: {module}")
        print(f"{'='*60}")

        for filepath in sorted(module_dir.glob('*.4gl')):
            if filepath.name in completed_files:
                print(f"Skipping (already done): {filepath.name}")
                continue

            total_processed += 1
            if process_4gl_file(filepath):
                total_modified += 1

    print(f"\n{'='*60}")
    print(f"Summary:")
    print(f"  Total files processed: {total_processed}")
    print(f"  Files modified: {total_modified}")
    print(f"{'='*60}")

if __name__ == '__main__':
    main()
