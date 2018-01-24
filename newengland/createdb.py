import psycopg2
from psycopg2 import connect
import sys
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

# choose a database name
dbname = "test"

# function to create a database
def createdb():
        conn_string = "host='localhost' user='postgres' password='postgres'"
        conn = psycopg2.connect(conn_string)
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()        
        cursor.execute('CREATE DATABASE ' + dbname)
        conn.commit()
        cursor.close()
        conn.close()

# function to create a database postgis extension
def createpostgisext():
        conn_string = "host='localhost' dbname='" + dbname + "' user='postgres' password='postgres'"
        conn = psycopg2.connect(conn_string)
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()
        cursor.execute('CREATE EXTENSION postgis;')
        conn.commit()
        cursor.close()
        conn.close()

if __name__ == "__main__":
    createdb()
    createpostgisext()