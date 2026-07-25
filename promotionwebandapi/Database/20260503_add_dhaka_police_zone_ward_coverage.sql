-- Run this migration against VaratiaManagementDb.
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.DhakaPoliceZones', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.DhakaPoliceZones
        (
            Id NVARCHAR(30) NOT NULL PRIMARY KEY,
            NameBn NVARCHAR(100) NOT NULL,
            NameEn NVARCHAR(100) NOT NULL,
            DisplayOrder INT NOT NULL
        );
    END;

    IF OBJECT_ID(N'dbo.DhakaPoliceStations', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.DhakaPoliceStations
        (
            Id NVARCHAR(60) NOT NULL PRIMARY KEY,
            ZoneId NVARCHAR(30) NOT NULL,
            NameBn NVARCHAR(100) NOT NULL,
            NameEn NVARCHAR(100) NOT NULL,
            DisplayOrder INT NOT NULL,
            CONSTRAINT FK_DhakaPoliceStations_DhakaPoliceZones
                FOREIGN KEY (ZoneId) REFERENCES dbo.DhakaPoliceZones (Id)
        );
    END;

    IF OBJECT_ID(N'dbo.DhakaPoliceStationWardCoverages', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.DhakaPoliceStationWardCoverages
        (
            Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            StationId NVARCHAR(60) NOT NULL,
            WardNo INT NOT NULL,
            CoverageNoteBn NVARCHAR(200) NULL,
            CoverageNoteEn NVARCHAR(200) NULL,
            DisplayOrder INT NOT NULL,
            CONSTRAINT FK_DhakaPoliceStationWardCoverages_DhakaPoliceStations
                FOREIGN KEY (StationId) REFERENCES dbo.DhakaPoliceStations (Id)
        );
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE name = N'UX_DhakaPoliceStationWardCoverages_StationId_WardNo'
          AND object_id = OBJECT_ID(N'dbo.DhakaPoliceStationWardCoverages')
    )
    BEGIN
        CREATE UNIQUE INDEX UX_DhakaPoliceStationWardCoverages_StationId_WardNo
        ON dbo.DhakaPoliceStationWardCoverages (StationId, WardNo);
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE name = N'IX_DhakaPoliceStations_ZoneId_DisplayOrder'
          AND object_id = OBJECT_ID(N'dbo.DhakaPoliceStations')
    )
    BEGIN
        CREATE INDEX IX_DhakaPoliceStations_ZoneId_DisplayOrder
        ON dbo.DhakaPoliceStations (ZoneId, DisplayOrder);
    END;

    MERGE dbo.DhakaPoliceZones AS target
    USING
    (
        VALUES
            (N'mirpur', N'মিরপুর ডিভিশন', N'Mirpur Zone', 1),
            (N'uttara', N'উত্তরা ডিভিশন', N'Uttara Zone', 2),
            (N'tejgaon', N'তেজগাঁও ডিভিশন', N'Tejgaon Zone', 3),
            (N'ramna', N'রমনা ডিভিশন', N'Ramna Zone', 4),
            (N'lalbagh', N'লালবাগ ডিভিশন', N'Lalbagh Zone', 5),
            (N'gulshan', N'গুলশান ডিভিশন', N'Gulshan Zone', 6),
            (N'wari', N'ওয়ারী ডিভিশন', N'Wari Zone', 7),
            (N'motijheel', N'মতিঝিল ডিভিশন', N'Motijheel Zone', 8)
    ) AS source (Id, NameBn, NameEn, DisplayOrder)
    ON target.Id = source.Id
    WHEN MATCHED THEN
        UPDATE SET
            NameBn = source.NameBn,
            NameEn = source.NameEn,
            DisplayOrder = source.DisplayOrder
    WHEN NOT MATCHED THEN
        INSERT (Id, NameBn, NameEn, DisplayOrder)
        VALUES (source.Id, source.NameBn, source.NameEn, source.DisplayOrder);

    MERGE dbo.DhakaPoliceStations AS target
    USING
    (
        VALUES
            (N'mirpur-model', N'mirpur', N'মিরপুর মডেল থানা', N'Mirpur Model Police Station', 1),
            (N'shah-ali', N'mirpur', N'শাহ আলী থানা', N'Shah Ali Police Station', 2),
            (N'pallabi', N'mirpur', N'পল্লবী থানা', N'Pallabi Police Station', 3),
            (N'kafrul', N'mirpur', N'কাফরুল থানা', N'Kafrul Police Station', 4),
            (N'bhashantek', N'mirpur', N'ভাষানটেক থানা', N'Bhashantek Police Station', 5),
            (N'uttara-west', N'uttara', N'উত্তরা পশ্চিম থানা', N'Uttara West Police Station', 1),
            (N'uttara-east', N'uttara', N'উত্তরা পূর্ব থানা', N'Uttara East Police Station', 2),
            (N'airport', N'uttara', N'বিমানবন্দর থানা', N'Airport Police Station', 3),
            (N'turag', N'uttara', N'তুরাগ থানা', N'Turag Police Station', 4),
            (N'tejgaon', N'tejgaon', N'তেজগাঁও থানা', N'Tejgaon Police Station', 1),
            (N'tejgaon-industrial-area', N'tejgaon', N'তেজগাঁও শিল্পাঞ্চল থানা', N'Tejgaon Industrial Area Police Station', 2),
            (N'sher-e-bangla-nagar', N'tejgaon', N'শেরেবাংলা নগর থানা', N'Sher-e-Bangla Nagar Police Station', 3),
            (N'hatirjheel', N'tejgaon', N'হাতিরঝিল থানা', N'Hatirjheel Police Station', 4),
            (N'ramna', N'ramna', N'রমনা থানা', N'Ramna Police Station', 1),
            (N'paltan-ramna', N'ramna', N'পল্টন থানা', N'Paltan Police Station', 2),
            (N'shahbagh', N'ramna', N'শাহবাগ থানা', N'Shahbagh Police Station', 3),
            (N'motijheel-ramna', N'ramna', N'মতিঝিল থানা', N'Motijheel Police Station', 4),
            (N'lalbagh', N'lalbagh', N'লালবাগ থানা', N'Lalbagh Police Station', 1),
            (N'chawkbazar', N'lalbagh', N'চকবাজার থানা', N'Chawkbazar Police Station', 2),
            (N'kotwali', N'lalbagh', N'কোতোয়ালি থানা', N'Kotwali Police Station', 3),
            (N'hazaribagh', N'lalbagh', N'হাজারীবাগ থানা', N'Hazaribagh Police Station', 4),
            (N'gulshan', N'gulshan', N'গুলশান থানা', N'Gulshan Police Station', 1),
            (N'banani', N'gulshan', N'বনানী থানা', N'Banani Police Station', 2),
            (N'baridhara', N'gulshan', N'বারিধারা থানা', N'Baridhara Police Station', 3),
            (N'khilkhet', N'gulshan', N'খিলক্ষেত থানা', N'Khilkhet Police Station', 4),
            (N'bhatara', N'gulshan', N'ভাটারা থানা', N'Bhatara Police Station', 5),
            (N'wari', N'wari', N'ওয়ারী থানা', N'Wari Police Station', 1),
            (N'sutrapur', N'wari', N'সূত্রাপুর থানা', N'Sutrapur Police Station', 2),
            (N'jurain', N'wari', N'জুরাইন থানা', N'Jurain Police Station', 3),
            (N'demra', N'wari', N'ডেমরা থানা', N'Demra Police Station', 4),
            (N'shyampur', N'wari', N'শ্যামপুর থানা', N'Shyampur Police Station', 5),
            (N'motijheel', N'motijheel', N'মতিঝিল থানা', N'Motijheel Police Station', 1),
            (N'paltan-motijheel', N'motijheel', N'পল্টন থানা', N'Paltan Police Station', 2),
            (N'khilgaon', N'motijheel', N'খিলগাঁও থানা', N'Khilgaon Police Station', 3),
            (N'sabujbagh', N'motijheel', N'সবুজবাগ থানা', N'Sabujbagh Police Station', 4),
            (N'kamalapur-railway', N'motijheel', N'কমলাপুর রেলওয়ে থানা', N'Kamalapur Railway Police Station', 5)
    ) AS source (Id, ZoneId, NameBn, NameEn, DisplayOrder)
    ON target.Id = source.Id
    WHEN MATCHED THEN
        UPDATE SET
            ZoneId = source.ZoneId,
            NameBn = source.NameBn,
            NameEn = source.NameEn,
            DisplayOrder = source.DisplayOrder
    WHEN NOT MATCHED THEN
        INSERT (Id, ZoneId, NameBn, NameEn, DisplayOrder)
        VALUES (source.Id, source.ZoneId, source.NameBn, source.NameEn, source.DisplayOrder);

    MERGE dbo.DhakaPoliceStationWardCoverages AS target
    USING
    (
        VALUES
            (N'mirpur-model', 7, NULL, NULL, 1),
            (N'mirpur-model', 8, NULL, NULL, 2),
            (N'mirpur-model', 9, NULL, NULL, 3),
            (N'mirpur-model', 10, N'আংশিক', N'Partial', 4),
            (N'pallabi', 11, NULL, NULL, 1),
            (N'pallabi', 12, NULL, NULL, 2),
            (N'pallabi', 13, NULL, NULL, 3),
            (N'pallabi', 14, NULL, NULL, 4),
            (N'pallabi', 15, N'আংশিক', N'Partial', 5),
            (N'kafrul', 15, NULL, NULL, 1),
            (N'kafrul', 16, NULL, NULL, 2),
            (N'kafrul', 17, NULL, NULL, 3),
            (N'kafrul', 18, N'আংশিক', N'Partial', 4),
            (N'shah-ali', 8, N'আংশিক ও মিক্সড এরিয়া', N'Partial and mixed area', 1),
            (N'shah-ali', 9, N'আংশিক ও মিক্সড এরিয়া', N'Partial and mixed area', 2),
            (N'bhashantek', 17, NULL, NULL, 1),
            (N'bhashantek', 18, NULL, NULL, 2),
            (N'bhashantek', 19, N'আংশিক', N'Partial', 3),
            (N'uttara-west', 1, N'DNCC', N'DNCC', 1),
            (N'uttara-west', 2, N'DNCC', N'DNCC', 2),
            (N'uttara-west', 3, N'DNCC', N'DNCC', 3),
            (N'uttara-east', 3, NULL, NULL, 1),
            (N'uttara-east', 4, NULL, NULL, 2),
            (N'uttara-east', 5, NULL, NULL, 3),
            (N'turag', 5, N'আংশিক গ্রামীণ/নগর মিক্সড', N'Partial rural/urban mixed', 1),
            (N'turag', 6, N'আংশিক গ্রামীণ/নগর মিক্সড', N'Partial rural/urban mixed', 2),
            (N'turag', 51, N'আংশিক গ্রামীণ/নগর মিক্সড', N'Partial rural/urban mixed', 3),
            (N'turag', 52, N'আংশিক গ্রামীণ/নগর মিক্সড', N'Partial rural/urban mixed', 4),
            (N'airport', 1, N'এয়ারপোর্ট এলাকা মিক্সড জোন', N'Airport area mixed zone', 1),
            (N'airport', 2, N'এয়ারপোর্ট এলাকা মিক্সড জোন', N'Airport area mixed zone', 2),
            (N'tejgaon', 24, NULL, NULL, 1),
            (N'tejgaon', 25, NULL, NULL, 2),
            (N'tejgaon', 26, NULL, NULL, 3),
            (N'tejgaon-industrial-area', 27, NULL, NULL, 1),
            (N'tejgaon-industrial-area', 28, NULL, NULL, 2),
            (N'sher-e-bangla-nagar', 29, NULL, NULL, 1),
            (N'sher-e-bangla-nagar', 30, NULL, NULL, 2),
            (N'sher-e-bangla-nagar', 31, NULL, NULL, 3),
            (N'hatirjheel', 20, N'আংশিক', N'Partial', 1),
            (N'hatirjheel', 21, N'আংশিক', N'Partial', 2),
            (N'hatirjheel', 22, N'আংশিক', N'Partial', 3),
            (N'hatirjheel', 23, N'আংশিক', N'Partial', 4),
            (N'ramna', 19, NULL, NULL, 1),
            (N'ramna', 20, NULL, NULL, 2),
            (N'ramna', 21, NULL, NULL, 3),
            (N'motijheel-ramna', 33, NULL, NULL, 1),
            (N'motijheel-ramna', 34, NULL, NULL, 2),
            (N'motijheel-ramna', 35, NULL, NULL, 3),
            (N'paltan-ramna', 36, NULL, NULL, 1),
            (N'paltan-ramna', 37, NULL, NULL, 2),
            (N'shahbagh', 21, N'বিশেষ মিক্সড জোন', N'Special mixed zone', 1),
            (N'shahbagh', 22, N'বিশেষ মিক্সড জোন', N'Special mixed zone', 2),
            (N'lalbagh', 24, N'পুরান ঢাকা', N'Old Dhaka', 1),
            (N'lalbagh', 25, N'পুরান ঢাকা', N'Old Dhaka', 2),
            (N'lalbagh', 26, N'পুরান ঢাকা', N'Old Dhaka', 3),
            (N'chawkbazar', 27, NULL, NULL, 1),
            (N'chawkbazar', 28, NULL, NULL, 2),
            (N'kotwali', 30, NULL, NULL, 1),
            (N'kotwali', 31, NULL, NULL, 2),
            (N'kotwali', 32, NULL, NULL, 3),
            (N'hazaribagh', 56, N'আংশিক DSCC সীমা', N'Partial DSCC boundary', 1),
            (N'hazaribagh', 57, N'আংশিক DSCC সীমা', N'Partial DSCC boundary', 2),
            (N'hazaribagh', 58, N'আংশিক DSCC সীমা', N'Partial DSCC boundary', 3),
            (N'gulshan', 19, N'আংশিক উচ্চবিত্ত এলাকা', N'Partial high-income area', 1),
            (N'gulshan', 20, N'আংশিক উচ্চবিত্ত এলাকা', N'Partial high-income area', 2),
            (N'banani', 19, N'মিক্সড জোন', N'Mixed zone', 1),
            (N'banani', 20, N'মিক্সড জোন', N'Mixed zone', 2),
            (N'banani', 21, N'মিক্সড জোন', N'Mixed zone', 3),
            (N'baridhara', 21, N'ডিপ্লোম্যাটিক জোন', N'Diplomatic zone', 1),
            (N'baridhara', 22, N'ডিপ্লোম্যাটিক জোন', N'Diplomatic zone', 2),
            (N'khilkhet', 3, N'আংশিক', N'Partial', 1),
            (N'khilkhet', 4, N'আংশিক', N'Partial', 2),
            (N'khilkhet', 5, N'আংশিক', N'Partial', 3),
            (N'khilkhet', 18, N'আংশিক', N'Partial', 4),
            (N'bhatara', 17, N'আংশিক নতুন আবাসিক এলাকা', N'Partial new residential area', 1),
            (N'bhatara', 18, N'আংশিক নতুন আবাসিক এলাকা', N'Partial new residential area', 2),
            (N'bhatara', 19, N'আংশিক নতুন আবাসিক এলাকা', N'Partial new residential area', 3),
            (N'wari', 38, NULL, NULL, 1),
            (N'wari', 39, NULL, NULL, 2),
            (N'wari', 40, NULL, NULL, 3),
            (N'sutrapur', 39, NULL, NULL, 1),
            (N'sutrapur', 40, NULL, NULL, 2),
            (N'sutrapur', 41, NULL, NULL, 3),
            (N'jurain', 47, NULL, NULL, 1),
            (N'jurain', 48, NULL, NULL, 2),
            (N'jurain', 49, NULL, NULL, 3),
            (N'demra', 50, N'আংশিক সীমানা এলাকা', N'Partial boundary area', 1),
            (N'demra', 51, N'আংশিক সীমানা এলাকা', N'Partial boundary area', 2),
            (N'demra', 52, N'আংশিক সীমানা এলাকা', N'Partial boundary area', 3),
            (N'demra', 53, N'আংশিক সীমানা এলাকা', N'Partial boundary area', 4),
            (N'shyampur', 45, NULL, NULL, 1),
            (N'shyampur', 46, NULL, NULL, 2),
            (N'shyampur', 47, NULL, NULL, 3),
            (N'motijheel', 33, NULL, NULL, 1),
            (N'motijheel', 34, NULL, NULL, 2),
            (N'motijheel', 35, NULL, NULL, 3),
            (N'paltan-motijheel', 36, N'CBD এলাকা', N'CBD area', 1),
            (N'paltan-motijheel', 37, N'CBD এলাকা', N'CBD area', 2),
            (N'khilgaon', 54, NULL, NULL, 1),
            (N'khilgaon', 55, NULL, NULL, 2),
            (N'khilgaon', 56, NULL, NULL, 3),
            (N'sabujbagh', 56, NULL, NULL, 1),
            (N'sabujbagh', 57, NULL, NULL, 2),
            (N'sabujbagh', 58, NULL, NULL, 3),
            (N'kamalapur-railway', 42, N'রেলওয়ে কেন্দ্রিক এলাকা', N'Railway-centered area', 1),
            (N'kamalapur-railway', 43, N'রেলওয়ে কেন্দ্রিক এলাকা', N'Railway-centered area', 2)
    ) AS source (StationId, WardNo, CoverageNoteBn, CoverageNoteEn, DisplayOrder)
    ON target.StationId = source.StationId
       AND target.WardNo = source.WardNo
    WHEN MATCHED THEN
        UPDATE SET
            CoverageNoteBn = source.CoverageNoteBn,
            CoverageNoteEn = source.CoverageNoteEn,
            DisplayOrder = source.DisplayOrder
    WHEN NOT MATCHED THEN
        INSERT (StationId, WardNo, CoverageNoteBn, CoverageNoteEn, DisplayOrder)
        VALUES (source.StationId, source.WardNo, source.CoverageNoteBn, source.CoverageNoteEn, source.DisplayOrder);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    THROW;
