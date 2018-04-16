-- --------------------------------
-- 1: CREATE EMPTY DATABASE:
-- --------------------------------

drop database if exists jbechek_w;
create database jbechek_w;

-- --------------------------------
-- 2: CREATE TABLE STRUCTURE:
-- --------------------------------

use jbechek_w;

drop procedure if exists sp_create_warehouse;
delimiter $
create procedure sp_create_warehouse()
begin
	-- 2A: Create table to house possible member positions/instruments: (dimension)
	drop table if exists tblPosition;
	create table tblPosition like jbechek_t.tblPosition;
    alter table tblPosition drop LastUpdate;
    
    -- 2B: Create table to house artists: (dimension)
	drop table if exists tblArtist;
	create table tblArtist like jbechek_t.tblArtist;
    alter table tblArtist drop LastUpdate;
    
    -- 2C: Create table to house record companies/record company info: (dimension)
    drop table if exists tblRecordCompany;
    create table tblRecordCompany like jbechek_t.tblRecordCompany;
    alter table tblRecordCompany drop LastUpdate;
    
    -- 2D: Create table to house bands/band info: (dimension)
	drop table if exists tblBand;
	create table tblBand like jbechek_t.tblBand;
    alter table tblBand drop LastUpdate;
    
    -- 2E: Create table to house genres: (dimension)
    drop table if exists tblGenre;
    create table tblGenre like jbechek_t.tblGenre;
    alter table tblGenre drop LastUpdate;
    
    -- 2F: Create table to house albums/album info: (dimension)
    drop table if exists tblAlbum;
    create table tblAlbum like jbechek_t.tblAlbum;
    alter table tblAlbum drop LastUpdate;
    
    -- 2G: Create table to house clients/client info: (dimension)
    drop table if exists tblClient;
    create table tblClient like jbechek_t.tblClient;
    alter table tblClient drop LastUpdate;
    
    -- 2H: Create table to house types of DJ's: (dimension)
    drop table if exists tblDJType;
    create table tblDJType like jbechek_t.tblDJType;
    alter table tblDJType drop LastUpdate;
    
    -- 2I: Create table to house DJ's/DJ info: (dimension)
    drop table if exists tblDJ;
    create table tblDJ like jbechek_t.tblDJ;
    alter table tblDJ drop LastUpdate;
    
    -- 2J: Create table to house time data: (dimension)
    drop table if exists tblTime;
    create table tblTime(
		TimeID int unsigned auto_increment primary key not null,
        Time date not null
    );
    
    -- 2K: Create table to house all track info: (fact)
    drop table if exists tblTrack;
	create table tblTrack(
		Track varchar(45) not null,
		IsCensored boolean not null,
		AlbumID int unsigned not null,
		IsExplicit boolean not null,
		Duration int unsigned not null,
        RecordCompanyID int unsigned not null,
        ArtistID int unsigned not null,
        PositionID int unsigned not null,
        BandID int unsigned not null,
		constraint Track_FK1 foreign key(AlbumID) references tblAlbum(AlbumID),
        constraint Track_FK2 foreign key(RecordCompanyID) references tblRecordCompany(RecordCompanyID),
        constraint Track_FK3 foreign key(ArtistID) references tblArtist(ArtistID),
        constraint Track_FK4 foreign key(PositionID) references tblPosition(PositionID),
        constraint Track_FK5 foreign key(BandID) references tblBand(BandID),
		constraint Track_PK primary key(Track, IsCensored, AlbumID, RecordCompanyID, ArtistID, PositionID, BandID)
	);
    
    -- 2L: Create table to house all transaction info: (fact)
    drop table if exists tblTransaction;
    create table tblTransaction(
		ClientID int unsigned not null,
        DJID int unsigned not null,
        DJTypeID int unsigned not null,
        Price decimal(13,4) not null,
        GenreID int unsigned not null,
        TimeID int unsigned not null,
        constraint Transaction_FK1 foreign key(ClientID) references tblClient(ClientID),
        constraint Transaction_FK2 foreign key(DJID) references tblDJ(DJID),
        constraint Transaction_FK3 foreign key(DJTypeID) references tblDJType(DJTypeID),
        constraint Transaction_FK4 foreign key(GenreID) references tblGenre(GenreID),
        constraint Transaction_FK5 foreign key(TimeID) references tblTime(TimeID),
        constraint Transaction_PK primary key(ClientID, DJID, DJTypeID, GenreID, TimeID)
	);
    
    -- 2M: Create table to house aggregated album info: (aggregate)
    drop table if exists tblAlbumAggregate;
    create table tblAlbumAggregate(
		BandID int unsigned not null,
        AlbumID int unsigned not null,
        TrackCount int unsigned not null,
        Runtime time not null,
        constraint AlbumAggregate_FK1 foreign key(BandID) references tblBand(BandID),
        constraint AlbumAggregate_FK2 foreign key(AlbumID) references tblAlbum(AlbumID),
        constraint AlbumAggregate_PK primary key(BandID, AlbumID)
    );
    
    -- 2N: Create table to house aggregated DJ info: (aggregate)
    drop table if exists tblDJAggregate;
    create table tblDJAggregate(
		DJID int unsigned not null,
        DJTypeID int unsigned not null,
        TransactionCount int unsigned not null,
        TotalPrice decimal(13,4) not null,
        constraint DJAggregate_FK1 foreign key(DJID) references tblDJ(DJID),
        constraint DJAggregate_FK2 foreign key(DJTypeID) references tblDJType(DJTypeID),
        constraint DJAggregate_PK primary key(DJID, DJTypeID)
    );
