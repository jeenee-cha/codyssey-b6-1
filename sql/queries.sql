-- B6-1 핵심 쿼리 15개
-- 대상 DB: SQLite 3
PRAGMA foreign_keys = ON;

.headers on
.mode column
.nullvalue NULL

-- Q1. 기본 조회: 가격이 35,000원 이상인 고가 도서 상위 5권
SELECT 'Q1. 고가 도서 상위 5권' AS result;
SELECT book_id, title, price
FROM books
WHERE price >= 35000
ORDER BY price DESC, title ASC
LIMIT 5;

-- Q2. 기본 조회: 2023년 이후 출간된 도서 중 최신 5권
SELECT 'Q2. 최신 도서 5권' AS result;
SELECT book_id, title, published_date
FROM books
WHERE published_date >= '2023-01-01'
ORDER BY published_date DESC, book_id ASC
LIMIT 5;

-- Q3. 기본 조회: 처리 대기 중인 최근 주문 5건
SELECT 'Q3. 처리 대기 주문' AS result;
SELECT order_id, customer_id, ordered_at, status
FROM orders
WHERE status = 'pending'
ORDER BY ordered_at DESC
LIMIT 5;

-- Q4. 기본 조회: 재고가 5권 이하인 도서
SELECT 'Q4. 재고 부족 도서' AS result;
SELECT book_id, title, stock
FROM books
WHERE stock <= 5
ORDER BY stock ASC, title ASC
LIMIT 5;

-- Q5. INNER JOIN: 주문과 고객을 연결한 최근 주문 내역
SELECT 'Q5. 고객별 최근 주문' AS result;
SELECT o.order_id, c.name AS customer_name, o.ordered_at, o.status
FROM orders AS o
INNER JOIN customers AS c ON c.customer_id = o.customer_id
ORDER BY o.ordered_at DESC
LIMIT 10;

-- Q6. INNER JOIN: 주문 항목과 도서를 연결한 상세 내역
SELECT 'Q6. 주문 상품 상세' AS result;
SELECT oi.order_id, b.title, oi.quantity, oi.unit_price,
       oi.quantity * oi.unit_price AS line_total
FROM order_items AS oi
INNER JOIN books AS b ON b.book_id = oi.book_id
ORDER BY oi.order_id ASC, oi.order_item_id ASC
LIMIT 10;

-- Q7. LEFT JOIN: 주문 이력이 없는 고객 찾기
SELECT 'Q7. 주문 이력이 없는 고객' AS result;
SELECT c.customer_id, c.name, c.email
FROM customers AS c
LEFT JOIN orders AS o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;

-- Q8. INNER JOIN: 도서와 카테고리를 연결한 재고 현황
SELECT 'Q8. 카테고리별 도서 재고' AS result;
SELECT c.name AS category_name, b.title, b.stock
FROM books AS b
INNER JOIN categories AS c ON c.category_id = b.category_id
ORDER BY c.name ASC, b.stock ASC
LIMIT 10;

-- Q9. 집계: 카테고리별 도서 수와 평균 가격
SELECT 'Q9. 카테고리별 도서 통계' AS result;
SELECT c.name AS category_name,
       COUNT(b.book_id) AS book_count,
       ROUND(AVG(b.price), 0) AS average_price
FROM categories AS c
LEFT JOIN books AS b ON b.category_id = c.category_id
GROUP BY c.category_id, c.name
ORDER BY book_count DESC, c.name ASC;

-- Q10. 집계: 완료된 주문을 기준으로 고객별 구매 금액
SELECT 'Q10. 고객별 완료 구매 금액' AS result;
SELECT c.customer_id, c.name,
       COUNT(DISTINCT o.order_id) AS completed_orders,
       SUM(oi.quantity * oi.unit_price) AS total_spent
FROM customers AS c
INNER JOIN orders AS o ON o.customer_id = c.customer_id
INNER JOIN order_items AS oi ON oi.order_id = o.order_id
WHERE o.status = 'completed'
GROUP BY c.customer_id, c.name
ORDER BY total_spent DESC;

-- Q11. 집계: 월별 주문 수와 주문 금액
-- SQLite 전용 strftime 함수로 연월을 추출한다.
SELECT 'Q11. 월별 주문 통계' AS result;
SELECT strftime('%Y-%m', o.ordered_at) AS order_month,
       COUNT(DISTINCT o.order_id) AS order_count,
       SUM(oi.quantity * oi.unit_price) AS order_total
FROM orders AS o
INNER JOIN order_items AS oi ON oi.order_id = o.order_id
WHERE o.status <> 'cancelled'
GROUP BY strftime('%Y-%m', o.ordered_at)
ORDER BY order_month ASC;

-- Q12. 서브쿼리: 같은 카테고리의 평균보다 비싼 도서
SELECT 'Q12. 카테고리 평균 초과 도서' AS result;
SELECT b.book_id, b.title, b.price, c.name AS category_name
FROM books AS b
INNER JOIN categories AS c ON c.category_id = b.category_id
WHERE b.price > (
    SELECT AVG(b2.price)
    FROM books AS b2
    WHERE b2.category_id = b.category_id
)
ORDER BY c.name ASC, b.price DESC;

-- Q13. 수정: 7번 주문을 취소하고 전후 상태 확인
SELECT 'Q13. UPDATE 전' AS result;
SELECT order_id, status FROM orders WHERE order_id = 7;
UPDATE orders
SET status = 'cancelled'
WHERE order_id = 7;
SELECT 'Q13. UPDATE 후' AS result;
SELECT order_id, status FROM orders WHERE order_id = 7;

-- Q14. 삭제: 취소된 12번 주문 삭제 전후 확인
-- order_items는 ON DELETE CASCADE에 의해 함께 삭제된다.
SELECT 'Q14. DELETE 전' AS result;
SELECT o.order_id, o.status, COUNT(oi.order_item_id) AS item_count
FROM orders AS o
LEFT JOIN order_items AS oi ON oi.order_id = o.order_id
WHERE o.order_id = 12
GROUP BY o.order_id, o.status;
DELETE FROM orders
WHERE order_id = 12 AND status = 'cancelled';
SELECT 'Q14. DELETE 후' AS result;
SELECT COUNT(*) AS remaining_orders FROM orders WHERE order_id = 12;
SELECT COUNT(*) AS remaining_items FROM order_items WHERE order_id = 12;

-- Q15. 인덱스: 고객별 주문 이력과 기간 검색을 빠르게 하기 위한 복합 인덱스
SELECT 'Q15. 주문 검색 인덱스' AS result;
CREATE INDEX IF NOT EXISTS idx_orders_customer_ordered_at
    ON orders (customer_id, ordered_at);
SELECT name AS index_name
FROM pragma_index_list('orders')
WHERE name = 'idx_orders_customer_ordered_at';
EXPLAIN QUERY PLAN
SELECT order_id, ordered_at, status
FROM orders
WHERE customer_id = 2
  AND ordered_at >= '2026-09-01 00:00:00'
ORDER BY ordered_at;
