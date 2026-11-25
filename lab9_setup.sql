-- ============================================================================
-- PART 1: Database Setup
-- ============================================================================
DROP TABLE IF EXISTS rentals, bikes, members, stations CASCADE;

CREATE TABLE stations (
    station_id INT PRIMARY KEY,
    station_name VARCHAR(50) NOT NULL,
    city VARCHAR(40) NOT NULL,
    capacity INT NOT NULL
);

CREATE TABLE bikes (
    bike_id INT PRIMARY KEY,
    model VARCHAR(50) NOT NULL,
    station_id INT REFERENCES stations (station_id),
    daily_rate NUMERIC(8,2) NOT NULL
);

CREATE TABLE members (
    member_id INT PRIMARY KEY,
    full_name VARCHAR(60) NOT NULL,
    city VARCHAR(40) NOT NULL,
    joined_on DATE NOT NULL
);

CREATE TABLE rentals (
    rental_id INT PRIMARY KEY,
    member_id INT REFERENCES members (member_id),
    bike_id INT REFERENCES bikes (bike_id),
    start_date DATE NOT NULL,
    end_date DATE,
    fee NUMERIC(8,2)
);

INSERT INTO stations VALUES
(10, 'Central Park', 'Almaty', 4),
(20, 'Riverside', 'Almaty', 3),
(30, 'Expo Gate', 'Astana', 5),
(40, 'Old Town', 'Shymkent', 2),
(50, 'Depot', 'Astana', 0);

INSERT INTO bikes VALUES
(101, 'City Cruiser', 10, 4.50),
(102, 'City Cruiser', 10, 4.50),
(103, 'Mountain X', 20, 7.00),
(104, 'Mountain X', 30, 7.00),
(105, 'Road Sprint', 30, 9.25),
(106, 'Folding Mini', 40, 3.75),
(107, 'Cargo Hauler', 20, 12.00),
(108, 'Road Sprint', 10, 9.25);

INSERT INTO members VALUES
(1, 'Aisha Nurlanova', 'Almaty', DATE '2023-03-14'),
(2, 'Daniyar Serik', 'Almaty', DATE '2023-07-02'),
(3, 'Marta Kowalski', 'Astana', DATE '2024-01-20'),
(4, 'Chen Wei', 'Astana', DATE '2024-05-11'),
(5, 'Omar Haddad', 'Shymkent', DATE '2024-09-30'),
(6, 'Elena Petrova', 'Almaty', DATE '2025-02-05');

INSERT INTO rentals VALUES
(1, 1, 101, DATE '2024-04-05', DATE '2024-04-08', 13.50),
(2, 1, 103, DATE '2024-06-11', DATE '2024-06-16', 35.00),
(3, 1, 108, DATE '2025-02-02', DATE '2025-02-04', 18.50),
(4, 1, 102, DATE '2025-05-20', DATE '2025-05-27', 31.50),
(5, 2, 101, DATE '2024-05-01', DATE '2024-05-02', 4.50),
(6, 2, 107, DATE '2024-11-15', DATE '2024-11-19', 48.00),
(7, 2, 107, DATE '2025-03-08', DATE '2025-03-14', 72.00),
(8, 3, 104, DATE '2024-02-14', DATE '2024-02-18', 28.00),
(9, 3, 105, DATE '2024-08-03', DATE '2024-08-06', 27.75),
(10, 3, 104, DATE '2025-01-09', DATE '2025-01-10', 7.00),
(11, 3, 105, DATE '2025-06-01', DATE '2025-06-09', 74.00),
(12, 4, 104, DATE '2024-07-19', DATE '2024-07-21', 14.00),
(13, 4, 105, DATE '2025-04-12', DATE '2025-04-15', 27.75),
(14, 4, 103, DATE '2025-07-23', DATE '2025-07-29', 42.00),
(15, 5, 106, DATE '2024-10-05', DATE '2024-10-12', 26.25),
(16, 5, 106, DATE '2025-01-18', DATE '2025-01-20', 7.50),
(17, 5, 106, DATE '2025-08-14', DATE '2025-08-21', 26.25),
(18, 2, 102, DATE '2025-09-02', DATE '2025-09-05', 13.50),
(19, 1, 101, DATE '2025-10-10', NULL, NULL),
(20, 4, 108, DATE '2024-12-28', DATE '2025-01-03', 55.50),
(21, 3, 103, DATE '2025-02-26', DATE '2025-03-02', 28.00),
(22, 5, 104, DATE '2025-05-05', DATE '2025-05-08', 21.00);

