-- --------------------------------
-- 1: CREATE EMPTY DATABASE:
-- --------------------------------

drop database if exists jbechek_t;
create database jbechek_t;

-- --------------------------------
-- 2: CREATE TABLE STRUCTURE:
-- --------------------------------

use jbechek_t;

drop procedure if exists sp_create_database;
delimiter $
create procedure sp_create_database()
begin
	-- 2A: Create table to house genres:
	drop table if exists tblGenre;
	create table tblGenre(
		GenreID int unsigned auto_increment primary key not null,
		Genre varchar(20) not null,
        LastUpdate timestamp not null
	);

	-- 2B: Create table to house possible member positions/instruments:
	drop table if exists tblPosition;
	create table tblPosition(
		PositionID int unsigned auto_increment primary key not null,
		Position varchar(20) not null,
        LastUpdate timestamp not null
	);

	-- 2C: Create table to house bands/band info:
	drop table if exists tblBand;
	create table tblBand(
		BandID int unsigned auto_increment primary key not null,
		Band varchar(45) not null,
		FoundationYear date not null,
        LastUpdate timestamp not null
	);

	-- 2D: Create table to house artists:
	drop table if exists tblArtist;
	create table tblArtist(
		ArtistID int unsigned auto_increment primary key not null,
		FName varchar(20) not null,
		LName varchar(20) not null,
        LastUpdate timestamp not null
	);

	-- 2E: Create table to house record companies/record company info:
	drop table if exists tblRecordCompany;
	create table tblRecordCompany(
		RecordCompanyID int unsigned auto_increment primary key not null,
		RecordCompany varchar(45) not null,
		FoundationYear date not null,
        LastUpdate timestamp not null
	);

	-- 2F: Create table to represent the relationship between artist and position/instrument:
	drop table if exists tblArtistPosition;
	create table tblArtistPosition(
		ArtistID int unsigned not null,
		PositionID int unsigned not null,
        LastUpdate timestamp not null,
		constraint AP_FK1 foreign key(ArtistID) references tblArtist(ArtistID),
		constraint AP_FK2 foreign key(PositionID) references tblPosition(PositionID),
		constraint AP_PK primary key(ArtistID, PositionID)
	);

	-- 2G: Create table to represent the relationship between artist (with position) and their band:
	drop table if exists tblBandArtist;
	create table tblBandArtist(
		BandID int unsigned not null,
		ArtistID int unsigned not null,
		PositionID int unsigned not null,
        LastUpdate timestamp not null,
		constraint BA_FK1 foreign key(BandID) references tblBand(BandID),
		constraint BA_FK2 foreign key(ArtistID, PositionID) references tblArtistPosition(ArtistID, PositionID),
		constraint BA_PK primary key(ArtistID, PositionID, BandID)
	);

	-- 2H: Create table to house albums/album info:
	drop table if exists tblAlbum;
	create table tblAlbum(
		AlbumID int unsigned auto_increment primary key not null,
		Album varchar(45),
		ReleaseDate date not null,
		Price decimal(13,4) not null,
		GenreID int unsigned not null,
        LastUpdate timestamp not null,
		constraint A_FK1 foreign key(GenreID) references tblGenre(GenreID)
	);

	-- 2I: Create table to represent relationship between album and record company:
	drop table if exists tblRecordCompanyAlbum;
	create table tblRecordCompanyAlbum(
		RecordCompanyID int unsigned not null,
		AlbumID int unsigned not null,
        LastUpdate timestamp not null,
		constraint RA_FK1 foreign key(RecordCompanyID) references tblRecordCompany(RecordCompanyID),
		constraint RA_FK2 foreign key(AlbumID) references tblAlbum(AlbumID),
		constraint RA_PK primary key(RecordCompanyID, AlbumID)
	);

	-- 2J: Create table to represent relationship between band and album:
	drop table if exists tblAlbumBand;
	create table tblAlbumBand(
		BandID int unsigned not null,
		AlbumID int unsigned not null,
        LastUpdate timestamp not null,
		constraint AB_FK1 foreign key(BandID) references tblBand(BandID),
		constraint AB_FK2 foreign key(AlbumID) references tblAlbum(AlbumID),
		constraint AB_PK primary key(AlbumID, BandID)
	);

	-- 2K: Create table to house tracks/track info:
		-- IsExplicit describes current state of track (i.e. if track is censored, IsExplicit must be NO)
			-- 0 = no; 1 = yes
		-- IsCensored describes whether or not the song has been altered to be appropriate for all listeners
			-- 0 = no; 1 = yes
		-- Duration is length of track in seconds
	drop table if exists tblTrack;
	create table tblTrack(
		Track varchar(45) not null,
		IsCensored boolean not null,
		AlbumID int unsigned not null,
		IsExplicit boolean not null,
		Duration int unsigned not null,
        LastUpdate timestamp not null,
		constraint T_FK1 foreign key(AlbumID) references tblAlbum(AlbumID),
		constraint T_PK primary key(Track, IsCensored, AlbumID)
	);

	-- 2L: Create table to house types of DJ's:
	drop table if exists tblDJType;
	create table tblDJType(
		DJTypeID int unsigned auto_increment primary key not null,
		DJType varchar(45) not null,
        LastUpdate timestamp not null
	);

	-- 2M: Create table to house DJ's/DJ info:
	drop table if exists tblDJ;
	create table tblDJ(
		DJID int unsigned auto_increment primary key not null,
		FName varchar(20) not null,
		LName varchar(20) not null,
		Salary decimal(13,4) not null,
        LastUpdate timestamp not null
	);

	-- 2N: Create table to house clients/client info:
	drop table if exists tblClient;
	create table tblClient(
		ClientID int unsigned auto_increment primary key not null,
		FName varchar(20) not null,
		LName varchar(20) not null,
        LastUpdate timestamp not null
	);

	-- 2O: Create table to represent relationship between DJType and the Genres associated with each:
	drop table if exists tblDJTypeGenre;
	create table tblDJTypeGenre(
		DJTypeID int unsigned not null,
		GenreID int unsigned not null,
        LastUpdate timestamp not null,
		constraint DJTG_FK1 foreign key (DJTypeID) references tblDJType (DJTypeID),
		constraint DJTG_FK2 foreign key (GenreID) references tblGenre (GenreID),
		constraint DJTG_PK primary key (DJTypeID, GenreID)
	);

	-- 2P: Create table to represent relationship between DJ's and their type:
	drop table if exists tblDJTypeAssignment;
	create table tblDJTypeAssignment(
		DJID int unsigned not null,
		DJTypeID int unsigned not null,
        LastUpdate timestamp not null,
		constraint DJTA_FK1 foreign key (DJID) references tblDJ (DJID),
		constraint DJTA_FK2 foreign key (DJTypeID) references tblDJType (DJTypeID),
		constraint DJTA_PK primary key (DJID, DJTypeID)
	);

	-- 2Q: Create table to house transactions between DJ's (with type) and clients:
	drop table if exists tblTransaction;
	create table tblTransaction(
		TransactionID int unsigned auto_increment primary key not null,
		ClientID int unsigned not null,
		DJID int unsigned not null,
		DJTypeID int unsigned not null,
		TransactionDate date not null,
		Price decimal(13,4) not null,
        LastUpdate timestamp not null,
		constraint Tr_FK1 foreign key (ClientID) references tblClient (ClientID),
		constraint Tr_FK2 foreign key (DJID, DJTypeID) references tblDJTypeAssignment (DJID, DJTypeID)
	);
    
    -- 2R: Create table to log changes to tblBandArtist:
    drop table if exists tblBandAudit;
    create table tblBandAudit(
		ChangeID int unsigned auto_increment primary key not null,
        BandID int unsigned not null,
        ArtistID int unsigned not null,
        PositionID int unsigned not null,
        Event varchar(10) not null,
        TimeStamp datetime not null
	);
    
    -- 2S: Create table to log changes to tblDJ:
    drop table if exists tblDJAudit;
    create table tblDJAudit(
		ChangeID int unsigned auto_increment primary key not null,
        DJID int unsigned not null,
        FName varchar(20) not null,
        LName varchar(20) not null,
        Salary decimal(13,4) not null,
        Event varchar(10) not null,
        TimeStamp datetime not null
	);
