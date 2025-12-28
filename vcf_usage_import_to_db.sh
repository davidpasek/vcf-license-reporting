#!/bin/sh

MYSQL_BIN="/usr/local/bin/mysql"
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="3306"
MYSQL_USER="vcf"
MYSQL_PASS="vcf"
MYSQL_DB="vcf"
SCRIPT_DIR=$(dirname "$0")
VCF_USAGE_FILE="$SCRIPT_DIR/vcf_usage.tsv"

"$MYSQL_BIN" \
  --local-infile=1 \
  -h "$MYSQL_HOST" \
  -P "$MYSQL_PORT" \
  -u "$MYSQL_USER" \
  -p"$MYSQL_PASS" \
  "$MYSQL_DB" <<SQL
LOAD DATA LOCAL INFILE '${VCF_USAGE_FILE}'
IGNORE
INTO TABLE license_cpu_core_usage
CHARACTER SET utf8mb4
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
  \`Usage Meter Instance ID\`,
  \`Product\`,
  \`SKU\`,
  \`Usage Hour\`,
  \`License Key\`,
  \`Serial Number\`,
  \`Allocation Id\`,
  \`Quantity\`,
  \`Unit of Measurement\`
);
SHOW WARNINGS;
SELECT
  @@warning_count          AS skipped_rows;
SQL

