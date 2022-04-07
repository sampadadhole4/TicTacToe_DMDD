set serveroutput on;
whenever sqlerror exit sql.sqlcode rollback;
declare
counts int;
begin
select count(*) into counts from user_tables where table_name ='T';
if counts =1
then
--execute immediate 'drop table T'; 
dbms_output.put_line('Table already exists'); else
execute immediate 'CREATE TABLE T (
c NUMBER,
X CHAR,
Y CHAR,
Z CHAR
)';
end if;
end;
/
--CREATE TABLE T ( --c NUMBER,
--X CHAR,
--Y CHAR,
--Z CHAR --);
--Inserting null values to T
INSERT INTO T(c,X,Y,Z) VALUES(1,null,null,null);
 INSERT INTO T(c,X,Y,Z) VALUES(2,null,null,null); INSERT INTO T(c,X,Y,Z) VALUES(3,null,null,null);
--This procedure is to convert column to character
CREATE or replace FUNCTION chartocol(temp IN NUMBER) RETURN CHAR
IS
BEGIN
IF temp=1 THEN
RETURN 'X';
ELSIF temp=2 THEN
RETURN 'Y';
ELSIF temp=3 THEN
RETURN 'Z';
ELSE
RETURN '_';
END IF;
END;
/
--This procedure is to print the game
CREATE or replace PROCEDURE boards AS
BEGIN
dbms_output.enable(10000);
dbms_output.put_line(' ');
FOR i in (SELECT * FROM T ORDER BY C) LOOP dbms_output.put_line(' ' || i.X || ' ' || i.Y || ' ' || i.Z);
END LOOP;
dbms_output.put_line(' ');
END;
/
--This procedure is to reset the values when the game is over 
CREATE or replace PROCEDURE set_null AS
j INT;
BEGIN
DELETE FROM T;
FOR j in 1..3 LOOP

 INSERT INTO T VALUES (j,'_','_','_'); END LOOP; dbms_output.enable(10000); boards();
dbms_output.put_line('To Play : EXECUTE play(''X'', x, y);'); END;
/
Create or replace procedure playermove(turn IN VARCHAR2, tmp in number) as
novalidmove exception; novalidcolumn exception; novalidrow exception;
pragma exception_init(novalidmove, -20001);
begin
if turn not in ('X','O') then
--rollback;
raise_application_error(-20001,'invalid player',False); end if;
end;
/
--This preocedure checks for invalid column
create or replace procedure invalidcolumn(chars in number) as novalidcolumn exception;
pragma exception_init(novalidcolumn, -20001);
begin
if chars not in (1,2,3) then raise_application_error(-20001,'invalid column');
end if;
end;
/
--This procedure plays the main part
CREATE or replace PROCEDURE main_game(chance IN VARCHAR2, chars IN NUMBER, tmp IN NUMBER) IS
temp T.x%type;

 chartocharr CHAR; chance2 CHAR; --gvar_test.counts int; 
 BEGIN