end; $
delimiter ;

call sp_create_warehouse();

-- --------------------------------
-- 3: MIGRATE ALL DATA TO WAREHOUSE:
-- --------------------------------

use jbechek_w;

drop procedure if exists sp_etl_all;
delimiter $
create procedure sp_etl_all()
begin
	declare t_Track varchar(45);
    declare t_IsCensored boolean;
    declare t_AlbumID int;
    declare t_IsExplicit boolean;
    declare t_Duration int;
	declare RCCounter int default 0;
    declare ArtistCounter int default 0;
    
	declare t_ClientID int;
    declare t_DJID int;
    declare t_DJTypeID int;
    declare t_Price decimal(13,4);
    declare t_GenreID int;
    declare t_TransactionDate date;
	declare GenreCounter int default 0;
    
    declare no_more_rows int default 0;
    
    declare TrackCursor cursor for select Track, IsCensored, AlbumID, IsExplicit, Duration from jbechek_t.tblTrack;
    declare TransactionCursor cursor for select ClientID, DJID, DJTypeID, Price, TransactionDate from jbechek_t.tblTransaction;
    declare continue handler for not found set no_more_rows = 1;
	
    -- 3A: Insert data into dimension tables (excluding tblTime):
	insert into tblPosition select PositionID, Position from jbechek_t.tblPosition;
    insert into tblArtist select ArtistID, FName, LName from jbechek_t.tblArtist;
    insert into tblRecordCompany select RecordCompanyID, RecordCompany, FoundationYear from jbechek_t.tblRecordCompany;
    insert into tblBand select BandID, Band, FoundationYear from jbechek_t.tblBand;
    insert into tblGenre select GenreID, Genre from jbechek_t.tblGenre;
    insert into tblAlbum select AlbumID, Album, ReleaseDate, Price, GenreID from jbechek_t.tblAlbum;
    insert into tblClient select ClientID, FName, LName from jbechek_t.tblClient;
    insert into tblDJType select DJTypeID, DJType from jbechek_t.tblDJType;
    insert into tblDJ select DJID, FName, LName, Salary from jbechek_t.tblDJ;
    
    -- 3B: Insert data into tblTrack:
    open TrackCursor;
    
    TrackLoop: while(no_more_rows=0) do
		fetch TrackCursor into t_Track, t_IsCensored, t_AlbumID, t_IsExplicit, t_Duration;
        if(no_more_rows=1) then
			leave TrackLoop;
		end if;
        drop temporary table if exists tblTempRC;
        create temporary table tblTempRC(RC int unsigned);
        
        insert into tblTempRC select distinct RecordCompanyID from
			jbechek_t.tblRecordCompanyAlbum where AlbumID = t_AlbumID;
        select count(*) from tblTempRC into RCCounter;
        
		drop table if exists tblTempArtistPositionBand;
        create table tblTempArtistPositionBand(Artist int unsigned, Position int unsigned, Band int unsigned);
        
        insert into tblTempArtistPositionBand select distinct ba.ArtistID, ba.PositionID, ba.BandID
			from jbechek_t.tblBandArtist ba
			inner join jbechek_t.tblBand b on ba.BandID=b.BandID
            inner join jbechek_t.tblAlbumBand ab on b.BandID=ab.BandID
            inner join jbechek_t.tblAlbum a on ab.AlbumID=a.AlbumID
            where a.AlbumID = t_AlbumID;
        
        while(RCCounter>0) do
			set RCCounter = RCCounter - 1;
            select count(*) from tblTempArtistPositionBand into ArtistCounter;
			while(ArtistCounter>0) do
				set ArtistCounter = ArtistCounter - 1;
				insert into tblTrack values (t_Track, t_IsCensored, t_AlbumID, t_IsExplicit, t_Duration,
					(select RC from tblTempRC limit 1 offset RCCounter),
					(select Artist from tblTempArtistPositionBand limit 1 offset ArtistCounter),
                    (select Position from tblTempArtistPositionBand limit 1 offset ArtistCounter),
                    (select Band from tblTempArtistPositionBand limit 1 offset ArtistCounter));
			end while;
		end while;

    end while TrackLoop;
    
    drop table if exists tblTempArtistPositionBand;
    
    close TrackCursor;
    
    set no_more_rows = 0;
    
    -- 3C: Insert data into tblTransaction and tblTime:
    open TransactionCursor;
    
    TransactionLoop: while(no_more_rows=0) do
		fetch TransactionCursor into t_ClientID, t_DJID, t_DJTypeID, t_Price, t_TransactionDate;
        if(no_more_rows=1) then
			leave TransactionLoop;
		end if;
        insert into tblTime values (null, t_TransactionDate);
        
        drop temporary table if exists tblTempGenre;
        create temporary table tblTempGenre(Genre int unsigned);
        
        insert into tblTempGenre select distinct g.GenreID from jbechek_t.tblGenre g
			inner join jbechek_t.tblDJTypeGenre djtg on g.GenreID=djtg.GenreID
            inner join jbechek_t.tblDJType djt on djtg.DJTypeID=djt.DJTypeID
            inner join jbechek_t.tblDJTypeAssignment djta on djt.DJTypeID=djta.DJTypeID
            inner join jbechek_t.tblTransaction t on djta.DJTypeID=t.DJTypeID and djta.DJID=t.DJID
            where t.DJTypeID = t_DJTypeID;
		select count(*) from tblTempGenre into GenreCounter;
        
        while(GenreCounter>0) do
			set GenreCounter = GenreCounter - 1;
			insert into tblTransaction values (t_ClientID, t_DJID, t_DJTypeID, t_Price,
				(select Genre from tblTempGenre limit 1 offset GenreCounter),
				(select TimeID from tblTime where Time = t_TransactionDate limit 1));
		end while;
            
	end while TransactionLoop;
    
    close TransactionCursor;
    
    set no_more_rows = 0;
    
    -- 3D: Insert data into tblAlbumAggregate:
    insert into tblAlbumAggregate select distinct BandID, AlbumID, count(Track), sec_to_time(sum(Duration)) from tblTrack
    	where IsCensored = 0 group by AlbumID, BandID, ArtistID, RecordCompanyID, PositionID;
        
	-- 3E: Insert data into tblDJAggregate:
	insert into tblDJAggregate select distinct DJID, DJTypeID, count(*), sum(Price) from tblTransaction
		group by DJID, DJTypeID, GenreID;
        
	-- 3F: Create indices on data:
	create index idxBand on tblBand(Band);
    create index idxDJType on tblDJType(DJType);
    create index idxTime on tblTime(Time);
