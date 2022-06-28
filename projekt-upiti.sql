---- JEDNOSTAVNI UPITI

-- pronaći ime i prezime zaposlenika koji su zaposleni duže od 5 godina
select ime || ' ' || prezime as "Ime i prezime", datum_zaposlenja from zaposlenik where floor(months_between(sysdate, datum_zaposlenja)/12) > 5;

-- pronaći sve korisnike s prezimenom Kralj
select * from korisnik where prezime = 'Kralj';

-- pronaći sve usluge koje se barem u nekoj ustanovi mogu naći za cijenu od ispod 100 kuna
select distinct naziv from usluga where cijena < 100;

-- pronaći sve lokacije u Vukovarsko-srijemskoj županiji
select adresa, poštanski_broj, grad_općina from lokacija where županija = 'Vukovarsko-srijemska županija';

-- pronaći naziv i kontakt svih ustanova primarne razine
select naziv, kontakt from ustanova where razina = 'Primarna';

---- SLOŽENI UPITI

-- pronaći sve korisnike koji su koristili usluge ustanove na području Osječko-baranjske županije
select distinct ime || ' ' || prezime as "Ime i prezime"
    from korisnik join korištenje_usluge using (oib) join usluga us using (usluga_id, ustanova_id) join ustanova u using (ustanova_id)
    join ustanova_lokacija using (ustanova_id) join lokacija using (lokacija_id) where županija = 'Osječko-baranjska županija';  

-- pronaći ime kirurga i sve korisnike usluga kirurga na KBC-u Sestre milosrdnice
select distinct z.ime || ' ' || z.prezime as "Kirurg", k.ime || ' ' || k.prezime as "Korisnik" from zaposlenik z join korištenje_usluge using (zaposlenik_id) join korisnik k using (oib)
    join ustanova u on (u.ustanova_id = z.ustanova_id)
    where uloga = 'kirurg' and u.naziv = 'Klinički bolnički centar Sestre milosrdnice';

-- pronaći sve zaposlenike ustanova sekundarne razine zaposlene između 2011. i 2021.
select ime || ' ' || prezime as "Ime i prezime", datum_zaposlenja from ustanova join zaposlenik using (ustanova_id)
    where razina = 'Sekundarna' and extract (year from datum_zaposlenja) between 2011 and 2021;
    
-- pronaći sve usluge koje nude ustanove tercijarne razine
select distinct us.naziv from usluga us join ustanova using (ustanova_id) where razina = 'Tercijarna';

-- pronaći sve korisnike, usluge, ustanove i datume korištenja usluga cijene veće il jednake 500 kn
select k.ime || ' ' || k.prezime as "Korisnik", us.naziv, u.naziv, datum_usluge
    from korištenje_usluge ku join korisnik k on (ku.oib = k.oib) join usluga us using (usluga_id, ustanova_id) join ustanova u using (ustanova_id)
    where cijena >= 500; 
    
---- AGREGATNE FUNKCIJE

-- izračunati prosječnu cijenu usluga na KBC-u Osijek
select avg(cijena) from usluga join ustanova u using (ustanova_id) where u.naziv = 'Klinički bolnički centar Osijek';

-- prosječan broj korištenja usluga (za korisnike koji su koristili usluge barem jednom)
select round(avg(count(ku.oib)),2) as "Prosjek" from korištenje_usluge ku join korisnik k on (k.oib = ku.oib) group by ku.oib;

-- ukupni iznos cijena korištenja usluga za korisnike bez osiguranja
select sum(cijena) as "Ukupna cijena" from korištenje_usluge join usluga using(usluga_id, ustanova_id) where osiguranje = 'Ne';

-- najveći ukupni iznos usluga jedne osobe
select max(sum(cijena)) as "Max" from korištenje_usluge join usluga using(usluga_id, ustanova_id) group by oib;

-- broj ustanova u Dubrovačko-neretvanskoj županiji
select count(*) as "Broj ustanova" from ustanova join ustanova_lokacija using (ustanova_id) join lokacija using (lokacija_id) where županija = 'Dubrovačko-neretvanska županija';

---- PODUPITI
-- usluge iz baze koje su korištene samo jednom
select distinct usluga_id, naziv from usluga where usluga_id in (select usluga_id from korištenje_usluge group by usluga_id having count(*) = 1);

-- ime, prezime i email korisnika koji su koristili usluge u vrijednosti manjoj od 500 i većoj od 3000 
select ime, prezime, email from 
    (select ime, prezime, email, nvl(sum(cijena), 0) as "Ukupna cijena" from korisnik left join korištenje_usluge using (oib)
    left join usluga using (ustanova_id, usluga_id) group by ime, prezime, oib, email)
    where "Ukupna cijena" < 500 or "Ukupna cijena" > 3000;
    
-- sve usluge kojima je cijena veća od prosječne cijene u ustanovi 
select us.naziv as "Ustanova", u2.naziv as "Usluga", cijena,
    round((select avg(cijena) from usluga u1 where u1.ustanova_id = u2.ustanova_id), 2) as "Proječna cijena usluge u ustanovi" 
    from usluga u2 join ustanova us on (us.ustanova_id = u2.ustanova_id) 
    where cijena > round((select avg(cijena) from usluga u1 where u1.ustanova_id = u2.ustanova_id), 2);

-- svi zaposlenici ustanova sekundarne razine koji su barem jednom davali usluge
select ime, prezime, datum_zaposlenja from ustanova join zaposlenik using (ustanova_id) where razina = 'Sekundarna'
intersect
select distinct ime, prezime, datum_zaposlenja from zaposlenik join korištenje_usluge using (zaposlenik_id);

-- ime i prezime zaposlenika koji su dali usluge ukupne cijene preko 1000
select ime, prezime from zaposlenik where zaposlenik_id in
    (select zaposlenik_id from korištenje_usluge join usluga using (usluga_id, ustanova_id) group by zaposlenik_id having sum(cijena) > 1000)
    order by 2, 1;

---- KOMENTARI
comment on table korisnik is 'korisnik usluga ustanova';
comment on table korištenje_usluge is 'tablica korištenja usluga(tko je koristio koju uslugu kada, gdje i kod kojeg zaposlenika)';
comment on table lokacija is 'točna lokacija ustanova';
comment on table zaposlenik is 'osobe zaposlene u ustanovama';
comment on table ustanova is 'zdravstvena ustanova';
comment on column korištenje_usluge.osiguranje is 'ima li korisnik zdravstveno osiguranje';

---- INDEXI
-- B-tree index
create index i_korisnik_ime_prezime on korisnik(ime, prezime);
create index i_zaposlenik_ime_prezime on zaposlenik(ime, prezime);

-- Bitmap index
create bitmap index i_korištenje_usluge_osiguranje on korištenje_usluge(osiguranje);
create bitmap index i_ustanova_razina on ustanova(razina);