END CATCH;
GO

IF OBJECT_ID(N'dbo.GetDhakaPoliceZoneWardCoverage', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.GetDhakaPoliceZoneWardCoverage;
END;
GO

CREATE PROCEDURE dbo.GetDhakaPoliceZoneWardCoverage
    @ZoneId NVARCHAR(30) = NULL,
    @StationId NVARCHAR(60) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        z.Id,
        z.NameBn,
        z.NameEn,
        z.DisplayOrder
    FROM dbo.DhakaPoliceZones z
    WHERE (@ZoneId IS NULL OR z.Id = @ZoneId)
      AND
      (
          @StationId IS NULL
          OR EXISTS
          (
              SELECT 1
              FROM dbo.DhakaPoliceStations s
              WHERE s.ZoneId = z.Id
                AND s.Id = @StationId
          )
      )
    ORDER BY z.DisplayOrder;

    SELECT
        s.Id,
        s.ZoneId,
        s.NameBn,
        s.NameEn,
        s.DisplayOrder
    FROM dbo.DhakaPoliceStations s
    INNER JOIN dbo.DhakaPoliceZones z ON z.Id = s.ZoneId
    WHERE (@ZoneId IS NULL OR s.ZoneId = @ZoneId)
      AND (@StationId IS NULL OR s.Id = @StationId)
    ORDER BY z.DisplayOrder, s.DisplayOrder;

    SELECT
        w.Id,
        w.StationId,
        w.WardNo,
        w.CoverageNoteBn,
        w.CoverageNoteEn,
        w.DisplayOrder
    FROM dbo.DhakaPoliceStationWardCoverages w
    INNER JOIN dbo.DhakaPoliceStations s ON s.Id = w.StationId
    INNER JOIN dbo.DhakaPoliceZones z ON z.Id = s.ZoneId
    WHERE (@ZoneId IS NULL OR s.ZoneId = @ZoneId)
      AND (@StationId IS NULL OR w.StationId = @StationId)
    ORDER BY z.DisplayOrder, s.DisplayOrder, w.DisplayOrder;
END;
GO
