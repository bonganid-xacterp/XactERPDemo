#!/usr/bin/env python3
"""
Script to add TRY-CATCH error handling to Genero 4GL files
This script identifies SQL operations and wraps them in TRY-CATCH blocks
"""

import re
import os
import sys

def has_try_catch_before(lines, start_idx, lookback=10):
    """Check if there's already a TRY statement before this line"""
    search_start = max(0, start_idx - lookback)
    for i in range(start_idx - 1, search_start, -1):
        line = lines[i].strip().upper()
        if line.startswith('TRY'):
            return True
        if line.startswith('FUNCTION') or line.startswith('END '):
            return False
    return False

def add_error_handling(file_path):
    """Add TRY-CATCH blocks around SQL statements in a 4GL file"""

    print(f"Processing: {file_path}")

    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # SQL keywords that need error handling
    sql_keywords = [
        r'^\s*(SELECT|INSERT|UPDATE|DELETE|PREPARE|DECLARE|OPEN|FETCH|EXECUTE)\s+',
        r'^\s*FOREACH\s+',
    ]

    modified = False
    new_lines = []
    i = 0

    while i < len(lines):
        line = lines[i]
        line_upper = line.strip().upper()

        # Check if this is an SQL statement that needs protection
        is_sql = any(re.match(pattern, line_upper) for pattern in sql_keywords)

        if is_sql and not has_try_catch_before(lines, i):
            # Check if already in TRY block
            if not any('TRY' in lines[j].upper() for j in range(max(0, i-5), i)):
                # Add TRY before the SQL statement
                indent = len(line) - len(line.lstrip())
                indent_str = ' ' * indent

                new_lines.append(f"{indent_str}TRY\n")
                new_lines.append(line)

                # Look ahead to find the end of the SQL block
                j = i + 1
                while j < len(lines):
                    next_line = lines[j].strip().upper()
                    new_lines.append(lines[j])

                    # End of SQL block indicators
                    if (next_line.startswith('CATCH') or
                        next_line.startswith('END TRY') or
                        next_line.startswith('IF ') or
                        next_line.startswith('CALL ') or
                        (next_line and not next_line.startswith('FROM') and
                         not next_line.startswith('WHERE') and
                         not next_line.startswith('ORDER') and
                         not next_line.startswith('INTO') and
                         not next_line.startswith('VALUES') and
                         not next_line.startswith('SET') and
                         not next_line.startswith('GROUP') and
                         not next_line.startswith('HAVING') and
                         not next_line.startswith('LIMIT') and
                         not next_line.startswith('USING') and
                         not next_line.startswith('FOR') and
                         not next_line.startswith('CURSOR') and
                         not next_line.startswith('--') and
                         not next_line.startswith('AND') and
                         not next_line.startswith('OR'))):

                        # Add CATCH block
                        new_lines.append(f"{indent_str}CATCH\n")
                        new_lines.append(f"{indent_str}    CALL utils_globals.show_sql_error('Database error: ' || SQLERRMESSAGE)\n")
                        new_lines.append(f"{indent_str}END TRY\n")
                        modified = True
                        break
                    j += 1

                i = j
                continue

        new_lines.append(line)
        i += 1

    if modified:
        # Backup original file
        backup_path = file_path + '.bak'
        with open(backup_path, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        print(f"  Created backup: {backup_path}")

        # Write modified content
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        print(f"  ✓ Added error handling")
    else:
        print(f"  No changes needed")

    return modified

def main():
    """Main function"""
    if len(sys.argv) < 2:
        print("Usage: python add_error_handling.py <file.4gl>")
        print("   or: python add_error_handling.py <directory>")
        sys.exit(1)

    target = sys.argv[1]

    if os.path.isfile(target):
        add_error_handling(target)
    elif os.path.isdir(target):
        count = 0
        for root, dirs, files in os.walk(target):
            for file in files:
                if file.endswith('.4gl'):
                    file_path = os.path.join(root, file)
                    if add_error_handling(file_path):
                        count += 1
        print(f"\nProcessed {count} files with modifications")
    else:
        print(f"Error: {target} is not a valid file or directory")
        sys.exit(1)

if __name__ == '__main__':
    main()
