import sqlite3

DB_PATH = 'contacts.db'

def get_all_contacts():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM contacts")
    rows = cursor.fetchall()
    conn.close()
    return rows

def add_contact(name, phone, email, note):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("INSERT INTO contacts (name, phone, email, note) VALUES (?, ?, ?, ?)",
                   (name, phone, email, note))
    conn.commit()
    conn.close()

def update_contact(contact_id, name, phone, email, note):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("""
        UPDATE contacts
        SET name=?, phone=?, email=?, note=?
        WHERE id=?
    """, (name, phone, email, note, contact_id))
    conn.commit()
    conn.close()

def delete_contact(contact_id):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("DELETE FROM contacts WHERE id=?", (contact_id,))
    conn.commit()
    conn.close()
