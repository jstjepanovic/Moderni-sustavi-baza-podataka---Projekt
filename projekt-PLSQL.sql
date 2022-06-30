---- PROCEDURE
create or replace procedure usluga_update_cijena 
(uslugaid number, ustanovaid number, novaci number)
is
    c number;
begin
    select count(*) into c from usluga 
    where usluga_id = uslugaid and ustanova_id = ustanovaid;
    
    if c = 1 then
        update usluga set cijena = novaci 
        where usluga_id = uslugaid and ustanova_id = ustanovaid;
        dbms_output.put_line('Cijena usluge je ažurirana.');
        commit;
    else
        raise_application_error(-20111, 'Usluga ne postoji');
    end if;
end;
/

create or replace procedure insert_update_lokacija(
    lokid in lokacija.lokacija_id%type,
    vadresa in lokacija.adresa%type,
    pbroj in lokacija.poštanski_broj%type,
    go in lokacija.grad_opæina%type,
    zup in lokacija.županija%type)
is
    c number;
begin
    select count(*) into c from lokacija where lokacija_id = lokid;
    if c = 0 then
        insert into lokacija values(lokid, vadresa, pbroj, go, zup);
        dbms_output.put_line('Lokacija s id-jem ' || lokid || ' je stvorena.');
        commit;
    else
        update lokacija set adresa = vadresa, poštanski_broj = pbroj,
        grad_opæina = go, županija = zup where lokacija_id = lokid;
        dbms_output.put_line('Lokacija s id-jem ' || lokid || ' je ažurirana.');
        commit;
    end if;
end;
/

call insert_update_lokacija(27, 'J. Huttlera 5', 31000, 'Osijek', 'Osjeèko-baranjska županija');

select * from lokacija where lokacija_id = 27;

call usluga_update_cijena(1,1,500);

create or replace procedure top_10_spenders as
    cursor c_spenders is 
        select ime, prezime, sum(cijena) as "Ukupna cijena usluga" 
        from korisnik join korištenje_usluge using (oib)
        join usluga using (usluga_id, ustanova_id)
        group by oib, ime, prezime
        order by sum(cijena) desc
        fetch first 10 rows only;
    r_spenders c_spenders%rowtype;
begin
    open c_spenders;
    
    loop
        fetch c_spenders into r_spenders;
        exit when c_spenders%notfound;
        dbms_output.put_line('Korisnik ' || r_spenders.ime
        || ' ' || r_spenders.prezime || ' je iskoristio/la usluge u vrijednosti '
        || r_spenders."Ukupna cijena usluga");
    end loop;
    
    close c_spenders;
end;
/

call top_10_spenders();

---- OKIDAÈI
create or replace trigger poštanski_broj_trigger 
before update or insert of poštanski_broj on lokacija for each row
begin
    if substr(:new.poštanski_broj, 1, 2) not in 
    ('10', '20', '21', '22', '23', '31' ,'32' ,'33', '35',
     '34', '40', '42', '43', '44', '47', '48', '49', '51', '52', '53') then
        raise_application_error('-20013', 'Nevaljali poštanski broj');
    end if;
end;
/

update lokacija set poštanski_broj = '85331' where lokacija_id = 2;

create or replace trigger usluga_cijena_max_trigger
before update or insert of cijena on usluga for each row
when (new.cijena > 200000)
begin
    raise_application_error('-20011', 'Previsoka cijena');
end;
/

update usluga set cijena = 250000 where usluga_id = 2;

---- FUNKCIJE
create or replace function 
work_experience(zapid zaposlenik.zaposlenik_id%type)
return int as 
    v_exp int;
begin
    select floor(months_between(sysdate, datum_zaposlenja)/12)
    into v_exp from zaposlenik
    where zaposlenik_id = zapid;
    return v_exp;
end;
/

select work_experience(5) from dual;

create or replace function
ustanova_korištenje_usluge_count(usid ustanova.ustanova_id%type)
return int as
    v_count int;
begin
    select count(*) into v_count from ustanova u join
    ustanova_korisnik uk on (u.ustanova_id = uk.ustanova_id)
    join korisnik using (oib)
    join korištenje_usluge using (oib) where u.ustanova_id = usid;
    return v_count;
end;
/

select ustanova_korištenje_usluge_count(40) from dual;


