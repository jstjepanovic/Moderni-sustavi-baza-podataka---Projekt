drop table korištenje_usluge;
drop table usluga;
drop table zaposlenik;
drop table ustanova_korisnik;
drop table korisnik;
drop table ustanova_lokacija;
drop table ustanova;
drop table služba;
drop table sektor;
drop table zavodi_i_agencije;
drop table uprava;
drop table ministarstvo;
drop table lokacija;

create table ministarstvo
(
    ministarstvo_id number(2) constraint ministarstvo_pk primary key,
    naziv varchar2(100) not null,
    ministar varchar2(30) not null,
    kontakt varchar2(30) not null
);

create table uprava
(
    uprava_id number(2) constraint uprava_pk primary key,
    naziv varchar2(200) not null,
    ravnatelj varchar2(30) not null,
    kontakt varchar2(30) not null,
    ministarstvo_id number(2) not null constraint ministarstvo_uprava_fk references ministarstvo(ministarstvo_id)
);

create table zavodi_i_agencije
(
    zavod_agencija_id number(2) constraint zavod_agencija_pk primary key,
    naziv varchar2(200) not null,
    ravnatelj varchar2(30) not null,
    kontakt varchar2(30) not null,
    ministarstvo_id number(2) not null constraint ministarstvo_zavod_agencija_fk references ministarstvo(ministarstvo_id)
);

create table sektor
(
    sektor_id number(2) constraint sektor_pk primary key,
    naziv varchar2(200) not null,
    naèelnik varchar2(30) not null,
    kontakt varchar2(30) not null,
    uprava_id number(2) not null constraint uprava_sektor_fk references uprava(uprava_id)
);

create table služba
(
    služba_id number(2) constraint služba_pk primary key,
    naziv varchar2(200) not null,
    voditelj varchar2(30) not null,
    kontakt varchar2(30) not null,
    sektor_id number(2) constraint sektor_služba_fk references sektor(sektor_id),
    zavod_agencija_id number(2) constraint zavod_agencija_služba_fk references zavodi_i_agencije(zavod_agencija_id)
);
-- pobrinuti se za luk kod veza
alter table služba add constraint sektor_zavodi_i_agencije_služba_arc
check
(
    ( case when sektor_id is null then 0 else 1 end
    + case when zavod_agencija_id is null then 0 else 1 end
    ) = 1
);

create table lokacija 
(
    lokacija_id integer constraint lokacija_pk primary key,
    adresa varchar2(200) not null,
    poštanski_broj char(5) not null,
    grad_opæina varchar(50) not null,
    županija varchar(50) not null
);

create table ustanova
(
    ustanova_id number(4) constraint ustanova_pk primary key,
    razina varchar(10) not null,
    naziv varchar(200) not null,
    kontakt varchar2(30) not null,
    opis varchar2(200),
    ministarstvo_id number(2) not null constraint ministarstvo_ustanova_fk references ministarstvo(ministarstvo_id)
);

create table ustanova_lokacija
(
    lokacija_id integer not null constraint lokacija_fk_ustanova_lokacija references lokacija(lokacija_id),
    ustanova_id number(4) not null constraint ustanova_fk_ustanova_lokacija references ustanova(ustanova_id),
    constraint ustanova_lokacija_pk primary key(lokacija_id, ustanova_id)
);

create table korisnik
(
    OIB varchar2(11) not null constraint korisnik_pk primary key constraint OIB_length check (length(OIB) = 11),
    ime varchar2(50) not null,
    prezime varchar2(50) not null,
    email varchar2(50) not null
);

create table ustanova_korisnik
(
    OIB varchar2(11) not null constraint OIB_fk_ustanova_korisnik references korisnik(OIB),
    ustanova_id number(4) not null constraint ustanova_fk_ustanova_korisnik references ustanova(ustanova_id),
    constraint ustanova_korisnik_pk primary key(OIB, ustanova_id)
);

create table zaposlenik
(
    zaposlenik_id integer not null constraint zaposlenik_pk primary key,
    ime varchar2(30) not null,
    prezime varchar2(30) not null,
    email varchar2(50) not null,
    datum_zaposlenja date not null,
    uloga varchar2(30) not null,
    broj_telefona varchar2(20),
    ustanova_id number(4) constraint ustanova_zaposlenik_fk references ustanova(ustanova_id),
    služba_id number(2) constraint služba_zaposlenik_fk references služba(služba_id)
);
-- pobrinuti se za luk kod veza
alter table zaposlenik add constraint ustanova_služba_zaposlenik_arc
check
(
    ( case when ustanova_id is null then 0 else 1 end
    + case when služba_id is null then 0 else 1 end
    ) = 1
);

create table usluga
(
    usluga_id integer not null,
    naziv varchar2(200) not null,
    cijena number(8,2) not null,
    opis varchar2(200),
    ustanova_id number(4) not null constraint ustanova_usluga_fk references ustanova(ustanova_id),
    constraint usluga_pk primary key (usluga_id, ustanova_id)
);

create table korištenje_usluge
(
    usluga_id integer not null,
    ustanova_id number(4) not null,
    OIB varchar2(11) not null constraint OIB_korištenje_usluge_fk references korisnik(OIB),
    zaposlenik_id integer not null constraint zaposlenik_korištenje_usluge_fk references zaposlenik(zaposlenik_id),
    datum_usluge date not null,
    osiguranje char(2) not null,
    constraint služba_ustanova_kor_usl_fk foreign key (usluga_id, ustanova_id) references usluga(usluga_id, ustanova_id),
    constraint korištenje_usluge_pk primary key (usluga_id, ustanova_id, OIB, zaposlenik_id, datum_usluge)
);
