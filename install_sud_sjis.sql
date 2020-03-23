create table SUD_table(table_id int primary key, table_name text unique not null);

create or replace function SUD(command text) returns void as
$cf$
    declare 
        table_id int;
        table_name text;
        data_id int; wanted_data_id int; Q text; A text;
    begin
        if command ~* ws_pattern_ws('�\(?:�u)?[^�v]*(?:�v)?��(?:(?:(?:��|��|�n|(?:��))��)|(?:�쐬(?:����)?))') then -- �\�����R�}���h
            table_id := SUD_get_new_table_id();
            table_name := substring(command from ws_pattern_ws('�\(?:�u)?([^�v]*)(?:�v)?��(?:(?:(?:��|��|�n|(?:��))��)|(?:�쐬(?:����)?))'));
            execute 'create table SUD_'||table_id||'(data_id bigint, Q text, A text)';
            execute 
            $exe$
                insert into SUD_table values($exe$||table_id||$exe$, '$exe$||table_name||$exe$') 
            $exe$;
            raise notice '�\%�̍쐬�ɐ������܂���(�e�[�u��ID: %)', table_name, table_id;
            return;
        elsif command ~* ws_pattern_ws('.*\|.*\|.*\|.*') then -- �\�ɖ��ⓚ�����u�ԍ����w�肵�āv�ǉ�����R�}���h
            table_name := cut_both_ws(substring(command from ws_pattern_ws('(.*)\|.*\|.*\|.*')));
            wanted_data_id := cut_both_ws(substring(command from ws_pattern_ws('.*\|(.*)\|.*\|.*')));
            Q := cut_both_ws(substring(command from ws_pattern_ws('.*\|.*\|(.*)\|.*')));
            A := cut_both_ws(substring(command from ws_pattern_ws('.*\|.*\|.*\|(.*)')));
            table_id := get_id_from_name(table_name);
            if table_id is null then raise exception '�\�u%�v�͑��݂��܂���B', table_name; end if;
            data_id := SUD_get_new_data_id(table_id); 
            if wanted_data_id < data_id then
                execute 'update SUD_'||table_id||' SET data_id = data_id + 1 WHERE data_id >= '||wanted_data_id;
                execute 'insert into SUD_'||table_id||' values('||wanted_data_id||', $q$'||Q||'$q$, $a$'||A||'$a$)';
                execute 'create table SUD_tmp as select row_number() over(order by data_id) as data_id, q, a from SUD_'||table_id;
                execute 'drop table SUD_'||table_id;
                execute 'create table SUD_'||table_id||' as select * from SUD_tmp';
                execute 'drop table SUD_tmp';
            elsif wanted_data_id = data_id then
                execute 'insert into SUD_'||table_id||' values('||wanted_data_id||', $q$'||Q||'$q$, $a$'||A||'$a$)';
            elsif wanted_data_id > data_id then
                raise exception '���ԍ����W�����v�����邱�Ƃ͂ł��܂���';
            end if;
            raise notice '�\�u%�v�ɁA���(ID: %)��ǉ����܂����B', table_name, wanted_data_id;
            raise notice '�ڍ�: ���u%�v, �����u%�v', Q, A;
            return;
        elsif command ~* ws_pattern_ws('.*\|.*\|.*') then -- �\�ɖ��ⓚ����ǉ�����R�}���h
            table_name := cut_both_ws(substring(command from ws_pattern_ws('(.*)\|.*\|.*')));
            Q := cut_both_ws(substring(command from ws_pattern_ws('.*\|(.*)\|.*')));
            A := cut_both_ws(substring(command from ws_pattern_ws('.*\|.*\|(.*)')));
            table_id := get_id_from_name(table_name);
            if table_id is null then raise exception '�\�u%�v�͑��݂��܂���B', table_name; end if;
            data_id := SUD_get_new_data_id(table_id);
            raise notice '�\�u%�v�ɁA���(ID: %)��ǉ����܂����B', table_name, data_id;
            raise notice '�ڍ�: ���u%�v, �����u%�v', Q, A;
            execute 'insert into SUD_'||table_id||' values('||data_id||', $q$'||Q||'$q$, $a$'||A||'$a$)';
            return;
        elsif command ~* ws_pattern_ws('.*����id.*�̖����폜') then -- �\����f�[�^(id�Ŏw��)���폜����R�}���h
            table_name := cut_both_ws(substring(command from ws_pattern_ws('(.*)����id.*�̖����폜')));
            table_id := get_id_from_name(table_name);
            if table_id is null then raise exception '�\�u%�v�͑��݂��܂���B', table_name; end if;
            data_id := cut_both_ws(substring(command from ws_pattern_ws('.*����id(.*)�̖����폜')));
            execute 'delete from SUD_'||table_id||' where data_id='||data_id;
            execute 'create table SUD_tmp as select row_number() over(order by data_id) as data_id, q, a from SUD_'||table_id;
            execute 'drop table SUD_'||table_id;
            execute 'create table SUD_'||table_id||' as select * from SUD_tmp';
            execute 'drop table SUD_tmp';
            return;
        elsif command ~* ws_pattern_ws('.*���폜') then -- �\���ۂ��ƍ폜����R�}���h
            table_name := cut_both_ws(substring(command from ws_pattern_ws('(.*)���폜')));
            table_id := get_id_from_name(table_name);
            if table_id is null then raise exception '�\�u%�v�͑��݂��܂���B', table_name; end if;
            execute 'drop table SUD_'||table_id;
            execute 'delete from SUD_table where table_id = '||table_id;
            raise notice '�\�u%�v���폜���܂���', table_name
            return;
        else
            raise exception '�R�}���h���F���ł��܂���ł����B';
            return;
        end if;
    end;
