#!/bin/sh
#
# make_vcf_usage.sh
#
# Consolidates VMware Usage Meter hourly TSV reports into a single output file.
#
# The script processes all *.tsv files in the specified data directory,
# extracts the "Usage Meter Instance ID" from each file header, and prepends
# it to every usage record in the output.
#
# Input files are expected to be TAB-delimited (TSV) with comment lines
# starting with '#'. Header rows and comment lines are skipped automatically.
# Empty fields in data rows are preserved.
#
# The output is a single consolidated TSV file with a unified header,
# suitable for further reporting or import into external tools.
#
# Requirements:
#   - POSIX-compliant /bin/sh
#   - awk
#
# Tested on: FreeBSD
#

SCRIPT_DIR=$(dirname "$0")
DATADIR="$SCRIPT_DIR/data"
OUTFILE="$SCRIPT_DIR/vcf_usage.tsv"

# Ensure the data directory exists
if [ ! -d "$DATADIR" ]; then
    echo "ERROR: Data directory does not exist: $DATADIR" >&2
    exit 1
fi

# Write output header
printf "| Usage Meter Instance ID |\t| Product |\t| SKU |\t| Usage Hour |\t| License Key |\t| Serial Number |\t| Allocation Id |\t| Quantity |\t| Unit of Measurement |\n" > "$OUTFILE"

ls -1 "$DATADIR"/*.tsv 2>/dev/null | while IFS= read -r file; do
    [ "$file" = "$OUTFILE" ] && continue

    echo "Processing file: $file"

    usage_meter_id=""

    # Extract Usage Meter Instance ID
    while IFS= read -r line; do
        case "$line" in
            "# Usage Meter Instance ID:"*)
                usage_meter_id=${line#*: }
                break
                ;;
        esac
    done < "$file"

    awk -F '\t' -v umid="$usage_meter_id" '
        # Skip comments
        /^#/ { next }

        # Skip header row
        $1 ~ /^Product/ { next }

        # Skip empty rows
        $1 == "" { next }

        {
            printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
               umid,
               $1,  # Product
               $2,  # SKU
               $3,  # Usage Hour
               $4,  # License Key
               $5,  # Serial Number
               $6,  # Allocation Id
               $7,  # Quantity
               $8   # Unit of Measurement
        }
    ' "$file" >> "$OUTFILE"

done

total_lines=$(wc -l < "$OUTFILE")
data_lines=$((total_lines - 1))

echo "Output file '$OUTFILE' contains $data_lines data lines."
