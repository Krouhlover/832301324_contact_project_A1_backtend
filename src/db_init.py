import sqlite3

def init_db():
    conn = sqlite3.connect('contacts.db')
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS contacts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            email TEXT,
            note TEXT
        )
    ''')
    conn.commit()
    conn.close()
    print("✅ 数据库已初始化")

if __name__ == '__main__':
    init_db()