end; $
delimiter ;

call sp_create_database();

-- --------------------------------
-- 3: CREATE TRIGGERS:
-- --------------------------------

use jbechek_t;

-- 3A: Check if foundation date of band is in the future:
drop trigger if exists trCheckBandDate;
delimiter $
create trigger trCheckBandDate before insert on tblBand for each row
begin
	if(new.FoundationYear>now()) then
		signal sqlstate '45000' set message_text = 'Foundation year must not be in the future';
    end if;
end; $
delimiter ;

-- 3B: Check if release date of album is in the future:
drop trigger if exists trCheckReleaseDate;
delimiter $
create trigger trCheckReleaseDate before insert on tblAlbum for each row
begin
	if(new.ReleaseDate>now()) then
		signal sqlstate '45000' set message_text = 'Release date must not be in the future';
	end if;
end; $
delimiter ;

-- 3C: Check if foundation date of record company is in the future:
drop trigger if exists trCheckRCDate;
delimiter $
create trigger trCheckRCDate before insert on tblRecordCompany for each row
begin
	if(new.FoundationYear>now()) then
		signal sqlstate '45000' set message_text = 'Foundation year must not be in the future';
	end if;
end; $
delimiter ;

-- 3D: Check if IsExplicit and IsCensored fields correlate:
drop trigger if exists trExplicitCheck;
delimiter $
create trigger trExplicitCheck before insert on tblTrack for each row
begin
	if(new.IsCensored = 1 and new.IsExplicit = 1) then
		signal sqlstate '45000' set message_text = 'A censored track cannot be explicit';
	end if;