-- ============================================================================
-- PART 2: Your First Function
-- ============================================================================

-- Exercise 2.1: A function over one row
CREATE OR REPLACE FUNCTION rental_days(p_rental_id INT) RETURNS INT AS $$
DECLARE
    v_days INT;
BEGIN
    SELECT end_date - start_date INTO v_days
    FROM rentals
    WHERE rental_id = p_rental_id;

    RETURN v_days;
END;
$$ LANGUAGE plpgsql;

SELECT rental_days(2);
SELECT rental_days(11);
SELECT rental_days(19);
SELECT rental_days(999);

/*
Answer 2.1:
Both calls return NULL, but for different reasons. For rental 19, the row exists
in the table, but end_date is NULL, so NULL - start_date gives NULL. For rental 999,
the row does not exist at all, so SELECT INTO puts NULL into the variable.
*/

-- Exercise 2.2: A function over many rows
CREATE OR REPLACE FUNCTION member_rental_count(p_member_id INT) RETURNS INT AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM rentals
    WHERE member_id = p_member_id;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

SELECT member_rental_count(1);
SELECT member_rental_count(5);
SELECT member_rental_count(6);
SELECT member_rental_count(99);

/*
Answer 2.2:
Both member 6 and member 99 return 0. The COUNT(*) function always counts matching
rows and returns 0 when it finds zero rows, never NULL.
*/

-- Exercise 2.3: Returning text
CREATE OR REPLACE FUNCTION station_city(p_station_id INT) RETURNS VARCHAR AS $$
DECLARE
    v_city VARCHAR;
BEGIN
    SELECT city INTO v_city
    FROM stations
    WHERE station_id = p_station_id;

    RETURN v_city;
END;
$$ LANGUAGE plpgsql;

SELECT station_city(30);
SELECT station_city(77);

-- Exercise 2.4: Using a function inside a query
SELECT rental_id, member_id, rental_days(rental_id) AS duration
FROM rentals
WHERE rental_days(rental_id) > 4
ORDER BY duration DESC;

-- ============================================================================
-- PART 3: Parameter Modes
-- ============================================================================

