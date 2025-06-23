import duckdb


class S3CsvFileProcessor:
    def __init__(self, aws_access_key_id, aws_secret_access_key):
        self.aws_access_key_id = aws_access_key_id
        self.aws_secret_access_key = aws_secret_access_key
        self.conn = duckdb.connect()
        self.conn.execute(
            f"""
            CREATE OR REPLACE SECRET secret (
                TYPE s3,
                PROVIDER config,
                KEY_ID '{self.aws_access_key_id}',
                SECRET '{self.aws_secret_access_key}',
                REGION 'ap-southeast-2'
            )
            """
        )
        self.table_cleaning_rules = {
            "time_off_in_lieu": self._process_time_off_in_lieu,
            "timesheet": self._process_timesheet,
            "roster": self._process_roster,
            "dim_pay_period": self._process_dim_pay_period,
            "bonus": self._process_bonus,
            "employee_details": self._process_employee_details,
            "allowance": self._process_allowance,
            "employee_leave": self._process_employee_leave,
            "contract_details": self._process_contract_details,
            "junior_pay_rates": self._process_junior_pay_rates,
            "pay_rate_adjustments": self._process_pay_rate_adjustments,
            "minimum_pay_rates": self._process_minimum_pay_rates,
            "combined_holidays": self._process_combined_holidays,
            "super_guarantee_rates_formatted": self._process_super_guarantee_rates_formatted,
            "tax_rates": self._process_tax_rates,
            "past_payslips": self._process_past_payslips,
        }

    def _process_file(self, s3_raw_file_url):
        bucket_name = s3_raw_file_url.split("/")[2]
        table_name = s3_raw_file_url.split("/")[-1].split(".")[0]
        # Read the CSV file from S3
        self.conn.execute(
            f"CREATE OR REPLACE TABLE '{table_name}' AS SELECT DISTINCT * FROM read_csv_auto('{s3_raw_file_url}')"
        )
        cleaning_function = self._get_cleaning_function(table_name)
        cleaning_function()
        s3_processed_file_url = f"s3://{bucket_name}/processed/{table_name}.parquet"
        self._save_to_s3(table_name, s3_processed_file_url)
        return s3_processed_file_url

    def _get_cleaning_function(self, table_name):
        if table_name in self.table_cleaning_rules:
            return self.table_cleaning_rules.get(table_name)
        else:
            raise ValueError(f"No cleaning function defined for {table_name}")

    def _save_to_s3(self, table_name, s3_processed_file_url):
        self.conn.execute(
            f"""
            COPY {table_name}
            TO '{s3_processed_file_url}'
            (FORMAT 'parquet');
            """
        )

    def _process_time_off_in_lieu(self):
        pass

    def _process_timesheet(self):
        self.conn.execute("""
            ALTER TABLE timesheet
            RENAME COLUMN employee_code TO employee_id;
        """)

        # Convert start_time and end_time to string
        self.conn.execute("""
            CREATE OR REPLACE TABLE timesheet_str AS
            SELECT 
                timesheet_id,
                employee_id,
                timesheet_transaction_date,
                CAST(start_time AS VARCHAR) AS start_time,
                CAST(end_time AS VARCHAR) AS end_time,
                timesheet_transaction_hours,
                pay_period_id
            FROM timesheet;
        """)

        # Replace original table with transformed one
        self.conn.execute("DROP TABLE timesheet;")
        self.conn.execute("ALTER TABLE timesheet_str RENAME TO timesheet;")

    def _process_roster(self):
        pass

    def _process_dim_pay_period(self):
        pass

    def _process_bonus(self):
        pass

    def _process_employee_details(self):
        pass

    def _process_allowance(self):
        pass

    def _process_employee_leave(self):
        pass

    def _process_contract_details(self):
        pass

    def _process_junior_pay_rates(self):
        self.conn.execute(
            """
            ALTER TABLE junior_pay_rates
                RENAME COLUMN "Age" TO age;
            ALTER TABLE junior_pay_rates
                RENAME COLUMN "% of Adult Pay Rate" TO percent_of_adult_pay_rate;
            """
        )

    def _process_pay_rate_adjustments(self):
        self.conn.execute(
            """
            ALTER TABLE pay_rate_adjustments
                RENAME COLUMN "Rate Type" TO rate_type;
            ALTER TABLE pay_rate_adjustments
                RENAME COLUMN "Description" TO description;
            ALTER TABLE pay_rate_adjustments
                RENAME COLUMN "Rate Calculation" TO rate_calculation;
            """
        )

    def _process_minimum_pay_rates(self):
        pass

    def _process_combined_holidays(self):
        self.conn.execute(
            """
            ALTER TABLE combined_holidays
                RENAME COLUMN "Date" TO holiday_date;
            ALTER TABLE combined_holidays
                RENAME COLUMN "Holiday Name" TO holiday_name;
            ALTER TABLE combined_holidays
                RENAME COLUMN "Information" TO information;
            ALTER TABLE combined_holidays
                RENAME COLUMN "More information" TO more_information;
            ALTER TABLE combined_holidays
                RENAME COLUMN "Jurisdiction" TO jurisdiction;
            ALTER TABLE combined_holidays
                RENAME COLUMN "Day Of Week" TO day_of_week;
            """
        )

    def _process_super_guarantee_rates_formatted(self):
        self.conn.execute(
            """
            ALTER TABLE super_guarantee_rates_formatted
                RENAME COLUMN "Start Period" TO start_period;
            ALTER TABLE super_guarantee_rates_formatted
                RENAME COLUMN "End Period" TO end_period;
            ALTER TABLE super_guarantee_rates_formatted
                RENAME COLUMN "Super guarantee rate (charge percentage)" TO super_guarantee_rate_percentage;
            """
        )

    def _process_tax_rates(self):
        self.conn.execute(
            """
            ALTER TABLE tax_rates
                RENAME COLUMN "Taxable income" TO taxable_income;
            ALTER TABLE tax_rates
                RENAME COLUMN "Tax on this income" TO tax_on_this_income;
            ALTER TABLE tax_rates
                RENAME COLUMN "Year" TO year;
            ALTER TABLE tax_rates
                RENAME COLUMN "Note" TO note;
            ALTER TABLE tax_rates
                RENAME COLUMN "Start Range" TO start_range;
            ALTER TABLE tax_rates
                RENAME COLUMN "End Range" TO end_range;
            ALTER TABLE tax_rates
                RENAME COLUMN "Date Start" TO date_start;
            ALTER TABLE tax_rates
                RENAME COLUMN "Date End" TO date_end;
            ALTER TABLE tax_rates
                RENAME COLUMN "Fixed Tax" TO fixed_tax;
            ALTER TABLE tax_rates
                RENAME COLUMN "Cumulative Tax" TO cumulative_tax;
            """
        )

    def _process_past_payslips(self):
        pass