end; $
delimiter ;

-- 3E: Check if transaction date is in the future:
drop trigger if exists trCheckTransactionDate;
delimiter $
create trigger trCheckTransactionDate before insert on tblTransaction for each row
begin
	if(new.TransactionDate>now()) then
		signal sqlstate '45000' set message_text = 'Transaction date must not be in the future';
	end if;
end; $
delimiter ;

-- 3F: Log inserts into tblBandArtist in tblBandAudit:
drop trigger if exists trBandArtistInsert;
delimiter $
create trigger trBandArtistInsert after insert on tblBandArtist for each row
begin
	insert into tblBandAudit values (null, new.BandID, new.ArtistID, new.PositionID, 'Insert', now());
end; $
delimiter ;

-- 3G: Log updates to tblBandArtist in tblBandAudit:
drop trigger if exists trBandArtistUpdate;
delimiter $
create trigger trBandArtistUpdate after update on tblBandArtist for each row
begin
	insert into tblBandAudit values (null, new.BandID, new.ArtistID, new.PositionID, 'Update', now());
end; $
delimiter ;

-- 3H: Log deletes from tblBandArtist in tblBandAudit:
drop trigger if exists trBandArtistDelete;
delimiter $
create trigger trBandArtistDelete after delete on tblBandArtist for each row
begin
	insert into tblBandAudit values (null, old.BandID, old.ArtistID, old.PositionID, 'Delete', now());
end; $
delimiter ;

-- 3I: Log inserts into tblDJ in tblDJAudit:
drop trigger if exists trDJInsert;
delimiter $
create trigger trDJInsert after insert on tblDJ for each row
begin
	insert into tblDJAudit values (null, new.DJID, new.FName, new.LName, new.Salary, 'Insert', now());
end; $
delimiter ;

-- 3J: Log updates to tblDJ in tblDJAudit:
drop trigger if exists trDJUpdate;
delimiter $
create trigger trDJUpdate after update on tblDJ for each row
begin
	insert into tblDJAudit values (null, new.DJID, new.FName, new.LName, new.Salary, 'Update', now());
end; $
delimiter ;

-- 3K: Log deletes from tblDJ in tblDJAudit:
drop trigger if exists trDJDelete;
delimiter $
create trigger trDJDelete after delete on tblDJ for each row
begin
	insert into tblDJAudit values (null, old.DJID, old.FName, old.LName, old.Salary, 'Delete', now());
end; $
delimiter ;

-- --------------------------------
-- 4: CREATE FUNCTIONS:
-- --------------------------------

use jbechek_t;

-- 4A: Generate random integer within user specified range:
drop function if exists fnRandomInt;
delimiter $
create function fnRandomInt(min int, max int) returns int
not deterministic
begin
	return floor(rand() * (max - min + 1) + min);
end; $
delimiter ;

-- 4B: Generate random name:
drop function if exists fnRandomName;
delimiter $
create function fnRandomName() returns varchar(41)
not deterministic
begin
	declare f, l, fmax, lmax int default 0;

	drop temporary table if exists tblFirstNames;
    drop temporary table if exists tblLastNames;
    
    create temporary table tblFirstNames(fname varchar(20));
    create temporary table tblLastNames(lname varchar(20));
    
    insert into tblFirstNames values ('Bob'), ('Joe'), ('John'), ('Tyler'), ('Michael'), ('Susan'), ('Heather'),
		('Jen'), ('Brittany'), ('Kirsten'), ('Cody'), ('Philip'), ('David'), ('Maria'), ('Kelly');
    insert into tblLastNAmes values ('Smith'), ('Black'), ('White'), ('Adams'), ('Petricini'), ('Stanton'), ('Winkler'),
		('Martin'), ('Peterson'), ('Lombardi'), ('Doe'), ('Miller'), ('Daniels'), ('Lee'), ('Torez');
    
    select count(*) from tblFirstNames into fmax;
    select count(*) from tblLastNames into lmax;
    
    set f = floor(rand() * fmax);
    set l = floor(rand() * lmax);
    
    return concat((select fname from tblFirstNames limit 1 offset f), ' ', (select lname from tblLastNames limit 1 offset l));
end; $
delimiter ;

-- 4C: Generate random date within user specified range:
drop function if exists fnRandomDate;
delimiter $
create function fnRandomDate(StartDate date, EndDate date) returns date
not deterministic
begin
	declare RandomYear varchar(4);
    set RandomYear = floor(rand() * (year(EndDate) - year(StartDate) + 1) + year(StartDate));
    
	return makedate(RandomYear, rand() * (dayofyear(now())) + 1);
