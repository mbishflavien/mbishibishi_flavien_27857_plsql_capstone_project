import oracledb
import os

# -------- CONFIG --------
INSTANT_CLIENT_DIR = r"C:\Users\Fujitsu\Downloads\instantclient_21_19"
DB_USER = "careconnect"
DB_PASS = "carecapstone"
DB_DSN = "localhost:1521/ORCLPDB"
# ------------------------

def test_connection():
    """Test basic connection"""
    print("=" * 60)
    print("CARECONNECT DIAGNOSTIC TOOL")
    print("=" * 60)
    
    try:
        # Initialize Oracle client
        if INSTANT_CLIENT_DIR and os.path.exists(INSTANT_CLIENT_DIR):
            print(f"✓ Oracle Instant Client path found: {INSTANT_CLIENT_DIR}")
            oracledb.init_oracle_client(lib_dir=INSTANT_CLIENT_DIR)
        else:
            print(f"✗ Oracle Instant Client path not found: {INSTANT_CLIENT_DIR}")
            print("  Please update INSTANT_CLIENT_DIR in the script")
            return False
    except Exception as e:
        print(f"⚠ Oracle client initialization: {e}")
    
    # Test connection
    try:
        print("\nTesting database connection...")
        conn = oracledb.connect(user=DB_USER, password=DB_PASS, dsn=DB_DSN)
        print(f"✓ Connected to {DB_DSN} as {DB_USER}")
        
        cur = conn.cursor()
        
        # Check Oracle version
        cur.execute("SELECT banner FROM v$version WHERE ROWNUM = 1")
        version = cur.fetchone()[0]
        print(f"✓ Oracle version: {version}")
        
        # Check if package exists
        print("\nChecking package objects...")
        cur.execute("""
            SELECT object_name, object_type, status 
            FROM user_objects 
            WHERE object_name = 'CARECONNECT_PKG'
            ORDER BY object_type
        """)
        
        objects = cur.fetchall()
        if not objects:
            print("✗ CARECONNECT_PKG not found!")
            print("  You need to create the package first.")
            print("  Run the SQL scripts in SQL*Plus or SQL Developer")
            return False
        
        for obj_name, obj_type, status in objects:
            if status == 'VALID':
                print(f"✓ {obj_type}: {status}")
            else:
                print(f"✗ {obj_type}: {status}")
                
                # Get compilation errors
                cur.execute("""
                    SELECT line, position, text 
                    FROM user_errors 
                    WHERE name = :1 AND type = :2
                    ORDER BY sequence
                """, [obj_name, obj_type])
                
                errors = cur.fetchall()
                if errors:
                    print(f"  Compilation errors for {obj_type}:")
                    for line, pos, text in errors:
                        print(f"    Line {line}, Pos {pos}: {text}")
        
        # Check required tables
        print("\nChecking required tables...")
        tables = ['PATIENTS', 'DOCTORS', 'APPOINTMENTS', 'TREATMENTS', 
                  'BILLING', 'AUDIT_LOG', 'FEEDBACK']
        
        for table in tables:
            cur.execute(f"SELECT COUNT(*) FROM user_tables WHERE table_name = '{table}'")
            count = cur.fetchone()[0]
            if count > 0:
                # Get row count
                try:
                    cur.execute(f"SELECT COUNT(*) FROM {table}")
                    row_count = cur.fetchone()[0]
                    print(f"✓ {table}: exists ({row_count} rows)")
                except:
                    print(f"✓ {table}: exists")
            else:
                print(f"✗ {table}: missing!")
        
        # Test a simple function call if package is valid
        print("\nTesting package functions...")
        try:
            cur.execute("SELECT careconnect_pkg.monthly_patient_load('2025-01') FROM dual")
            result = cur.fetchone()[0]
            print(f"✓ Package functions callable (test result: {result})")
        except Exception as e:
            print(f"✗ Error calling package function: {e}")
            if "invalid identifier" in str(e).lower():
                print("  This means the package body wasn't created or compiled successfully")
            elif "does not exist" in str(e).lower():
                print("  The package specification exists but body is missing")
        
        # Test procedure call
        print("\nTesting procedure calls...")
        try:
            outcur = conn.cursor()
            cur.callproc("careconnect_pkg.get_doctor_schedule", [1, oracledb.Date(2025, 12, 1), outcur])
            print("✓ Procedures callable")
            outcur.close()
        except Exception as e:
            print(f"✗ Error calling procedure: {e}")
        
        cur.close()
        conn.close()
        
        print("\n" + "=" * 60)
        print("DIAGNOSTIC COMPLETE")
        print("=" * 60)
        return True
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        print(f"\n✗ Database Error:")
        print(f"  Code: {error_obj.code}")
        print(f"  Message: {error_obj.message}")
        return False
    except Exception as e:
        print(f"\n✗ Connection Error: {e}")
        return False

if __name__ == "__main__":
    test_connection()
    input("\nPress Enter to exit...")