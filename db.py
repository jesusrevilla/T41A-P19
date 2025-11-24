import sqlite3
import json

def crear_conexion():
    return sqlite3.connect("productos.db")

def crear_tablas():
    conn = crear_conexion()
    cur = conn.cursor()

    cur.execute("""
        CREATE TABLE IF NOT EXISTS productos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            atributos JSON
        );
    """)

    conn.commit()
    conn.close()

def insertar_datos():
    conn = crear_conexion()
    cur = conn.cursor()

    # ─────────────────────────────────────────────
    # Insertar laptop
    # ─────────────────────────────────────────────
    laptop_atributos = {
        "marca": "HP",
        "ram": "12GB"
    }

    cur.execute("""
        INSERT INTO productos (nombre, atributos)
        VALUES (?, ?)
    """, ("Laptop", json.dumps(laptop_atributos)))

    # ─────────────────────────────────────────────
    # Insertar teléfono
    # ─────────────────────────────────────────────
    telefono_atributos = {
        "color": "azul"
    }

    cur.execute("""
        INSERT INTO productos (nombre, atributos)
        VALUES (?, ?)
    """, ("Teléfono", json.dumps(telefono_atributos)))

    conn.commit()
    conn.close()

def run_query(query):
    conn = crear_conexion()
    cur = conn.cursor()

    result = cur.execute(query).fetchall()

    conn.commit()
    conn.close()

    return result