end; $
delimiter ;

-- 4D: Generate random band name (Adjective + Noun):
drop function if exists fnRandomBand;
delimiter $
create function fnRandomBand() returns varchar(51)
not deterministic
begin
	declare a, n, amax, nmax int default 0;

	drop temporary table if exists tblAdjectives;
    drop temporary table if exists tblNouns;
    
    create temporary table tblAdjectives(adj varchar(25));
    create temporary table tblNouns(noun varchar(25));
    
    insert into tblAdjectives values ('Fearful'), ('Elderly'), ('Warm'), ('Thundering'), ('Premium'),
		('Rebellious'), ('Pointless'), ('Elastic'), ('Spiteful'), ('Filthy'), ('Wicked'), ('Earsplitting');
	insert into tblNouns values ('Rhythms'), ('Mascara'), ('Tortoises'), ('Bandanas'), ('Strawberries'),
		('Refrigerators'), ('Toads'), ('Radishes'), ('Antelopes'), ('Toys'), ('Macaroni'), ('Lunchrooms');
        
	select count(*) from tblAdjectives into amax;
    select count(*) from tblNouns into nmax;
    
    set a = floor(rand() * amax);
    set n = floor(rand() * nmax);
    
    return concat((select adj from tblAdjectives limit 1 offset a), ' ', (select noun from tblNouns limit 1 offset n));
end; $
delimiter ;

-- 4E: Generate random decimal within user specified range:
drop function if exists fnRandomDecimal;
delimiter $
create function fnRandomDecimal(min decimal(13,4), max decimal(13,4)) returns decimal(13,4)
not deterministic
begin
	return rand() * (max - min) + min;
end; $
delimiter ;

-- --------------------------------
-- 5: FILL TABLES WITH RANDOM DATA:
-- --------------------------------

use jbechek_t;

drop procedure if exists sp_generate_test_data;
delimiter $
create procedure sp_generate_test_data(in ArtistAmount int, in BandAmount int, in RCAmount int, in AlbumAmount int,
	in TrackAmount int, in DJAmount int, in ClientAmount int, in TransactionAmount int)