end; $
delimiter ;

call sp_etl_all();

-- --------------------------------
-- 4: MAINTAIN WAREHOUSE:
-- --------------------------------

use jbechek_w;

drop procedure if exists sp_maintenance;
delimiter $
create procedure sp_maintenance()
begin
	drop index idxBand on tblBand;
    drop index idxDJType on tblDJType;
    drop index idxTime on tblTime;

	optimize table tblPosition;
    optimize table tblArtist;
    optimize table tblRecordCompany;
    optimize table tblBand;
    optimize table tblGenre;
    optimize table tblAlbum;
    optimize table tblClient;
    optimize table tblDJType;
    optimize table tblDJ;
    optimize table tblTime;
    optimize table tblTrack;
    optimize table tblTransaction;
    optimize table tblAlbumAggregate;
    optimize table tblDJAggregate;
    
	create index idxBand on tblBand(Band);
    create index idxDJType on tblDJType(DJType);
    create index idxTime on tblTime(Time);
end; $
delimiter ;

-- 4A: Create event to perform maintenance on warehouse every day at 2AM starting tomorrow:
drop event if exists DailyMaintenance;
create event DailyMaintenance on schedule every 1 day starts concat(date_add(date(now()), interval 1 day), ' 02:00:00')
    do call sp_maintenance();

