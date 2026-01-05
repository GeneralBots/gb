#!/bin/bash

set -euo pipefail

LOCALES_DIR="${1:-locales}"
BASE_LOCALE="${2:-en}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ ! -d "$LOCALES_DIR" ]; then
    echo -e "${RED}Error: Locales directory not found: $LOCALES_DIR${NC}"
    exit 1
fi

if [ ! -d "$LOCALES_DIR/$BASE_LOCALE" ]; then
    echo -e "${RED}Error: Base locale not found: $LOCALES_DIR/$BASE_LOCALE${NC}"
    exit 1
fi

extract_keys() {
    local file="$1"
    grep -E '^[a-z][a-z0-9-]*\s*=' "$file" 2>/dev/null | cut -d'=' -f1 | tr -d ' ' | sort -u
}

count_keys() {
    local dir="$1"
    local count=0
    for file in "$dir"/*.ftl; do
        if [ -f "$file" ]; then
            local file_count
            file_count=$(extract_keys "$file" | wc -l)
            count=$((count + file_count))
        fi
    done
    echo "$count"
}

echo "========================================"
echo "  General Bots i18n Coverage Report"
echo "========================================"
echo ""

base_count=$(count_keys "$LOCALES_DIR/$BASE_LOCALE")
echo -e "Base locale: ${GREEN}$BASE_LOCALE${NC} ($base_count keys)"
echo ""

declare -A all_base_keys
for file in "$LOCALES_DIR/$BASE_LOCALE"/*.ftl; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        while IFS= read -r key; do
            all_base_keys["$filename:$key"]=1
        done < <(extract_keys "$file")
    fi
done

total_missing=0
total_extra=0

for locale_dir in "$LOCALES_DIR"/*/; do
    locale=$(basename "$locale_dir")

    if [ "$locale" = "$BASE_LOCALE" ]; then
        continue
    fi

    locale_count=$(count_keys "$locale_dir")

    if [ "$base_count" -gt 0 ]; then
        coverage=$((locale_count * 100 / base_count))
    else
        coverage=0
    fi

    if [ "$coverage" -ge 90 ]; then
        color=$GREEN
    elif [ "$coverage" -ge 50 ]; then
        color=$YELLOW
    else
        color=$RED
    fi

    echo -e "Locale: ${color}$locale${NC} - $locale_count/$base_count keys (${coverage}%)"

    missing_keys=()
    extra_keys=()

    for file in "$LOCALES_DIR/$BASE_LOCALE"/*.ftl; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            target_file="$locale_dir/$filename"

            if [ ! -f "$target_file" ]; then
                while IFS= read -r key; do
                    missing_keys+=("$filename: $key")
                done < <(extract_keys "$file")
            else
                while IFS= read -r key; do
                    if ! grep -q "^$key\s*=" "$target_file" 2>/dev/null; then
                        missing_keys+=("$filename: $key")
                    fi
                done < <(extract_keys "$file")

                while IFS= read -r key; do
                    if ! grep -q "^$key\s*=" "$file" 2>/dev/null; then
                        extra_keys+=("$filename: $key")
                    fi
                done < <(extract_keys "$target_file")
            fi
        fi
    done

    if [ ${#missing_keys[@]} -gt 0 ]; then
        echo -e "  ${RED}Missing keys (${#missing_keys[@]}):${NC}"
        for key in "${missing_keys[@]:0:10}"; do
            echo "    - $key"
        done
        if [ ${#missing_keys[@]} -gt 10 ]; then
            echo "    ... and $((${#missing_keys[@]} - 10)) more"
        fi
        total_missing=$((total_missing + ${#missing_keys[@]}))
    fi

    if [ ${#extra_keys[@]} -gt 0 ]; then
        echo -e "  ${YELLOW}Extra keys (${#extra_keys[@]}):${NC}"
        for key in "${extra_keys[@]:0:5}"; do
            echo "    - $key"
        done
        if [ ${#extra_keys[@]} -gt 5 ]; then
            echo "    ... and $((${#extra_keys[@]} - 5)) more"
        fi
        total_extra=$((total_extra + ${#extra_keys[@]}))
    fi

    echo ""
done

echo "========================================"
echo "  Summary"
echo "========================================"
echo "Base keys: $base_count"
echo -e "Total missing: ${RED}$total_missing${NC}"
echo -e "Total extra: ${YELLOW}$total_extra${NC}"

if [ "$total_missing" -eq 0 ] && [ "$total_extra" -eq 0 ]; then
    echo -e "${GREEN}All translations are complete!${NC}"
    exit 0
else
    exit 1
fi