begin
	declare Counter int default 0; -- used to cycle through loops for a specified number of iterations
    declare Probability int default 0; -- used to determine probability of uncommon events (artist with multiple positions)
    declare ArtistCount int default 0; -- used to determine number of artists from tblArtist
    declare PositionCount int default 0; -- used to determine number of positions from tblPosition
    declare BandCount int default 0; -- used to determine number of bands from tblBand
    declare ArtistPositionCount int default 0; -- used to determine number of artists (with positions) from tblArtistPosition
    declare GenreCount int default 0; -- used to determine number of genres from tblGenre
    declare RCCount int default 0; -- used to determine number of record companies from tblRecordCompany
    declare AlbumCount int default 0; -- used to determine number of albums from tblAlbum
    declare RandomSelection int default 0; -- Row number of randomly selected item
    declare RandomAlbum int default 0; -- used to select random album from tblAlbum from a certain genre for inserting tracks
    declare RandomAlbum2 int default 0; -- used to limit query to specified random album selection
    declare TrackCount int default 0; -- used to determine number of pre-existing tracks in selected album
    declare RandomDuration int default 0; -- used to select random duration for track begin entered into tblTrack
    declare DJCount int default 0; -- used to determine number of DJ's in tblDJ
    declare DJTypeCount int default 0; -- used to determine number of DJ Types in tblDJType
    declare ClientCount int default 0; -- used to determine number of clients in tblClient
    declare continue handler for sqlstate '23000' set Counter = Counter;
    
	-- 5A: Insert genres into tblGenre:
	insert into tblGenre values (null, 'Alternative', null);
	insert into tblGenre values (null, 'Blues', null);
	insert into tblGenre values (null, 'Classical', null);
	insert into tblGenre values (null, 'Country', null);
	insert into tblGenre values (null, 'Electronic', null);
	insert into tblGenre values (null, 'Rap', null);
	insert into tblGenre values (null, 'Jazz', null);
	insert into tblGenre values (null, 'Rock', null);
	insert into tblGenre values (null, 'Metal', null);

	-- 5B: Insert positions into tblPosition:
	insert into tblPosition values (null, 'Lead Singer', null);
	insert into tblPosition values (null, 'Guitarist', null);
	insert into tblPosition values (null, 'Bassist', null);
	insert into tblPosition values (null, 'Drummer', null);
	insert into tblPosition values (null, 'Pianist', null);
	insert into tblPosition values (null, 'Rapper', null);
	insert into tblPosition values (null, 'Keyboardist', null);
    
    -- 5C: Insert DJ Types into tblDJType:
    insert into tblDJType values (null, 'Wedding', null);
	insert into tblDJType values (null, 'Children\'s Party', null);
    insert into tblDJType values (null, 'Night Club', null);
    insert into tblDJType values (null, 'Restaurant', null);
    insert into tblDJType values (null, 'Adult\'s Party', null);
    
    -- 5D: Pair Genres with DJ Types in tblDJTypeGenre:
    insert into tblDJTypeGenre values (1, 1, null);
    insert into tblDJTypeGenre values (1, 4, null);
    insert into tblDJTypeGenre values (1, 5, null);
    insert into tblDJTypeGenre values (1, 8, null);
    insert into tblDJTypeGenre values (2, 4, null);
    insert into tblDJTypeGenre values (2, 6, null);
    insert into tblDJTypeGenre values (2, 8, null);
    insert into tblDJTypeGenre values (3, 5, null);
	insert into tblDJTypeGenre values (3, 6, null);
    insert into tblDJTypeGenre values (4, 1, null);
    insert into tblDJTypeGenre values (4, 2, null);
    insert into tblDJTypeGenre values (4, 3, null);
    insert into tblDJTypeGenre values (4, 7, null);
    insert into tblDJTypeGenre values (5, 1, null);
    insert into tblDJTypeGenre values (5, 4, null);
    insert into tblDJTypeGenre values (5, 5, null);
    insert into tblDJTypeGenre values (5, 6, null);
    insert into tblDJTypeGenre values (5, 8, null);
    insert into tblDJTypeGenre values (5, 9, null);
    
	-- 5E: Insert artists into tblArtist:
    while(Counter < ArtistAmount) do
		insert into tblArtist values (null, (select substring_index((select fnRandomName()), ' ', 1)), (select substring_index((select fnRandomName()), ' ', -1)), null);
		set Counter = Counter + 1;
	end while;
    
    set Counter = 0;
    
    -- 5F: Pair artists with positions in tblArtistPosition:
    select count(ArtistID) from tblArtist into ArtistCount;
    select count(PositionID) from tblPosition into PositionCount;
    
    while(Counter < ArtistCount) do
		set Probability = ceiling(rand() * 10);
        if(Probability > 1) then
			insert into tblArtistPosition values(Counter+1, floor(rand() * (PositionCount) + 1), null);
            set Counter = Counter + 1;
		elseif(Probability <= 1) then
			insert into tblArtistPosition values(Counter+1, floor(rand() * (PositionCount) + 1), null);
		end if;
	end while;
    
    set Counter = 0;
    
    -- 5G: Insert bands into tblBand:
    while(Counter < BandAmount) do
		insert into tblBand values (null, (select fnRandomBand()), (select fnRandomDate('1990-01-01', '2010-01-01')), null);
        set Counter = Counter + 1;
	end while;
    
    set Counter = 0;
    
    -- 5H: Pair artists (with positions) with bands in tblBandArtist:
    select count(BandID) from tblBand into BandCount;
    select count(*) from tblArtistPosition into ArtistCount;
    
    while(Counter < ArtistCount) do
		set RandomSelection = floor(rand() * (ArtistCount) + 1) - 1;
		insert into tblBandArtist values ((select floor(rand() * (BandCount) + 1)),
			(select ArtistID from tblArtistPosition limit 1 offset RandomSelection),
            (select PositionID from tblArtistPosition limit 1 offset RandomSelection), null);
		set Counter = Counter + 1;
	end while;
    
    set Counter = 0;
    
    -- 5I: Insert record companies into tblRecordCompany:
    while(Counter < RCAmount) do
		insert into tblRecordCompany values (null, (select concat(substring_index((select fnRandomBand()), ' ', 1),
			' Records')), (select fnRandomDate('1850-01-01', '1980-01-01')), null);
		set Counter = Counter + 1;
	end while;
    
    set Counter = 0;
    
    -- 5J: Insert albums into tblAlbum and pair albums with bands in tblAlbumBand:
		-- This must be done at the same time to ensure albums are not paired with bands that were founded after
        -- the release date of the album
        -- There is a 10% chance that the album will be untitled
	select count(GenreID) from tblGenre into GenreCount;
        
	while(Counter < AlbumAmount) do
		set Probability = ceiling(rand() * 10);
        set RandomSelection = floor(rand() * (BandCount) + 1);
        if(Probability > 1) then
			insert into tblAlbum values (null, (select concat(substring_index((select fnRandomBand()), ' ', -1))),
				(select fnRandomDate((select FoundationYear from tblBand where BandID=RandomSelection), now())),
                (select round(fnRandomDecimal(10, 12), 2)), (select floor(rand() * (GenreCount) + 1)), null);
			insert into tblAlbumBand values (RandomSelection, Counter+1, null);
		elseif(Probability <= 1) then
			insert into tblAlbum values (null, null,
				(select fnRandomDate((select FoundationYear from tblBand where BandID=RandomSelection), now())),
                (select round(fnRandomDecimal(10, 12), 2)), (select floor(rand() * (GenreCount) + 1)), null);
			insert into tblAlbumBand values (RandomSelection, Counter+1, null);
		end if;
        set Counter = Counter + 1;
    end while;
    
    set Counter = 0;
    
    -- 5K: Pair record companies with albums in tblRecordCompanyAlbum:
	select count(RecordCompanyID) from tblRecordCompany into RCCount;
    select count(AlbumID) from tblAlbum into AlbumCount;
    
    while(Counter < AlbumCount) do
			insert into tblRecordCompanyAlbum values (floor(rand() * (RCCount) + 1), Counter+1, null);
            set Counter = Counter + 1;
	end while;
    
    set Counter = 0;
    
    -- 5L: Insert tracks into tblTrack
		-- Tracks have varying probilities of being explicit/clean based on genre
	set Counter = 1;
	while(Counter < TrackAmount) do
		set RandomSelection = floor(rand() * (GenreCount) + 1);
        set Probability = rand() * 10;
        if(RandomSelection = 1) then
			set RandomAlbum = floor(rand() * (select count(AlbumID) from tblAlbum where GenreID=1) + 1) - 1;
            select AlbumID from tblAlbum where GenreID=1 limit 1 offset RandomAlbum into RandomAlbum2;
            select count(Track) from tblTrack where AlbumID=RandomAlbum2 and IsCensored=0 into TrackCount;
			if(Probability > 3) then
				insert into tblTrack values (concat('Track ', TrackCount+1),
					0, RandomAlbum2, 0, (select fnRandomInt(100, 400)), null);
			elseif(Probability <= 3) then
				select fnRandomInt(100,400) into RandomDuration;
				insert into tblTrack values (concat('Track ', TrackCount+1),
					0, RandomAlbum2, 1, RandomDuration, null);
				insert into tblTrack values (concat('Track ', TrackCount+1),
					1, RandomAlbum2, 0, RandomDuration, null);
			end if;
            
		elseif(RandomSelection = 2) then
			set RandomAlbum = floor(rand() * (select count(AlbumID) from tblAlbum where GenreID=2) + 1) - 1;
            select AlbumID from tblAlbum where GenreID=2 limit 1 offset RandomAlbum into RandomAlbum2;
            select count(Track) from tblTrack where AlbumID=RandomAlbum2 and IsCensored=0 into TrackCount;
			insert into tblTrack values (concat('Track ', TrackCount+1),
				0, RandomAlbum2, 0, (select fnRandomInt(100, 400)), null);
                
		elseif(RandomSelection = 3) then
			set RandomAlbum = floor(rand() * (select count(AlbumID) from tblAlbum where GenreID=3) + 1) - 1;
            select AlbumID from tblAlbum where GenreID=3 limit 1 offset RandomAlbum into RandomAlbum2;
            select count(Track) from tblTrack where AlbumID=RandomAlbum2 and IsCensored=0 into TrackCount;
			insert into tblTrack values (concat('Track ', TrackCount+1),
				0, RandomAlbum2, 0, (select fnRandomInt(100, 400)), null);
                
		elseif(RandomSelection = 4) then
			set RandomAlbum = floor(rand() * (select count(AlbumID) from tblAlbum where GenreID=4) + 1) - 1;
            select AlbumID from tblAlbum where GenreID=4 limit 1 offset RandomAlbum into RandomAlbum2;
            select count(Track) from tblTrack where AlbumID=RandomAlbum2 and IsCensored=0 into TrackCount;
			if(Probability > 3) then
				insert into tblTrack values (concat('Track ', TrackCount+1),
					0, RandomAlbum2, 0, (select fnRandomInt(100, 400)), null);
			elseif(Probability <= 3) then
				select fnRandomInt(100,400) into RandomDuration;
				insert into tblTrack values (concat('Track ', TrackCount+1),
					0, RandomAlbum2, 1, RandomDuration, null);
				insert into tblTrack values (concat('Track ', TrackCount+1),
					1, RandomAlbum2, 0, RandomDuration, null);
			end if;
		
        elseif(RandomSelection = 5) then
			set RandomAlbum = floor(rand() * (select count(AlbumID) from tblAlbum where GenreID=5) + 1) - 1;
            select AlbumID from tblAlbum where GenreID=5 limit 1 offset RandomAlbum into RandomAlbum2;
            select count(Track) from tblTrack where AlbumID=RandomAlbum2 and IsCensored=0 into TrackCount;
			insert into tblTrack values (concat('Track ', TrackCount+1),
				0, RandomAlbum2, 0, (select fnRandomInt(100, 400)), null);
                
		elseif(RandomSelection = 6) then
			set RandomAlbum = floor(rand() * (select count(AlbumID) from tblAlbum where GenreID=6) + 1) - 1;
            select AlbumID from tblAlbum where GenreID=6 limit 1 offset RandomAlbum into RandomAlbum2;
            select count(Track) from tblTrack where AlbumID=RandomAlbum2 and IsCensored=0 into TrackCount;
			if(Probability > 8) then
				insert into tblTrack values (concat('Track ', TrackCount+1),
					0, RandomAlbum2, 0, (select fnRandomInt(100, 400)), null);
			elseif(Probability <= 8) then
				select fnRandomInt(100,400) into RandomDuration;
				insert into tblTrack values (concat('Track ', TrackCount+1),
					0, RandomAlbum2, 1, RandomDuration, null);
				insert into tblTrack values (concat('Track ', TrackCount+1),
					1, RandomAlbum2, 0, RandomDuration, null);
			end if;
                
		elseif(RandomSelection = 7) then
			set RandomAlbum = floor(rand() * (select count(AlbumID) from tblAlbum where GenreID=7) + 1) - 1;
            select AlbumID from tblAlbum where GenreID=7 limit 1 offset RandomAlbum into RandomAlbum2;
            select count(Track) from tblTrack where AlbumID=RandomAlbum2 and IsCensored=0 into TrackCount;
			insert into tblTrack values (concat('Track ', TrackCount+1),
				0, RandomAlbum2, 0, (select fnRandomInt(100, 400)), null);
                
		elseif(RandomSelection = 8) then
			set RandomAlbum = floor(rand() * (select count(AlbumID) from tblAlbum where GenreID=8) + 1) - 1;
            select AlbumID from tblAlbum where GenreID=8 limit 1 offset RandomAlbum into RandomAlbum2;
            select count(Track) from tblTrack where AlbumID=RandomAlbum2 and IsCensored=0 into TrackCount;
			if(Probability > 4) then
				insert into tblTrack values (concat('Track ', TrackCount+1),
					0, RandomAlbum2, 0, (select fnRandomInt(100, 400)), null);
			elseif(Probability <= 4) then
				select fnRandomInt(100,400) into RandomDuration;
				insert into tblTrack values (concat('Track ', TrackCount+1),
					0, RandomAlbum2, 1, RandomDuration, null);
				insert into tblTrack values (concat('Track ', TrackCount+1),
					1, RandomAlbum2, 0, RandomDuration, null);
			end if;
                
		elseif(RandomSelection = 9) then
			set RandomAlbum = floor(rand() * (select count(AlbumID) from tblAlbum where GenreID=9) + 1) - 1;
            select AlbumID from tblAlbum where GenreID=9 limit 1 offset RandomAlbum into RandomAlbum2;
            select count(Track) from tblTrack where AlbumID=RandomAlbum2 and IsCensored=0 into TrackCount;
			if(Probability > 6) then
				insert into tblTrack values (concat('Track ', TrackCount+1),
					0, RandomAlbum2, 0, (select fnRandomInt(100, 400)), null);
			elseif(Probability <= 6) then
				select fnRandomInt(100,400) into RandomDuration;
				insert into tblTrack values (concat('Track ', TrackCount+1),
					0, RandomAlbum2, 1, RandomDuration, null);
				insert into tblTrack values (concat('Track ', TrackCount+1),
					1, RandomAlbum2, 0, RandomDuration, null);
			end if;
		end if;
        
        set Counter = Counter + 1;
    end while;
    
    set Counter = 0;
    
    -- 5M: Insert DJ's into tblDJ:
	while(Counter < DJAmount) do
		insert into tblDJ values (null, (select substring_index((select fnRandomName()), ' ', 1)),
			(select substring_index((select fnRandomName()), ' ', -1)), (select round(fnRandomDecimal(20000, 80000), 2)), null);
		set Counter = Counter + 1;
	end while;
    
    set Counter = 0;
    
    -- 5N: Insert clients into tblClient:
	while(Counter < ClientAmount) do
		insert into tblClient values (null, (select substring_index((select fnRandomName()), ' ', 1)),
			(select substring_index((select fnRandomName()), ' ', -1)), null);
		set Counter = Counter + 1;
	end while;
    
    set Counter = 0;
    
    -- 5O: Pair DJ's with DJ Types in tblDJTypeAssignment:
	select count(DJID) from tblDJ into DJCount;
    select count(DJTypeID) from tblDJType into DJTypeCount;
    
    while(Counter < DJCount) do
		set Probability = ceiling(rand() * 10);
        if(Probability > 4) then
			insert into tblDJTypeAssignment values(Counter+1, floor(rand() * (DJTypeCount) + 1), null);
            set Counter = Counter + 1;
		elseif(Probability <= 4) then
			insert into tblDJTypeAssignment values(Counter+1, floor(rand() * (DJTypeCount) + 1), null);
		end if;
	end while;
    
    set Counter = 0;
    
    -- 5P: Insert records into tblTransaction:
    select count(ClientID) from tblClient into ClientCount;
    select count(*) from tblDJTypeAssignment into DJCount;
    
    while(Counter < TransactionAmount) do
		set RandomSelection = floor(rand() * (DJCount) + 1) - 1;
		insert into tblTransaction values (null, floor(rand() * (ClientCount) + 1),
			(select DJID from tblDJTypeAssignment limit 1 offset RandomSelection),
            (select DJTypeID from tblDJTypeAssignment limit 1 offset RandomSelection),
            (select fnRandomDate('2010-01-01', date(now()))), (select round(fnRandomDecimal(500, 5000), 2)), null);
		set Counter = Counter + 1;
	end while;
