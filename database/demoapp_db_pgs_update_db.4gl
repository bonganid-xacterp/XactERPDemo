#+ Database update script for PostgreSQL 8.4 and higher
#+
#+ Note: This script is a helper script to update database schema
#+       Adapt it to fit your needs

MAIN
    DATABASE demoapp_db

    CALL db_drop_constraints()
    CALL db_drop_indexes()
    CALL db_drop_tables()
    CALL db_add_tables()
    CALL db_add_indexes()
    CALL db_add_constraints()
END MAIN

#+ Drop modified or removed tables from database. A backup of the table is made
#+ and table data is saved in the backup table.
FUNCTION db_drop_tables()

    WHENEVER ERROR CONTINUE
    EXECUTE IMMEDIATE "DROP TABLE cl30_trans_backup"
    WHENEVER ERROR STOP
    EXECUTE IMMEDIATE "CREATE TABLE cl30_trans_backup (
        id BIGSERIAL NOT NULL, 
        acc_code VARCHAR(20) NOT NULL, 
        doc_no VARCHAR(20) NOT NULL, 
        trans_date DATE NOT NULL, 
        doc_type VARCHAR(10) NOT NULL, 
        gross_val DECIMAL(12,2) NOT NULL, 
        vat DECIMAL(12,2) NOT NULL, 
        notes TEXT)"
    EXECUTE IMMEDIATE "INSERT INTO cl30_trans_backup SELECT * FROM cl30_trans"
    EXECUTE IMMEDIATE "DROP TABLE cl30_trans"

END FUNCTION

#+ Create new and modified tables in database. Backup data is inserted into them
#+ if available.
FUNCTION db_add_tables()
    WHENEVER ERROR STOP


    EXECUTE IMMEDIATE "CREATE TABLE cl30_trans (
        id BIGSERIAL NOT NULL,
        acc_code VARCHAR(20) NOT NULL,
        doc_no VARCHAR(20) NOT NULL,
        trans_date DATE NOT NULL,
        doc_type VARCHAR(10) NOT NULL,
        gross_val DECIMAL(12,2) NOT NULL,
        vat DECIMAL(12,2) NOT NULL,
        notes TEXT)"
    EXECUTE IMMEDIATE "INSERT INTO cl30_trans(id, acc_code, doc_no, trans_date, doc_type, gross_val, vat, notes)
        SELECT id, acc_code, doc_no, trans_date, doc_type, gross_val, vat, notes
            FROM cl30_trans_backup"

END FUNCTION

#+ Drop removed and modified constraints and also constraints from modified tables.
FUNCTION db_drop_constraints()
    WHENEVER ERROR STOP

    EXECUTE IMMEDIATE "ALTER TABLE cl30_trans DROP CONSTRAINT cl30_trans_acc_code_fkey"

END FUNCTION

#+ Add constraints for all tables.
FUNCTION db_add_constraints()
    WHENEVER ERROR STOP

    EXECUTE IMMEDIATE "ALTER TABLE cl30_trans ADD CONSTRAINT cl30_trans_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE cl30_trans ADD CONSTRAINT cl30_trans_acc_code_fkey
        FOREIGN KEY (acc_code)
        REFERENCES cl01_mast (acc_code)"

END FUNCTION

#+ Drop removed and modified indexes.
FUNCTION db_drop_indexes()
    WHENEVER ERROR STOP

    EXECUTE IMMEDIATE "DROP INDEX dl30_idx_acc_date"
    EXECUTE IMMEDIATE "DROP INDEX st30_idx_code_date"

END FUNCTION

#+ Add indexes for all tables.
FUNCTION db_add_indexes()
    WHENEVER ERROR STOP
    
    EXECUTE IMMEDIATE "CREATE INDEX cl30_idx_acc_trans_date ON cl30_trans(acc_code)"
    EXECUTE IMMEDIATE "CREATE INDEX dl30_idx_acc_trans_date ON dl30_trans(acc_code)"
    EXECUTE IMMEDIATE "CREATE INDEX st30_idx_code_trans_date ON st30_trans(stock_code)"

END FUNCTION


