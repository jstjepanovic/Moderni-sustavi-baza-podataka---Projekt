---- JEDNOSTAVNI UPITI

-- prona�i ime i prezime zaposlenika koji su zaposleni du�e od 5 godina
select ime || ' ' || prezime as "Ime i prezime", datum_zaposlenja from zaposlenik where floor(months_between(sysdate, datum_zaposlenja)/12) > 5;

-- prona�i sve korisnike s prezimenom Kralj
select * from korisnik where prezime = 'Kralj';

-- prona�i sve usluge koje se barem u nekoj ustanovi mogu na�i za cijenu od ispod 100 kuna
select distinct naziv from usluga where cijena < 100;

-- prona�i sve lokacije u Vukovarsko-srijemskoj �upaniji
select adresa, po�tanski_broj, grad_op�ina from lokacija where �upanija = 'Vukovarsko-srijemska �upanija';

-- prona�i naziv i kontakt svih ustanova primarne razine
select naziv, kontakt from ustanova where razina = 'Primarna';

---- SLO�ENI UPITI

-- prona�i sve korisnike koji su koristili usluge ustanove na podru�ju Osje�ko-baranjske �upanije
select distinct ime || ' ' || prezime as "Ime i prezime"
    from korisnik join kori�tenje_usluge using (oib) join usluga us using (usluga_id, ustanova_id) join ustanova u using (ustanova_id)
    join ustanova_lokacija using (ustanova_id) join lokacija using (lokacija_id) where �upanija = 'Osje�ko-baranjska �upanija';  

-- prona�i ime kirurga i sve korisnike usluga kirurga na KBC-u Sestre milosrdnice
select distinct z.ime || ' ' || z.prezime as "Kirurg", k.ime || ' ' || k.prezime as "Korisnik" from zaposlenik z join kori�tenje_usluge using (zaposlenik_id) join korisnik k using (oib)
    join ustanova u on (u.ustanova_id = z.ustanova_id)
    where uloga = 'kirurg' and u.naziv = 'Klini�ki bolni�ki centar Sestre milosrdnice';

-- prona�i sve zaposlenike ustanova sekundarne razine zaposlene izme�u 2011. i 2021.
select ime || ' ' || prezime as "Ime i prezime", datum_zaposlenja from ustanova join zaposlenik using (ustanova_id)
    where razina = 'Sekundarna' and extract (year from datum_zaposlenja) between 2011 and 2021;
    
-- prona�i sve usluge koje nude ustanove tercijarne razine
select distinct us.naziv from usluga us join ustanova using (ustanova_id) where razina = 'Tercijarna';

-- prona�i sve korisnike, usluge, ustanove i datume kori�tenja usluga cijene ve�e il jednake 500 kn
select k.ime || ' ' || k.prezime as "Korisnik", us.naziv, u.naziv, datum_usluge
    from kori�tenje_usluge ku join korisnik k on (ku.oib = k.oib) join usluga us using (usluga_id, ustanova_id) join ustanova u using (ustanova_id)
    where cijena >= 500; 
    
---- AGREGATNE FUNKCIJE

-- izra�unati prosje�nu cijenu usluga na KBC-u Osijek
select avg(cijena) from usluga join ustanova u using (ustanova_id) where u.naziv = 'Klini�ki bolni�ki centar Osijek';

-- prosje�an broj kori�tenja usluga (za korisnike koji su koristili usluge barem jednom)
select round(avg(count(ku.oib)),2) as "Prosjek" from kori�tenje_usluge ku join korisnik k on (k.oib = ku.oib) group by ku.oib;

-- ukupni iznos cijena kori�tenja usluga za korisnike bez osiguranja
select sum(cijena) as "Ukupna cijena" from kori�tenje_usluge join usluga using(usluga_id, ustanova_id) where osiguranje = 'Ne';

-- najve�i ukupni iznos usluga jedne osobe
select max(sum(cijena)) as "Max" from kori�tenje_usluge join usluga using(usluga_id, ustanova_id) group by oib;

-- broj ustanova u Dubrova�ko-neretvanskoj �upaniji
select count(*) as "Broj ustanova" from ustanova join ustanova_lokacija using (ustanova_id) join lokacija using (lokacija_id) where �upanija = 'Dubrova�ko-neretvanska �upanija';

---- PODUPITI
-- usluge iz baze koje su kori�tene samo jednom
select distinct usluga_id, naziv from usluga where usluga_id in (select usluga_id from kori�tenje_usluge group by usluga_id having count(*) = 1);

-- ime, prezime i email korisnika koji su koristili usluge u vrijednosti manjoj od 500 i ve�oj od 3000 
select ime, prezime, email from 
    (select ime, prezime, email, nvl(sum(cijena), 0) as "Ukupna cijena" from korisnik left join kori�tenje_usluge using (oib)
    left join usluga using (ustanova_id, usluga_id) group by ime, prezime, oib, email)
    where "Ukupna cijena" < 500 or "Ukupna cijena" > 3000;
    
-- sve usluge kojima je cijena ve�a od prosje�ne cijene u ustanovi 
select us.naziv as "Ustanova", u2.naziv as "Usluga", cijena,
    round((select avg(cijena) from usluga u1 where u1.ustanova_id = u2.ustanova_id), 2) as "Proje�na cijena usluge u ustanovi" 
    from usluga u2 join ustanova us on (us.ustanova_id = u2.ustanova_id) 
    where cijena > round((select avg(cijena) from usluga u1 where u1.ustanova_id = u2.ustanova_id), 2);

-- svi zaposlenici ustanova sekundarne razine koji su barem jednom davali usluge
select ime, prezime, datum_zaposlenja from ustanova join zaposlenik using (ustanova_id) where razina = 'Sekundarna'
intersect
select distinct ime, prezime, datum_zaposlenja from zaposlenik join kori�tenje_usluge using (zaposlenik_id);

-- ime i prezime zaposlenika koji su dali usluge ukupne cijene preko 1000
select ime, prezime from zaposlenik where zaposlenik_id in
    (select zaposlenik_id from kori�tenje_usluge join usluga using (usluga_id, ustanova_id) group by zaposlenik_id having sum(cijena) > 1000)
    order by 2, 1;