-- --------------------------------
-- 5: LOAD DAILY INTO WAREHOUSE:
-- --------------------------------

use jbechek_w;

drop procedure if exists sp_etl_daily;
delimiter $
create procedure sp_etl_daily()
begin
	declare t_Track varchar(45);
    declare t_IsCensored boolean;
    declare t_AlbumID int;
    declare t_IsExplicit boolean;
    declare t_Duration int;
	declare RCCounter int default 0;
    declare ArtistCounter int default 0;
    
	declare t_ClientID int;
    declare t_DJID int;
    declare t_DJTypeID int;
    declare t_Price decimal(13,4);
    declare t_GenreID int;
    declare t_TransactionDate date;
	declare GenreCounter int default 0;
    
    declare no_more_rows int default 0;
    
    declare TrackCursor cursor for select Track, IsCensored, AlbumID, IsExplicit, Duration from jbechek_t.tblTrack where LastUpdate >= date_sub(now(), interval 1 day);
    declare TransactionCursor cursor for select ClientID, DJID, DJTypeID, Price, TransactionDate from jbechek_t.tblTransaction where LastUpdate >= date_sub(now(), interval 1 day);
    declare continue handler for not found set no_more_rows = 1;
	
	-- 5A: Insert data into dimension tables (excluding tblTime):
	insert into tblPosition select PositionID, Position from jbechek_t.tblPosition where LastUpdate >= date_sub(now(), interval 1 day);
    insert into tblArtist select ArtistID, FName, LName from jbechek_t.tblArtist where LastUpdate >= date_sub(now(), interval 1 day);
    insert into tblRecordCompany select RecordCompanyID, RecordCompany, FoundationYear from jbechek_t.tblRecordCompany where LastUpdate >= date_sub(now(), interval 1 day);
    insert into tblBand select BandID, Band, FoundationYear from jbechek_t.tblBand where LastUpdate >= date_sub(now(), interval 1 day);
    insert into tblGenre select GenreID, Genre from jbechek_t.tblGenre where LastUpdate >= date_sub(now(), interval 1 day);
    insert into tblAlbum select AlbumID, Album, ReleaseDate, Price, GenreID from jbechek_t.tblAlbum where LastUpdate >= date_sub(now(), interval 1 day);
    insert into tblClient select ClientID, FName, LName from jbechek_t.tblClient where LastUpdate >= date_sub(now(), interval 1 day);
    insert into tblDJType select DJTypeID, DJType from jbechek_t.tblDJType where LastUpdate >= date_sub(now(), interval 1 day);
    insert into tblDJ select DJID, FName, LName, Salary from jbechek_t.tblDJ where LastUpdate >= date_sub(now(), interval 1 day);
    
    -- 5B: Insert data into tblTrack:
    open TrackCursor;
    
    TrackLoop: while(no_more_rows=0) do
		fetch TrackCursor into t_Track, t_IsCensored, t_AlbumID, t_IsExplicit, t_Duration;
        if(no_more_rows=1) then
			leave TrackLoop;
		end if;
        drop temporary table if exists tblTempRC;
        create temporary table tblTempRC(RC int unsigned);
        
        insert into tblTempRC select distinct RecordCompanyID from jbechek_t.tblRecordCompanyAlbum where AlbumID = t_AlbumID;
        select count(*) from tblTempRC into RCCounter;
        
		drop table if exists tblTempArtistPositionBand;
        create table tblTempArtistPositionBand(Artist int unsigned, Position int unsigned, Band int unsigned);
        
        insert into tblTempArtistPositionBand select distinct ba.ArtistID, ba.PositionID, ba.BandID from jbechek_t.tblBandArtist ba
			inner join jbechek_t.tblBand b on ba.BandID=b.BandID
            inner join jbechek_t.tblAlbumBand ab on b.BandID=ab.BandID
            inner join jbechek_t.tblAlbum a on ab.AlbumID=a.AlbumID
            where a.AlbumID = t_AlbumID;
        
        while(RCCounter>0) do
			set RCCounter = RCCounter - 1;
            select count(*) from tblTempArtistPositionBand into ArtistCounter;
			while(ArtistCounter>0) do
				set ArtistCounter = ArtistCounter - 1;
				insert into tblTrack values (t_Track, t_IsCensored, t_AlbumID, t_IsExplicit, t_Duration,
					(select RC from tblTempRC limit 1 offset RCCounter),
					(select Artist from tblTempArtistPositionBand limit 1 offset ArtistCounter),
                    (select Position from tblTempArtistPositionBand limit 1 offset ArtistCounter),
                    (select Band from tblTempArtistPositionBand limit 1 offset ArtistCounter));
			end while;
		end while;

    end while TrackLoop;
    
    drop table if exists tblTempArtistPositionBand;
    
    close TrackCursor;
    
    set no_more_rows = 0;
    
    -- 5C: Insert data into tblTransaction and tblTime:
    open TransactionCursor;
    
    TransactionLoop: while(no_more_rows=0) do
		fetch TransactionCursor into t_ClientID, t_DJID, t_DJTypeID, t_Price, t_TransactionDate;
        if(no_more_rows=1) then
			leave TransactionLoop;
		end if;
        insert into tblTime values (null, t_TransactionDate);
        
        drop temporary table if exists tblTempGenre;
        create temporary table tblTempGenre(Genre int unsigned);
        
        insert into tblTempGenre select distinct g.GenreID from jbechek_t.tblGenre g
			inner join jbechek_t.tblDJTypeGenre djtg on g.GenreID=djtg.GenreID
            inner join jbechek_t.tblDJType djt on djtg.DJTypeID=djt.DJTypeID
            inner join jbechek_t.tblDJTypeAssignment djta on djt.DJTypeID=djta.DJTypeID
            inner join jbechek_t.tblTransaction t on djta.DJTypeID=t.DJTypeID and djta.DJID=t.DJID
            where t.DJTypeID = t_DJTypeID;
		select count(*) from tblTempGenre into GenreCounter;
        
        while(GenreCounter>0) do
			set GenreCounter = GenreCounter - 1;
			insert into tblTransaction values (t_ClientID, t_DJID, t_DJTypeID, t_Price,
				(select Genre from tblTempGenre limit 1 offset GenreCounter),
				(select TimeID from tblTime where Time = t_TransactionDate limit 1));
		end while;
            
	end while TransactionLoop;
    
    close TransactionCursor;
    
    set no_more_rows = 0;
    
    -- 5D: Insert data into tblAlbumAggregate:
	insert into tblAlbumAggregate select distinct BandID, AlbumID, count(Track), sec_to_time(sum(Duration)) from tblTrack
		where IsCensored = 0 group by AlbumID, BandID, ArtistID, RecordCompanyID, PositionID;
        
	-- 5E: Insert data into tblDJAggregate:
	insert into tblDJAggregate select distinct DJID, DJTypeID, count(*), sum(Price) from tblTransaction
		group by DJID, DJTypeID, GenreID;