-- Exercise 3.1: IN parameters
CREATE OR REPLACE FUNCTION fee_with_discount(p_fee NUMERIC, p_percent NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
    RETURN ROUND(p_fee * (1 - p_percent / 100.0), 2);
END;
$$ LANGUAGE plpgsql;

SELECT fee_with_discount(74.00, 15);

-- Exercise 3.2: OUT parameters
CREATE OR REPLACE FUNCTION member_stats(
    p_member_id INT,
    OUT rental_cnt INT,
    OUT total_fee NUMERIC,
    OUT last_start DATE)
AS $$
BEGIN
    SELECT COUNT(*), COALESCE(SUM(fee), 0), MAX(start_date)
    INTO rental_cnt, total_fee, last_start
    FROM rentals
    WHERE member_id = p_member_id;
END;
$$ LANGUAGE plpgsql;

SELECT member_stats(3);
SELECT * FROM member_stats(3);
SELECT * FROM member_stats(6);

/*
Answer 3.2:
SELECT member_stats(3) returns one single column with all values together in
parentheses like (5,164.75,2025-06-01). SELECT * FROM member_stats(3) returns
three separate columns. Inside a larger query, SELECT * FROM ... is better because
you can use each column name easily. For member 6, it returns (0, 0, NULL).
*/

-- Exercise 3.3: INOUT parameters
CREATE OR REPLACE FUNCTION apply_late_fee(INOUT p_fee NUMERIC)
AS $$
BEGIN
    p_fee := p_fee + 5.00;
END;
$$ LANGUAGE plpgsql;

SELECT apply_late_fee(fee) FROM rentals WHERE rental_id = 1;

/*
Answer 3.3:
It produces a value because the parameter mode is INOUT. An INOUT parameter
automatically works as an output column, so PostgreSQL returns its final value
when the function ends.
*/

-- Exercise 3.4: VARIADIC parameters
CREATE OR REPLACE FUNCTION fee_summary(
    VARIADIC p_fees NUMERIC[],
    OUT total NUMERIC,
    OUT average NUMERIC,
    OUT largest NUMERIC)
AS $$
BEGIN
    SELECT SUM(p_fees[i]), ROUND(AVG(p_fees[i]), 2), MAX(p_fees[i])
    INTO total, average, largest
    FROM generate_subscripts(p_fees, 1) g(i);
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fee_summary(13.50, 35.00, 18.50, 31.50);
SELECT * FROM fee_summary();

/*
Answer 3.4:
If you call fee_summary() with no arguments, all three output columns return NULL.
A VARIADIC parameter must be last because it takes all remaining arguments; if
another parameter came after it, PostgreSQL would not know where the array ends.
*/

/*
Answer 3.5: Choosing a mode
(a) IN: The function only needs to read the ID and does not change it.
(b) INOUT: The caller gives a starting balance, and the function updates and returns the same variable.
(c) VARIADIC: The caller can pass any number of station IDs as a list.
(d) OUT: The function needs to return two different result values at the same time.
*/

-- ============================================================================
-- PART 4: Default Values and Function Overloading
-- ============================================================================

-- Exercise 4.1: A function with one parameter
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT) RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0) INTO v_total
    FROM rentals
    WHERE member_id = p_member_id;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees(1);
SELECT total_fees(6);

-- Exercise 4.2: Overloading the name
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT, p_from_date DATE)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0) INTO v_total
    FROM rentals
    WHERE member_id = p_member_id AND start_date >= p_from_date;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees(1, DATE '2024-01-01');
SELECT total_fees(1, DATE '2025-01-01');

-- Exercise 4.3: Giving a parameter a default value
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT, p_from_date DATE DEFAULT DATE '2025-01-01')
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0) INTO v_total
    FROM rentals
    WHERE member_id = p_member_id AND start_date >= p_from_date;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

-- Uncomment the line below to trigger the error:
-- SELECT total_fees(1);

/*
Answer 4.3:
Error: ERROR: function total_fees(integer) is not unique
Hint: HINT: Could not choose a best candidate function. You might need to add explicit type casts.
Explanation: PostgreSQL cannot choose because total_fees(1) matches both
total_fees(INT) and total_fees(INT, DATE) (using the default date).
*/

-- Exercise 4.4: Resolving the ambiguity
DROP FUNCTION total_fees(INTEGER);
SELECT total_fees(1);

/*
Answer 4.4:
Now the two-parameter version with the default date answers the call, and it
returns 50.00 (only rentals from 2025). Dropping the other version would call
total_fees(INT) and return 98.50 (all rentals from all years).
*/

-- Exercise 4.5: Overloading on type, not just on count
CREATE OR REPLACE FUNCTION total_fees(p_member_name VARCHAR) RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(r.fee), 0) INTO v_total
    FROM members m
    LEFT JOIN rentals r ON m.member_id = r.member_id
    WHERE m.full_name = p_member_name;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees('Aisha Nurlanova');
SELECT total_fees(1);

/*
Answer 4.5:
There is no error because VARCHAR and INT are different data types, so PostgreSQL
knows which one to pick. total_fees('Aisha Nurlanova') calls the VARCHAR version
and sums all her rentals (98.50), while total_fees(1) calls the (INT, DATE) version
with the default date 2025-01-01 and returns 50.00.
*/

-- ============================================================================
-- PART 5: Functions That Return a Table
-- ============================================================================

