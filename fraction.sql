-- This is an easy type-definition for PostgreSQL. It is for educational purposes only.
-- No time is spend on low level optimization and the range of the bigint is limited under circumstances. 
-- For production-code, it is better to use the Multiple Precision Arithmetic plugin.
-- http://pgmp.projects.pgfoundry.org

-- (c) 2015 Matthieu Peeters. Feel free to read, copy, change, or reuse in any way under the terms of the GPL. 


-- Note that the still limited precision might result in problems when multiplying a lot of fractions. 
create type fraction as (n bigint, d bigint);


-- Some casting functions:
create or replace function pgx_fraction_from_int(int) returns fraction as $$ select row($1::bigint, 1::bigint)::fraction; $$ language sql immutable strict ;

create or replace function pgx_fraction_from_bigint(bigint) returns fraction as $$ select row($1::bigint, 1::bigint)::fraction; $$ language sql immutable strict ;

create or replace function pgx_numeric_from_fraction(fraction) returns numeric as $$ select (($1).n::numeric / ($1).d::numeric)::numeric; $$ language sql immutable strict ;

create or replace function pgx_double_precision_from_fraction(fraction) returns double precision as $$ select (($1).n::double precision / ($1).d::double precision)::double precision; $$ language sql immutable strict ;

-- The greatest commin divider is used to reduce fractions:
create or replace function gcd(a_p bigint, b_p bigint) returns bigint as $$
declare r_v bigint;
begin
   -- The gcd is always positive, but that is only important at the end.
   -- the formula is: gcd(a, b) := b = 0 -> a
   --                              b <> 0 -> gcd(b, a % b)
   while b_p <> 0 loop -- But we won't recurse 
     r_v := a_p % b_p; -- We'll use modulo to skip a lot of steps that Euclid would have taken.
     a_p := b_p;
     b_p := r_v;
   end loop;
   return abs(a_p);
end;
$$ language plpgsql immutable strict; 


-- Reduce the franction to the smallest nominator and divider:
create or replace function pgx_fraction_reduce(a_p fraction) returns fraction as $$
declare gcd_v bigint;
declare neg_v integer = 1;
begin
   -- the formula is: reduce(n / d) = sign(n)*sign(d)*(|n|/gcd(n, d))   /   (|d|/gcd(n,d))
   if (a_p).d <= 0 then
      if (a_p).d = 0 then return row((a_p).n / 0, 0)::fraction; end if; -- Throw /0 error
      a_p.d := -(a_p).d;
      neg_v := -1;
   end if;
   if (a_p).n <= 0 then
      if (a_p).n = 0 then return row(0, 1)::fraction; end if;
      a_p.n := -(a_p).n;
      neg_v := -neg_v;
   end if;
   gcd_v := gcd((a_p).n, (a_p).d);
   return row(neg_v * (a_p).n / gcd_v, (a_p).d / gcd_v)::fraction;
end;
$$ language plpgsql immutable strict;


-- Some support functions for typecasting:
create or replace function pgx_fraction_from_numeric(a numeric) returns fraction as $$
declare d bigint = 1;
begin
   while (a - trunc(a)) <> 0.0 -- Any digits behind the decimal point?
   loop -- decimal fraction, always writable as a power of ten as the divider:
	d := d * 10;
	a := a * 10;
   end loop;
   return pgx_fraction_reduce(row(a::bigint, d));
end;
$$ language plpgsql immutable strict;
 
create or replace function pgx_fraction_from_double_precision(a double precision) returns fraction as $$
declare d bigint = 1;
begin
   while (a - trunc(a)) <> 0.0 -- Any digits behind the binary point?
   loop -- binary fraction, always writable as a power of sixteen as the divider: 
	d := d * 16; -- (16 instead of 2 for speed, maybe premature ;) )
	a := a * 16;
   end loop;
   return pgx_fraction_reduce(row(a::bigint, d));