end; $
delimiter ;

-- 5A: Create event to move new data to warehouse every day at 2AM starting tomorrow:
drop event if exists DailyLoad;
create event DailyLoad on schedule every 1 day starts concat(date_add(date(now()), interval 1 day), ' 02:00:00')
    do call sp_etl_daily();
    
-- --------------------------------
-- 6: CREATE REPORTS:
-- --------------------------------

use jbechek_w;

-- 6A: View the count of uncensored tracks and total runtime per album:
drop view if exists vwAlbumAggregate;
create view vwAlbumAggregate as
select b.Band, a.Album, aa.TrackCount, aa.Runtime from tblAlbumAggregate aa
inner join tblBand b on b.BandID=aa.BandID
inner join tblAlbum a on a.AlbumID=aa.AlbumID
order by b.Band asc;

-- 6B: View the count of transactions and the total price per DJ:
drop view if exists vwDJAggregate;
create view vwDJAggregate as
select concat(d.FName, ' ', d.LName) as 'DJ', dt.DJType, da.TransactionCount, da.TotalPrice from tblDJAggregate da
inner join tblDJ d on da.DJID=d.DJID
inner join tblDJType dt on dt.DJTypeID=da.DJTypeID
order by d.FName asc, d.LName asc;

-- 6C: View all transactions from the last 4 weeks:
drop view if exists vwTransactions;
create view vwTransactions as
select distinct concat(c.FName, ' ', c.LName) as 'Client', concat(d.FName, ' ', d.LName) as 'DJ',
dt.DJType, tr.Price, t.Time from tblTransaction tr
inner join tblClient c on tr.ClientID=c.ClientID
inner join tblDJ d on tr.DJID=d.DJID
inner join tblDJType dt on tr.DJTypeID=dt.DJTypeID
inner join tblTime t on tr.TimeID=t.TimeID
where t.Time >= date_sub(now(), interval 28 day)
order by c.FName asc, c.LName asc;