end; $
delimiter ;

call sp_generate_test_data(50, 10, 20, 25, 300, 15, 35, 100);

-- --------------------------------
-- 6: CREATE INDICES:
-- --------------------------------

use jbechek_t;

-- 6A: Create index on Band field of tblBand:
create index idxBand on tblBand(Band);

-- 6B: Create index on RecordCompany field of tblRecordCompany:
create index idxRecordCompany on tblRecordcompany(RecordCompany);

-- --------------------------------
-- 7: CREATE VIEWS:
-- --------------------------------

use jbechek_t;

-- 7A: View all bands and artists:
	-- Artists who are the only member of their band are categorized seperately
drop view if exists vwArtistBandUnion;
create view vwArtistBandUnion as
select distinct concat(a.FName, ' ', a.LName) as 'Name', 'ARTIST' as 'Category' from tblArtist a
inner join tblArtistPosition ap on a.ArtistID=ap.ArtistID
inner join tblBandArtist ba on ap.ArtistID=ba.ArtistID and ap.PositionID=ba.PositionID
inner join tblBand b on ba.BandID=b.BandID
where b.BandID in (select b.BandID from tblBand b inner join tblBandArtist ba
on b.BandID=ba.BandID group by b.BandID having count(ba.ArtistID)>1)
union
select b.Band, 'BAND' as 'Category' from tblBand b inner join tblBandArtist ba
on b.BandID=ba.BandID group by b.BandID having count(ba.ArtistID)>1
union
select concat(a.FName, ' ', a.LName, '/', b.Band) as 'Name', 'ARTIST/BAND' as 'Category' from tblArtist a
inner join tblArtistPosition ap on a.ArtistID=ap.ArtistID
inner join tblBandArtist ba on ap.ArtistID=ba.ArtistID and ap.PositionID=ba.PositionID
inner join tblBand b on ba.BandID=b.BandID
where b.BandID in (select b.BandID from tblBand b inner join tblBandArtist ba
on b.BandID=ba.BandID group by b.BandID having count(ba.ArtistID)=1);