-- Exercise 5.1: Search by pattern
CREATE OR REPLACE FUNCTION find_bikes(p_pattern VARCHAR)
RETURNS TABLE(found_id INT, found_model VARCHAR, found_rate NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT bike_id, model, daily_rate
    FROM bikes
    WHERE model ILIKE p_pattern
    ORDER BY bike_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM find_bikes('%road%');
SELECT * FROM find_bikes('%Mini');
SELECT find_bikes('%road%');

/*
Answer 5.1:
Without FROM, PostgreSQL returns all columns packed into one single composite
column (a tuple like (105,"Road Sprint",9.25)) instead of three separate columns.
*/

-- Exercise 5.2: A table from a join
CREATE OR REPLACE FUNCTION member_history(p_member_id INT)
RETURNS TABLE(
    rental_id INT,
    bike_model VARCHAR,
    station_name VARCHAR,
    duration INT,
    fee NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT r.rental_id, b.model, s.station_name, (r.end_date - r.start_date), r.fee
    FROM rentals r
    JOIN bikes b ON r.bike_id = b.bike_id
    JOIN stations s ON b.station_id = s.station_id
    WHERE r.member_id = p_member_id
    ORDER BY r.start_date;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM member_history(3);

-- Exercise 5.3: When the column names collide
-- Fix 1: Renaming output columns
CREATE OR REPLACE FUNCTION bike_list_v1(p_station_id INT)
RETURNS TABLE(out_bike_id INT, out_model VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT bike_id, model FROM bikes WHERE station_id = p_station_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM bike_list_v1(10);

-- Fix 2: Qualifying table columns with an alias
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE(bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT b.bike_id, b.model FROM bikes b WHERE b.station_id = p_station_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);

/*
Answer 5.3:
Why at call time: PostgreSQL checks the syntax when creating the function, but it
only runs and checks the SELECT query inside PL/pgSQL when you call the function.
Error message: ERROR: column reference "bike_id" is ambiguous
*/

-- Exercise 5.4: Casting the output
CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR)
RETURNS TABLE(s_name VARCHAR, s_bikes INT, s_free INT) AS $$
BEGIN
    RETURN QUERY
    SELECT s.station_name,
           COUNT(b.bike_id)::INT,
           (s.capacity - COUNT(b.bike_id))::INT
    FROM stations s
    LEFT JOIN bikes b ON s.station_id = b.station_id
    WHERE s.city = p_city
    GROUP BY s.station_id, s.station_name, s.capacity;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM station_board('Almaty');

/*
Answer 5.4:
If you do not cast COUNT(*), the function fails with a type mismatch error because
BIGINT does not automatically match INT in RETURNS TABLE.
Error message: ERROR: structure of query does not match function result type
(Returned type bigint does not match expected type integer in column 2.)
*/

-- ============================================================================
-- PART 6: Block Structure, DO Blocks and Subblocks
-- ============================================================================

-- Exercise 6.1: An anonymous block
DO $$
<<rental_report>>
DECLARE
    total_rentals INTEGER := 0;
BEGIN
    SELECT COUNT(*) INTO total_rentals FROM rentals;
    RAISE NOTICE 'The rentals table holds % rows.', total_rentals;
END rental_report $$;

/*
Answer 6.1:
If the end label does not match the start label, PostgreSQL stops and gives a
syntax error (ERROR: end label "..." differs from block's label "...").
*/

-- Exercise 6.2: A subblock and a hidden variable
DO $$
<<outer_block>>
DECLARE
    fee_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0) INTO fee_total FROM rentals;
    RAISE NOTICE '1. Outer before subblock: %', fee_total;

    DECLARE
        fee_total NUMERIC;
    BEGIN
        SELECT COALESCE(SUM(fee), 0) INTO fee_total
        FROM rentals
        WHERE start_date >= DATE '2025-01-01';

        RAISE NOTICE '2. Subblock own value: %', fee_total;
        RAISE NOTICE '3. Outer value via label: %', outer_block.fee_total;
    END;

    RAISE NOTICE '4. Outer after subblock: %', fee_total;
END outer_block $$;

/*
Answer 6.2:
Four numbers printed: 593.00, 356.75, 593.00, 593.00.
No, the assignment inside the subblock did not change the outer variable. This
shows that a variable declared in a subblock is local and separate from the outer block.
*/

-- Exercise 6.3: Declarations are local (Fixed version)
DO $$
DECLARE
    shared_var INT := 100;
BEGIN
    BEGIN
        shared_var := shared_var + 50;
        RAISE NOTICE 'Subblock 1 sees: %', shared_var;
    END;

    BEGIN
        RAISE NOTICE 'Subblock 2 sees: %', shared_var;
    END;
END $$;

/*
Answer 6.3:
Error message when reading from first subblock: ERROR: column "..." does not exist
(PL/pgSQL cannot find the variable because it died when the first subblock ended).
*/

-- Exercise 6.4: From a block to a function
CREATE OR REPLACE FUNCTION fee_split(
    p_from_date DATE,
    OUT before_total NUMERIC,
    OUT after_total NUMERIC)
AS $$
BEGIN
    SELECT COALESCE(SUM(fee), 0) INTO before_total
    FROM rentals
    WHERE start_date < p_from_date;

    SELECT COALESCE(SUM(fee), 0) INTO after_total
    FROM rentals
    WHERE start_date >= p_from_date;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fee_split(DATE '2025-01-01');

-- ============================================================================
-- PART 7: Practical Scenarios
-- ============================================================================

-- Exercise 7.1: Station occupancy
CREATE OR REPLACE FUNCTION station_load(
    p_station_id INT,
    OUT bikes_parked INT,
    OUT capacity_pct NUMERIC)
AS $$
DECLARE
    v_cap INT;
BEGIN
    SELECT capacity INTO v_cap FROM stations WHERE station_id = p_station_id;
    SELECT COUNT(*)::INT INTO bikes_parked FROM bikes WHERE station_id = p_station_id;

    IF v_cap = 0 OR v_cap IS NULL THEN
        capacity_pct := 0.0;
    ELSE
        capacity_pct := ROUND((bikes_parked::NUMERIC / v_cap) * 100, 1);
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT s.station_id, s.station_name, l.*
FROM stations s, LATERAL station_load(s.station_id) l;

/*
Answer 7.1:
I chose to return 0.0 when capacity is 0 because you cannot divide by zero, and
0.0 shows there is no valid percentage without crashing the query.
*/

-- Exercise 7.2: Top members, with a default
CREATE OR REPLACE FUNCTION top_members(p_limit INT DEFAULT 3)
RETURNS TABLE(member_name VARCHAR, rental_cnt INT, total_spent NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT m.full_name,
           COUNT(r.rental_id)::INT,
           COALESCE(SUM(r.fee), 0)
    FROM members m
    LEFT JOIN rentals r ON m.member_id = r.member_id
    GROUP BY m.member_id, m.full_name
    ORDER BY COALESCE(SUM(r.fee), 0) DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM top_members();
SELECT * FROM top_members(6);

/*
Answer 7.2:
Member 3 (Marta Kowalski) has 5 rentals, which is more than Member 2 (Daniyar Serik,
4 rentals), yet Member 3 is ranked lower. This is not a bug because the table is
ordered by total_spent (money), not by the number of rentals (164.75 vs 138.00).
*/

-- Exercise 7.3: An invoice for an open rental
CREATE OR REPLACE FUNCTION rental_invoice(p_rental_id INT)
RETURNS TABLE(
    member_name VARCHAR,
    bike_model VARCHAR,
    days INT,
    amount_owed NUMERIC,
    status VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT m.full_name,
           b.model,
           (COALESCE(r.end_date, CURRENT_DATE) - r.start_date)::INT,
           ROUND((COALESCE(r.end_date, CURRENT_DATE) - r.start_date) * b.daily_rate, 2),
           (CASE WHEN r.end_date IS NULL THEN 'OPEN' ELSE 'CLOSED' END)::VARCHAR
    FROM rentals r
    JOIN members m ON r.member_id = m.member_id
    JOIN bikes b ON r.bike_id = b.bike_id
    WHERE r.rental_id = p_rental_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM rental_invoice(11);
SELECT * FROM rental_invoice(19);

/*
Answer 7.3:
Yes, for rental 11 the calculated amount is 74.00, which equals the fee in the table.
For rental 19, end_date is NULL, so the function uses CURRENT_DATE (today), which
grows larger every day. A function using CURRENT_DATE cannot be called IMMUTABLE
because it returns different answers on different days.
*/

-- Exercise 7.4: A report per city
CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR)
RETURNS TABLE(member_cnt INT, rental_cnt INT, total_revenue NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(DISTINCT m.member_id)::INT,
           COUNT(r.rental_id)::INT,
           COALESCE(SUM(r.fee), 0)
    FROM members m
    LEFT JOIN rentals r ON m.member_id = r.member_id
    WHERE m.city = p_city;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR, p_from_date DATE)
RETURNS TABLE(member_cnt INT, rental_cnt INT, total_revenue NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(DISTINCT m.member_id)::INT,
           COUNT(r.rental_id)::INT,
           COALESCE(SUM(r.fee), 0)
    FROM members m
    LEFT JOIN rentals r ON m.member_id = r.member_id AND r.start_date >= p_from_date
    WHERE m.city = p_city;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM city_report('Almaty');
SELECT * FROM city_report('Almaty', DATE '2025-01-01');

/*
Answer 7.4:
The date condition belongs in the ON clause. In the ON clause, Almaty has 3 members
(Elena Petrova is still counted with 0 rentals). If you put it in the WHERE clause,
Almaty has only 2 members because WHERE removes rows where start_date is NULL.
*/

-- ============================================================================
-- LAB QUESTIONS (1 - 10)
-- ============================================================================
/*
1. Name vs. Signature:
A function's name is just its text identifier (like total_fees), while its signature
is the name plus its input argument types (like total_fees(INT)). PostgreSQL needs
the signature when dropping an overloaded function so it knows which exact version to delete.

2. Dollar Quoting ($$):
Dollar quoting lets you write strings with single quotes inside a function without
doubling them (''). For example, writing 'It''s a bike' is awkward, while
$$SELECT 'It's a bike';$$ is clean and easy to read.

3. OUT parameters vs. RETURNS TABLE:
Use OUT parameters when a function returns just one row with a few values (like a summary).
Use RETURNS TABLE when a function returns many rows, like a list or a report.

4. VARIADIC last:
A VARIADIC parameter collects all extra arguments into an array. If you had
func(VARIADIC a INT[], b INT) and called func(1, 2, 3), PostgreSQL could not know
if 3 belongs to the array a or to parameter b.

5. RETURN vs. RETURN QUERY:
RETURN sends back a single value and stops the function immediately. RETURN QUERY
adds rows from a SELECT query to the result table and continues running the function.

6. DEFAULT parameter ambiguity:
If you already have func(INT) and add func(INT, DATE DEFAULT '2025-01-01'), calling
func(1) becomes ambiguous because both match. In production, avoid overloading
functions with the same starting types and default values, or drop the old version.

7. Subblock variables:
When a subblock ends, all variables declared inside it are destroyed and cannot be
used anymore. To read a shadowed outer variable inside a subblock, add a label to
the outer block and write outer_label.variable_name.

8. Advantage and disadvantage:
An advantage is better performance because the code runs inside the database server
in one step. A disadvantage is that database code is harder to test and put into
version control (like Git) than normal application code.

9. Trusted vs. Untrusted languages:
A trusted language (like PL/pgSQL) cannot touch files or the network outside the
database, so any regular user can write functions in it. An untrusted language
(like PL/Python) can access the server's operating system and files, so only a
database superuser can use it.

10. Changing argument types with CREATE OR REPLACE:
CREATE OR REPLACE only replaces a function if the name and argument types are identical.
If you change the argument types, PostgreSQL creates a brand-new overloaded function
instead, leaving the old version in the database, which can cause confusion or
ambiguity errors later.
*/