-- 6D: View all tracks by album by band:
	-- Includes subtotals per band
drop procedure if exists sp_track_report;
delimiter $
create procedure sp_track_report()
begin
	declare t_Track varchar(45);
    declare t_IsCensored boolean;
    declare t_AlbumID int unsigned;
    declare no_more_rows int default 0;
    
    declare TrackCount int;
    declare Counter int default 0;
    
    declare TrackCursor cursor for select distinct t.Track, t.IsCensored, t.AlbumID from tblTrack t
		inner join tblBand b on t.BandID=b.BandID
        inner join tblAlbum a on t.AlbumID=a.AlbumID
        order by b.Band asc, a.Album asc, t.Track asc;
    declare continue handler for not found set no_more_rows = 1;
    
	drop temporary table if exists tblTempTrack;
	create temporary table tblTempTrack(Band varchar(45), Album varchar(45), Track varchar(45), Version varchar(10));
    
    open TrackCursor;
    
    TrackLoop: while(no_more_rows = 0) do
		fetch TrackCursor into t_Track, t_IsCensored, t_AlbumID;
        if(no_more_rows = 1) then
			leave TrackLoop;
		end if;
        select distinct count(Track) from tblTrack where AlbumID=t_AlbumID group by AlbumID, BandID, ArtistID, RecordCompanyID, PositionID into TrackCount;
        
		if(t_IsCensored = 0) then
			insert into tblTempTrack values ((select distinct b.Band from tblBand b inner join tblTrack t on b.BandID=t.BandID where t.AlbumID=t_AlbumID),
				(select distinct a.Album from tblAlbum a inner join tblTrack t on a.AlbumID=t.AlbumID where t.AlbumID=t_AlbumID), t_Track, 'Uncensored');
		elseif(t_IsCensored = 1) then
			insert into tblTempTrack values ((select distinct b.Band from tblBand b inner join tblTrack t on b.BandID=t.BandID where t.AlbumID=t_AlbumID),
				(select distinct a.Album from tblAlbum a inner join tblTrack t on a.AlbumID=t.AlbumID where t.AlbumID=t_AlbumID), t_Track, 'Censored');
		end if;
		
		set Counter = Counter + 1;
		
		if(Counter = TrackCount) then
			insert into tblTempTrack(Track) values (concat('Total: ', Counter));
			set Counter = 0;
		end if;
	end while TrackLoop;
    
    close TrackCursor;
    
    set no_more_rows = 0;
    set Counter = 0;
    
    select * from tblTempTrack;
end; $
delimiter ;

call sp_track_report();

-- 6E: View all transactions by Client:
	-- Includes subtotals per client
