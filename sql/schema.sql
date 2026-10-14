-- B6-1 온라인 서점 주문 관리 데이터베이스
-- 대상 DB: SQLite 3

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS categories;

CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    joined_at TEXT NOT NULL,
    -- SQLite date()가 해석할 수 있는 YYYY-MM-DD 형식만 허용한다.
    CHECK (date(joined_at) IS NOT NULL AND joined_at = date(joined_at))
);

CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    category_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    isbn TEXT NOT NULL UNIQUE,
    price INTEGER NOT NULL CHECK (price >= 0),
    stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    published_date TEXT NOT NULL,
    -- SQLite date()가 해석할 수 있는 YYYY-MM-DD 형식만 허용한다.
    CHECK (
        date(published_date) IS NOT NULL
        AND published_date = date(published_date)
    ),
    FOREIGN KEY (category_id)
        REFERENCES categories (category_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    ordered_at TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'shipped', 'completed', 'cancelled')),
    -- SQLite datetime()가 해석할 수 있는 YYYY-MM-DD HH:MM:SS 형식만 허용한다.
    CHECK (
        datetime(ordered_at) IS NOT NULL
        AND ordered_at = datetime(ordered_at)
    ),
    FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    book_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price INTEGER NOT NULL CHECK (unit_price >= 0),
    UNIQUE (order_id, book_id),
    FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (book_id)
        REFERENCES books (book_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);