end;
$$ language plpgsql immutable strict;


-- A support function for comparation:
-- compare := a < b -> -1 or smaller
--            a = b -> 0
--            a > b -> +1 or bigger
create or replace function pgx_fraction_compare(a_p fraction, b_p fraction) returns integer as $$
declare n bigint;
declare d bigint;
begin
   n = (a_p).n * (b_p).d - (b_p).n * (a_p).d;
   d = (a_p).d * (b_p).d;
   if d <= 0 then
      if d = 0 then return 1/0; end if;
      return -n;
   else
      return n;
   end if;
end;
$$ language plpgsql immutable strict;


-- The comparison operators:
create or replace function pgx_fraction_eq(a_p fraction, b_p fraction) returns bool as $$
begin
   return 0 = pgx_fraction_compare(a_p, b_p);
end;
$$ language plpgsql immutable strict;

create or replace function pgx_fraction_ne(a_p fraction, b_p fraction) returns bool as $$
begin
   return 0 <> pgx_fraction_compare(a_p, b_p);
end;
$$ language plpgsql immutable strict;

create or replace function pgx_fraction_lt(a_p fraction, b_p fraction) returns bool as $$
begin
   return pgx_fraction_compare(a_p, b_p) < 0;
end;
$$ language plpgsql immutable strict;

create or replace function pgx_fraction_gt(a_p fraction, b_p fraction) returns bool as $$
begin
   return pgx_fraction_compare(a_p, b_p) > 0;
end;
$$ language plpgsql immutable strict;

create or replace function pgx_fraction_le(a_p fraction, b_p fraction) returns bool as $$
begin
   return pgx_fraction_compare(a_p, b_p) <= 0;
end;
$$ language plpgsql immutable strict;

create or replace function pgx_fraction_ge(a_p fraction, b_p fraction) returns bool as $$
begin
   return pgx_fraction_compare(a_p, b_p) >= 0;
end;
$$ language plpgsql immutable strict;


-- The most common mathematical operations:
-- (note that every operation reduces the result)
create or replace function pgx_fraction_negate(a_p fraction) returns fraction as $$
begin
   a_p := pgx_fraction_reduce(a_p);
   return  row(-(a_p).n, (a_p).d); 
end;
$$ language plpgsql immutable strict;

create or replace function pgx_fraction_add(a_p fraction, b_p fraction) returns fraction as $$
declare n bigint;
declare d bigint;
begin
   -- a / c + b / d = (a*d + b*c) / (d*c)  
   n = (a_p).n * (b_p).d + (b_p).n * (a_p).d;
   d = (a_p).d * (b_p).d;
   return pgx_fraction_reduce((n, d));
end;
$$ language plpgsql immutable strict;

create or replace function pgx_fraction_substract(a_p fraction, b_p fraction) returns fraction as $$
declare n bigint;
declare d bigint;
begin
   n = (a_p).n * (b_p).d - (b_p).n * (a_p).d;
   d = (a_p).d * (b_p).d;
   return pgx_fraction_reduce((n, d));
end;
$$ language plpgsql immutable strict;

create or replace function pgx_fraction_multiply(a_p fraction, b_p fraction) returns fraction as $$
declare n bigint;
declare d bigint;
begin
   n = (a_p).n * (b_p).n;
   d = (a_p).d * (b_p).d;
   return pgx_fraction_reduce((n, d)::fraction);
end;
$$ language plpgsql immutable strict;

create or replace function pgx_fraction_divide(a_p fraction, b_p fraction) returns fraction as $$
declare n bigint;
declare d bigint;
begin
   n = (a_p).n * (b_p).d;
   d = (a_p).d * (b_p).n;
   return pgx_fraction_reduce((n, d));
end;
$$ language plpgsql immutable strict;


-- The operators that go with the earlier defined functions:
create operator = (
  leftarg = fraction,
  rightarg = fraction,
  procedure = pgx_fraction_eq,
  negator = <>,
  hashes,
  merges
);

