import os
import sys
import subprocess
import urllib.parse

def load_db_env(env_path):
    if not os.path.exists(env_path):
        print(f"Error: {env_path} not found.")
        sys.exit(1)
        
    db_url = None
    with open(env_path) as f:
        for line in f:
            if "SUPABASE_DB_URL" in line:
                db_url = line.split("=", 1)[1].strip().strip("'\"")
                break
                
    if not db_url:
        print("Error: SUPABASE_DB_URL not found in .env")
        sys.exit(1)
        
    p = urllib.parse.urlparse(db_url)
    username = urllib.parse.unquote(p.username) if p.username else ""
    password = urllib.parse.unquote(p.password) if p.password else ""
    hostname = p.hostname
    port = str(p.port or 5432)
    dbname = p.path.lstrip("/")
    
    env = os.environ.copy()
    env["PGHOST"] = hostname
    env["PGPORT"] = port
    env["PGDATABASE"] = dbname
    env["PGUSER"] = username
    env["PGPASSWORD"] = password
    env["PGSSLMODE"] = "require"
    env["PGCONNECT_TIMEOUT"] = "10"
    return env

def run_sql_file(sql_file, env):
    print(f"Executing: {sql_file} on Supabase...")
    res = subprocess.run(
        ["psql", "-w", "-f", sql_file], 
        capture_output=True, 
        text=True, 
        env=env
    )
    if res.returncode == 0:
        print("SUCCESS!")
        print(res.stdout)
        return True, res.stdout
    else:
        print(f"FAILED with exit code {res.returncode}:")
        print("STDOUT:", res.stdout)
        print("STDERR:", res.stderr)
        return False, res.stderr

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python run_sql_on_supabase.py <sql_file_path>")
        sys.exit(1)
        
    sql_file = sys.argv[1]
    env_path = os.path.join(os.path.dirname(__file__), "..", "..", ".env")
    env = load_db_env(env_path)
    run_sql_file(sql_file, env)