drop procedure if exists sp_transaction_report;
delimiter $
create procedure sp_transaction_report()
begin
	declare t_ClientID int unsigned;
    declare t_DJID int unsigned;
    declare t_DJTypeID int unsigned;
    declare t_Price decimal(13,4);
    declare t_TimeID int unsigned;
    declare no_more_rows int default 0;
    
    declare TransactionCount int;
    declare Counter int default 0;
    
    declare TransactionCursor cursor for select distinct ClientID, DJID, DJTypeID, Price, TimeID from tblTransaction order by ClientID asc;
    declare continue handler for not found set no_more_rows = 1;
    
    drop temporary table if exists tblTempTrans;
    create temporary table tblTempTrans(Client varchar(41), DJ varchar(41), DJType varchar(45), Price decimal(13,4), Time varchar(45));
    
    open TransactionCursor;
    
    TransactionLoop: while(no_more_rows = 0) do
		fetch TransactionCursor into t_ClientID, t_DJID, t_DJTypeID, t_Price, t_TimeID;
        if(no_more_rows = 1) then
			leave TransactionLoop;
		end if;
        drop temporary table if exists tblIntermediate;
        create temporary table tblIntermediate(count int);
        
        insert into tblIntermediate select count(ClientID) from tblTransaction where ClientID=t_ClientID group by DJID, DJTypeID, TimeID;
        select count(count) from tblIntermediate into TransactionCount;
        
        insert into tblTempTrans values ((select distinct concat(c.FName, ' ', c.LName) from tblClient c inner join tblTransaction t on c.ClientID=t.ClientID where t.ClientID=t_ClientID),
			(select distinct concat(d.FName, ' ', d.LName) from tblDJ d inner join tblTransaction t on d.DJID=t.DJID where t.DJID=t_DJID),
            (select distinct dt.DJType from tblDJType dt inner join tblTransaction t on dt.DJTypeID=t.DJTypeID where t.DJTypeID=t_DJTypeID), t_Price,
            (select distinct ti.Time from tblTime ti inner join tblTransaction t on ti.TimeID=t.TimeID where t.TimeID=t_TimeID));
            
		set Counter = Counter + 1;
            
		if(Counter = TransactionCount) then
			insert into tblTempTrans(Time) values (concat('Total: ', Counter));
            set Counter = 0;
        end if;
	end while TransactionLoop;
    
    close TransactionCursor;
    
    set no_more_rows = 0;
    set Counter = 0;
    
    select * from tblTempTrans;
end; $
delimiter ;

call sp_transaction_report();

-- --------------------------------
-- 7: IMPORT/EXPORT DATA:
-- --------------------------------

use jbechek_w;

-- 7A: Export album aggregate data:
select b.Band, a.Album, aa.TrackCount, aa.Runtime from tblAlbumAggregate aa
inner join tblBand b on b.BandID=aa.BandID
inner join tblAlbum a on a.AlbumID=aa.AlbumID
order by b.Band asc
into outfile 'C:/users/public/Album_Aggregate_Data.csv'
fields terminated by ' ';

-- 7B: Import new album aggregate data:
truncate tblAlbumAggregate;
load data local infile 'C:/users/public/Album_Aggregate_Data.csv' into table tblAlbumAggregate;

-- --------------------------------
-- 8: EMPTY WAREHOUSE:
-- --------------------------------

use jbechek_w;

drop procedure if exists sp_clean_warehouse;
delimiter $
create procedure sp_clean_warehouse()
begin
	SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;

	truncate tblTransaction;
    truncate tblTrack;
    truncate tblAlbumAggregate;
    truncate tblDJAggregate;
    truncate tblPosition;
    truncate tblArtist;
    truncate tblRecordCompany;
    truncate tblAlbum;
    truncate tblBand;
    truncate tblGenre;
    truncate tblClient;
    truncate tblDJ;
    truncate tblDJType;
    truncate tblTime;
    
    SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=1;
end; $
delimiter ;

call sp_clean_warehouse();

-- --------------------------------
-- 9: EXTRA:
-- --------------------------------

use jbechek_w;

-- 9A: DJ view with hidden salary:
select DJID, FName, LName from tblDJ;