$cf$ language plpgsql;

create or replace function SUD_see_table(table_name text) returns table(data_id bigint, Q text, A text) as
$cf$
    begin
        return query execute 'select * from SUD_'||get_id_from_name(table_name);
    end;
$cf$ language plpgsql;

create or replace function SUD_see_Q(table_name text, data_id int) returns text as
$cf$
    declare txt text;
    begin
        execute 'select Q from SUD_see_table($$'||table_name||'$$) where data_id='||data_id into txt;
        return txt;
    end;
$cf$ language plpgsql;

create or replace function SUD_see_A(table_name text, data_id int) returns text as
$cf$
    declare txt text;
    begin
        execute 'select A from SUD_see_table($$'||table_name||'$$) where data_id='||data_id into txt;
        return txt;
    end;
$cf$ language plpgsql;

create or replace function SUD_see_table(table_id int) returns table(data_id bigint, Q text, A text) as
$cf$
    begin
        return query execute 'select * from SUD_'||table_id;
    end;
$cf$ language plpgsql;

create or replace function SUD_see_Q(table_id int, data_id int) returns text as
$cf$
    declare txt text;
    begin
        execute 'select Q from SUD_see_table('||table_id||') where data_id='||data_id into txt;
        return txt;
    end;
$cf$ language plpgsql;

create or replace function SUD_see_A(table_id int, data_id int) returns text as
$cf$
    declare txt text;
    begin
        execute 'select A from SUD_see_table('||table_id||') where data_id='||data_id into txt;
        return txt;
    end;
$cf$ language plpgsql;

    create function SUD_get_new_table_id() returns int as
    $cf$
        declare m int;
        begin
            select into m max(table_id) from SUD_table;
            if m is null then m := 0; end if;
            return m+1;
        end;
    $cf$ language plpgsql;

    create function ws_pattern_ws(pattern text) returns text as
    $cf$ select '^(?:(?: |\t|\r|\n)*)'||pattern||'(?:(?: |\t|\r|\n)*)$' $cf$ language sql;

    create function cut_both_ws(str text) returns text as
    $cf$ select substring(str from '^(?:(?: |\t|\r|\n)*)((?:[^ \t\r\n].*[^ \t\r\n])|[^ \t\r\n])(?:(?: |\t|\r|\n)*)$'); $cf$ language sql;

    create function SUD_get_new_data_id(table_id int) returns int as
    $cf$
        declare m int;
        begin
            execute 'select max(data_id) from SUD_'||table_id 
            into m;
            if m is null then m := 0; end if;
            return m+1;
        end;
    $cf$ language plpgsql;

    create function get_id_from_name(table_name text) returns int as
    $cf$
        declare i int;
        begin
            execute $exe$ select table_id from SUD_table where table_name='$exe$||table_name||$exe$'$exe$ into i;
            return i; 
        end;
    $cf$ language plpgsql;

    create function get_name_from_id(table_id int) returns text as
    $cf$
        declare t text;
        begin
            execute $exe$ select table_name from SUD_table where table_id='$exe$||table_id||$exe$'$exe$ into t;
            return t; 
        end;
    $cf$ language plpgsql;