SELECT chartocol(chars) INTO chartocharr FROM DUAL;
begin
invalidcolumn(chars);
EXECUTE IMMEDIATE ('SELECT ' || chartocharr || ' FROM T WHERE c=' || tmp) INTO temp;
exception
when no_data_found then
--dbms_output.put_line('You have entered out of index values'); 
raise_application_error(-20001,'You have entered out of index values');
end;
IF temp='_' THEN
EXECUTE IMMEDIATE ('UPDATE T SET ' || chartocharr || '=''' || chance || ''' WHERE c=' || tmp);
playermove(chance,tmp);
IF chance='X' THEN
chance2:='O';
ELSE
chance2:='X';
END IF;
boards();
dbms_output.put_line('For ' || chance2 || '. to play : EXECUTE play(''' || chance2 || ''', x, y);');
ELSE
dbms_output.enable(10000);
dbms_output.put_line('You cannot play this square, it is already played');
END IF;
--gvar_test.counts := gvar_test.counts+1;
END;
/

--This procedure is to find the winner of the game
CREATE or replace PROCEDURE champ(chance IN VARCHAR2) IS BEGIN

 dbms_output.enable(10000);
boards();
dbms_output.put_line('The player ' || chance || ' won !!'); 
dbms_output.put_line('---------------------------------------'); 
dbms_output.put_line('Starting a new game...'); 
set_null();
END; 
/
--This procedure is to find the winner column request
CREATE or replace FUNCTION champ_column(columchar IN VARCHAR2, chance IN VARCHAR2)
RETURN VARCHAR2
IS
BEGIN
RETURN ('SELECT COUNT(*) FROM T WHERE ' || columchar || ' = '''|| chance ||''' AND ' || columchar || ' != ''_''');
END;
/
--This procedure is to find the diagonal column request
CREATE or replace FUNCTION diag_col(columchar IN VARCHAR2, temp IN NUMBER)
RETURN VARCHAR2
IS
BEGIN
RETURN ('SELECT '|| columchar ||' FROM T WHERE c=' || temp);
END;
/
CREATE or replace FUNCTION champ_col(columchar IN VARCHAR2) RETURN CHAR
IS
temp1 NUMBER;
rems VARCHAR2(256); BEGIN

 SELECT champ_column(columchar, 'X') into rems FROM DUAL; EXECUTE IMMEDIATE rems INTO temp1;
IF temp1=3 THEN
RETURN 'X';
ELSIF temp1=0 THEN
SELECT champ_column(columchar, 'O') into rems FROM DUAL; EXECUTE IMMEDIATE rems INTO temp1;
IF temp1=3 THEN
RETURN 'O';
END IF;
END IF;
RETURN '_';
END;
/
--to find the diagonal
CREATE or replace FUNCTION diagonal(temp IN CHAR, var1 IN NUMBER, numtemp IN NUMBER)
RETURN CHAR
IS
temp2 CHAR;
temp3 CHAR;
rems VARCHAR2(256);
BEGIN
SELECT diag_col(chartocol(var1), numtemp) INTO rems FROM DUAL;
IF temp IS NULL THEN
EXECUTE IMMEDIATE (rems) INTO temp3;
ELSIF NOT temp = '_' THEN
EXECUTE IMMEDIATE (rems) INTO temp2;
IF NOT temp = temp2 THEN
temp3 := '_';
END IF;
ELSE
temp3 := '_';
END IF;
RETURN temp3;
END;

 /
--Trigger is applied whenever we update any value on table T 
CREATE or replace TRIGGER champion
AFTER UPDATE ON T
DECLARE
--gvar_test.counts number; 
CURSOR cur IS
SELECT * FROM T ORDER BY c; 
curs T%rowtype;
temp2 CHAR;
temp1 CHAR;
temp3 CHAR;
rems VARCHAR2(40); flag int :=-1;
BEGIN
FOR curs IN cur LOOP
IF curs.X = curs.Y AND curs.Y = curs.Z AND NOT curs.X='_' THEN champ(curs.X);
EXIT;
END IF;
SELECT champ_col(chartocol(curs.c)) INTO temp2 FROM DUAL; IF NOT temp2 = '_' THEN
champ(temp2);
EXIT;
END IF;
SELECT diagonal(temp1, curs.c, curs.c) INTO temp1 FROM dual; SELECT diagonal(temp3, 4-curs.c, curs.c) INTO temp3 FROM dual; END LOOP;
IF NOT temp1 = '_' THEN
champ(temp1);
flag := 1;
END IF;
IF NOT temp3 = '_' THEN
champ(temp3);
flag :=1;
END IF;

END; 
/




EXECUTE set_null;
EXECUTE main_game('X', 1, 1); 
EXECUTE main_game('O', 2, 1); 
EXECUTE main_game('X', 2, 2); 
EXECUTE main_game('O', 3, 1); 
EXECUTE main_game('X', 3, 3);