create operator <> (
  leftarg = fraction,
  rightarg = fraction,
  procedure = pgx_fraction_ne,
  negator = =,
  hashes,
  merges
);

create operator < (
  leftarg = fraction,
  rightarg = fraction,
  procedure = pgx_fraction_lt,
  negator = >=,
  hashes,
  merges
);

create operator > (
  leftarg = fraction,
  rightarg = fraction,
  procedure = pgx_fraction_gt,
  negator = <=,
  hashes,
  merges
);

create operator <= (
  leftarg = fraction,
  rightarg = fraction,
  procedure = pgx_fraction_le,
  negator = >,
  hashes,
  merges
);

create operator >= (
  leftarg = fraction,
  rightarg = fraction,
  procedure = pgx_fraction_ge,
  negator = <,
  hashes,
  merges
);


create operator - (
   rightarg = fraction,
   procedure = pgx_fraction_negate
);

create operator + (
   leftarg = fraction,
   rightarg = fraction,
   procedure = pgx_fraction_add
);

create operator - (
   leftarg = fraction,
   rightarg = fraction,
   procedure = pgx_fraction_substract
);

create operator * (
   leftarg = fraction,
   rightarg = fraction,
   procedure = pgx_fraction_multiply
);

create operator / (
   leftarg = fraction,
   rightarg = fraction,
   procedure = pgx_fraction_divide
);

-- The casting operators:
create cast (int as fraction)
with function pgx_fraction_from_int(int)
as assignment;

create cast (bigint as fraction)
with function pgx_fraction_from_bigint(bigint)
as assignment;

create cast (numeric as fraction)
with function pgx_fraction_from_numeric(numeric)
as assignment;

create cast (double precision as fraction)
with function pgx_fraction_from_double_precision(double precision)
as assignment;



create cast (fraction as numeric)
with function pgx_numeric_from_fraction(fraction)
as assignment;

create cast (fraction as double precision)
with function pgx_double_precision_from_fraction(fraction)
as assignment;



-- Assist type for aggregates:
create type fraction_accum as (
   cnt  int,       -- Number of aggregate steps taken
   sum  fraction,  -- sum so far
   sofs fraction   -- sum of the squares so far
);

-- Create this type for every step in the aggregate:
create or replace function pgx_fraction_accum(fraction_accum, fraction) returns fraction_accum as $$
   select case when $1 is null then 1 else $1.cnt + 1 end,
          case when $1 is null then $2 else $1.sum + $2 end,
          case when $1 is null then $2 * $2 else $1.sofs + $2 * $2 end;
$$ language sql;

create or replace function pgx_fraction_disaccum(fraction_accum, fraction) returns fraction_accum as $$
   select pgx_fraction_accum($1, -$2);
$$ language sql;

-- avg = sum(A) / count(A), cast count(A) as a fraction, since division by integer is not defined.
create or replace function pgx_fraction_avg(fraction_accum) returns fraction as $$
   select case when $1 is null then null
               when $1.cnt = 0 then (0,1)::fraction
               else $1.sum / $1.cnt::fraction end;
$$ language sql;


create aggregate sum(fraction) (
   SFUNC = pgx_fraction_add,
   STYPE = fraction,
   INITCOND = '(0, 1)'
   -- MSFUNC = pgx_fraction_add,
   -- MINVFUNC = pgx_fraction_subtract,
   -- MSTYPE = fraction,
   -- MINITCOND = '(0, 1)'
);

create aggregate avg(fraction) (
   SFUNC = pgx_fraction_accum,
   STYPE = fraction_accum,
   -- MSFUNC = pgx_fraction_accum,
   -- MINVFUNC = pgx_fraction_disaccum,
   -- MSTYPE = fraction_accum,
   FINALFUNC = pgx_fraction_avg
);

-- Feel free to implement the sum of squares here
