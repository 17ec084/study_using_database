create table SUD_table(table_id int primary key, table_name text unique not null);

create function SUD(command text) returns void as
$cf$
    declare 
        table_id int;
        table_name text;
        data_id int; Q int; A int;
    begin
        if command ~* ws_pattern_ws('表「.*」を(?:作|造|創|(?:つく))る') then -- 表を作るコマンド
            table_id := SUD_get_new_table_id();
            table_name := substring(command from ws_pattern_ws('表「(.*)」を(?:作|造|創|(?:つく))る'));
            execute 'create table SUD_'||table_id||'(data_id int, Q text, A text)';
            execute 
            $exe$
                insert into SUD_table values($exe$||table_id||$exe$, '$exe$||table_name||$exe$') 
            $exe$;
            return;
        elsif command ~* ws_pattern_ws('.*\|.*\|.*') then -- 表に問題や答えを追加するコマンド
            table_name := cut_both_ws(substring(command from ws_pattern_ws('(.*)\|.*\|.*')));
            Q := cut_both_ws(substring(command from ws_pattern_ws('.*\|(.*)\|.*')));
            A := cut_both_ws(substring(command from ws_pattern_ws('.*\|.*\|(.*)')));
            table_id := get_id_from_name(table_name);
            if table_id is null then raise exception '表%は存在しません。', table_name; end if;
            data_id := SUD_get_new_data_id(table_id);
            execute 'insert into SUD_'||table_id||' values('||data_id||', '||Q||', '||A||')';
            return;
        elsif command ~* ws_pattern_ws('.*からid.*の問題を削除') then -- 表からデータ(idで指定)を削除するコマンド
            table_name := cut_both_ws(substring(command from ws_pattern_ws('(.*)からid.*の問題を削除')));
            table_id := get_id_from_name(table_name);
            if table_id is null then raise exception '表%は存在しません。', table_name; end if;
            data_id := cut_both_ws(substring(command from ws_pattern_ws('.*からid(.*)の問題を削除')));
            execute 'delete from SUD_'||table_id||' where data_id='||data_id;
        elsif command ~* ws_pattern_ws('.*を削除') then -- 表を丸ごと削除するコマンド
            table_name := cut_both_ws(substring(command from ws_pattern_ws('(.*)を削除')));
            table_id := get_id_from_name(table_name);
            if table_id is null then raise exception '表%は存在しません。', table_name; end if;
            execute 'drop table SUD_'||table_id;
        else
            raise exception 'コマンドが認識できませんでした。';
        end if;
    end;
$cf$ language plpgsql;

create function SUD_see_table(table_name text) returns table(data_id int, Q text, A text) as
$cf$
    begin
        return query execute 'select * from SUB_'||get_id_from_name(table_name);
    end;
$cf$ language plpgsql;

create function SUD_see_Q(table_name text, data_id int) returns text as
$cf$
    declare txt text;
    begin
        execute 'select Q from SUD_see_table('||table_name||') where data_id='||data_id into txt;
        return txt;
    end;
$cf$ language plpgsql;

create function SUD_see_A(table_name text, data_id int) returns text as
$cf$
    declare txt text;
    begin
        execute 'select A from SUD_see_table('||table_name||') where data_id='||data_id into txt;
        return txt;
    end;
$cf$ language plpgsql;

create function SUD_see_table(table_id int) returns table(data_id int, Q text, A text) as
$cf$
    begin
        return query execute 'select * from SUB_'||table_id;
    end;
$cf$ language plpgsql;

create function SUD_see_Q(table_id int, data_id int) returns text as
$cf$
    declare txt text;
    begin
        execute 'select Q from SUD_see_table('||table_id||') where data_id='||data_id into txt;
        return txt;
    end;
$cf$ language plpgsql;

create function SUD_see_A(table_id int, data_id int) returns text as
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
    $cf$ select substring(str from '^(?:(?: |\t|\r|\n)*)([^ \t\r\n].*[^ \t\r\n])(?:(?: |\t|\r|\n)*)$'); $cf$ language sql;

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