-- 7B: View albums by record company:
drop view if exists vwRecordCompanyAlbums;
create view vwRecordCompanyAlbums as
select rc.RecordCompany, a.Album from tblRecordCompany rc
inner join tblRecordCompanyAlbum rca on rc.RecordCompanyID=rca.RecordCompanyID
inner join tblAlbum a on rca.AlbumID=a.AlbumID;

-- 7C: View artists by band:
	-- Shows artists without bands
drop view if exists vwArtists;
create view vwArtists as
select distinct concat(a.FName, ' ', a.LName) as 'Artist', b.Band from tblArtist a
left join tblArtistPosition ap on a.ArtistID=ap.ArtistID
left join tblBandArtist ba on ap.ArtistID=ba.ArtistID and ap.PositionID=ba.PositionID
left join tblBand b on ba.BandID=b.BandID;

-- 7D: View changes in band membership:
drop view if exists vwBandMembership;
create view vwBandMembership as
select * from tblBandAudit;

-- 7E: View changes in DJ information:
drop view if exists vwDJ;
create view vwDJ as
select * from tblDJAudit;

-- 7F: View transactions by genre:
drop view if exists vwTransByGenre;
create view vwTransByGenre as
select g.Genre, count(t.TransactionID) as 'Number of events',
format(sum(t.Price), 2) as 'Total Price' from tblTransaction t
inner join tblDJTypeAssignment ta on t.DJID=ta.DJID and t.DJTypeID=ta.DJTypeID
inner join tblDJType dt on ta.DJTypeID=dt.DJTypeID
inner join tblDJTypeGenre dtg on dt.DJTypeID=dtg.DJTypeID
inner join tblGenre g on dtg.GenreID=g.GenreID group by g.Genre;

-- --------------------------------
-- 8: EXTRA:
-- --------------------------------

use jbechek_t;

-- 8A: Transaction example:
start transaction;

SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;

delete from tblBandArtist where ArtistID=1;
delete from tblArtistPosition where ArtistID=1;
delete from tblArtist where ArtistID=1;

SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=1;

commit;