# VMware Cloud Foundation - Usage Meter - License Reporting

VMware VCF Usage Meters send data to https://vcf.broadcom.com/
This solution automatically downloads these data (Usage Metter reports) from https://vcf.broadcom.com/ and pump it into MySQL Database which is used as Grafana Datasource for data statistics visualization. 

## FreeBSD and Bourne Shell

The solution is developed and operated on FreeBSD leveraging standard Bourne Shell scripts merging the data and pumping them into MySQL Database.

## MySQL Server

The solution uses local installed **MySQL database** as a backend data store of **VCF License Usage over time**.

#### MySQL Configuration

You must have enable local_infile feature on MySQL Server configuration at /usr/local/etc/mysql/my.cnf

```ini
[mysqld]
local_infile                    = 1
log_error                       = /var/db/mysql/mysql.log
```

#### Database init
In file vcf_db_init.mysql are MySQL commands to create database "vcf" and user "vcf" with password "vcf".. You can apply it into MySQL by following command ...
```code
cat vcf_db_init.mysql | mysql -u root --password=''
```
Note 1: Root password to local MySQL is by default empty.

Note 2: Do not change DB name, DB user, and DB password, because solution expects these hard coded information. If you change it, you have to change it in the rest of scripts and various integrations. This constraint may be improved in the future by keeping MYSQL DB information in a dedicated secure file.

#### Database Schema init
In file "vcf_db_schema.mysql" is tested DB Structure. You can apply it into MySQL database "vcf" by following command ...
```code
export MYSQL_PWD='vcf'
cat vcf_db_schema.mysql | mysql -u vcf vcf -h localhost
unset MYSQL_PWD
```

#### Workflow to import usage data into Database
```code
./make_vcf_usage_tsv.sh
./vcf_usage_import_to_db.sh
```

### MySQL Queries

#### Count of records in database
```sql
SELECT count(*) 
FROM license_cpu_core_usage;
```

#### Count of records in database in particular date interval
```sql
SELECT COUNT(*)
FROM license_cpu_core_usage
WHERE `Usage Hour` >= '2025-12-01 00:00:00'
  AND `Usage Hour` <  '2025-12-10 00:00:00';
```

#### Sum of Quantity per Usage Hour
```sql
SELECT
  `Usage Hour`,
  SUM(`Quantity`) AS Q
FROM license_cpu_core_usage
GROUP BY `Usage Hour`
ORDER BY `Usage Hour`;
```

#### Sum of Quantity per Usage Hour - per Provider
```sql
SELECT
  l.`Usage Hour` AS time,
  CONCAT(p.provider_name) AS instance,
  SUM(l.`Quantity`) AS value
FROM license_cpu_core_usage l
LEFT JOIN usage_meter u
  ON u.usage_meter_id = l.`Usage Meter Instance ID`
LEFT JOIN provider p
  ON p.provider_id = u.provider_id
GROUP BY
  time,
  instance
ORDER BY
  time;
```

#### Sum of Quantity per Usage Hour - per Provider's Usage Meters
```sql
SELECT
  l.`Usage Hour` AS time,
  CONCAT(p.provider_name, '-', u.usage_meter_name) AS instance,
  SUM(l.`Quantity`) AS value
FROM license_cpu_core_usage l
LEFT JOIN usage_meter u
  ON u.usage_meter_id = l.`Usage Meter Instance ID`
LEFT JOIN provider p
  ON p.provider_id = u.provider_id
GROUP BY
  time,
  instance
ORDER BY
  time;
```

#### Sum of Quantity per Usage Hour - limited to date interval
```sql
SELECT
  `Usage Hour`,
  SUM(`Quantity`) AS Q
FROM license_cpu_core_usage
WHERE `Usage Hour` >= '2025-12-01 00:00:00'
  AND `Usage Hour` <  '2025-12-10 00:00:00'
GROUP BY `Usage Hour`
ORDER BY `Usage Hour`;
```

#### Duplicity of License Key within Usage Hours
```sql
SELECT
  `License Key`,
  `Usage Hour`,
  COUNT(`License Key`) AS COUNT
FROM license_cpu_core_usage
GROUP BY `License Key`, `Usage Hour`
HAVING COUNT(`License Key`) > 1
ORDER BY `License Key`, `Usage Hour`;
```

#### Wierd License Key - 00000-00000-00000-00000-00000
```sql
SELECT
  `Usage Meter Instance ID`,
  `License Key`,
  `Usage Hour`,
  SUM(`Quantity`) AS Q
FROM license_cpu_core_usage
WHERE `License Key`="00000-00000-00000-00000-00000"
GROUP BY `Usage Meter Instance ID`,`Usage Hour`
ORDER BY `Usage Hour`;
```

#### Count of records in database with Wierd License Key - 00000-00000-00000-00000-00000
```sql
SELECT count(*) from license_cpu_core_usage
WHERE `License Key`="00000-00000-00000-00000-00000";
