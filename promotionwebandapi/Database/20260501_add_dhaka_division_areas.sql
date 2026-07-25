-- Run this migration against VaratiaManagementDb.
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.DhakaDivisions', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.DhakaDivisions
        (
            Id NVARCHAR(30) NOT NULL PRIMARY KEY,
            NameBn NVARCHAR(100) NOT NULL,
            DisplayOrder INT NOT NULL
        );
    END;

    IF OBJECT_ID(N'dbo.DhakaAreas', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.DhakaAreas
        (
            Id NVARCHAR(50) NOT NULL PRIMARY KEY,
            DivisionId NVARCHAR(30) NOT NULL,
            NameBn NVARCHAR(100) NOT NULL,
            DisplayOrder INT NOT NULL,
            CONSTRAINT FK_DhakaAreas_DhakaDivisions
                FOREIGN KEY (DivisionId) REFERENCES dbo.DhakaDivisions (Id)
        );
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE name = N'IX_DhakaAreas_DivisionId_DisplayOrder'
          AND object_id = OBJECT_ID(N'dbo.DhakaAreas')
    )
    BEGIN
        CREATE INDEX IX_DhakaAreas_DivisionId_DisplayOrder
        ON dbo.DhakaAreas (DivisionId, DisplayOrder);
    END;

    MERGE dbo.DhakaDivisions AS target
    USING
    (
        VALUES
            (N'mirpur', N'মিরপুর ডিভিশন', 1),
            (N'tejgaon', N'তেজগাঁও ডিভিশন', 2),
            (N'gulshan', N'গুলশান ডিভিশন', 3),
            (N'ramna', N'রমনা ডিভিশন', 4),
            (N'motijheel', N'মতিঝিল ডিভিশন', 5),
            (N'lalbagh', N'লালবাগ ডিভিশন', 6),
            (N'wari', N'ওয়ারী ডিভিশন', 7),
            (N'uttara', N'উত্তরা ডিভিশন', 8)
    ) AS source (Id, NameBn, DisplayOrder)
    ON target.Id = source.Id
    WHEN MATCHED THEN
        UPDATE SET
            NameBn = source.NameBn,
            DisplayOrder = source.DisplayOrder
    WHEN NOT MATCHED THEN
        INSERT (Id, NameBn, DisplayOrder)
        VALUES (source.Id, source.NameBn, source.DisplayOrder);

    MERGE dbo.DhakaAreas AS target
    USING
    (
        VALUES
            (N'mirpur-01', N'mirpur', N'মিরপুর ১', 1),
            (N'mirpur-02', N'mirpur', N'মিরপুর ২', 2),
            (N'mirpur-06', N'mirpur', N'মিরপুর ৬', 3),
            (N'mirpur-07', N'mirpur', N'মিরপুর ৭', 4),
            (N'mirpur-10', N'mirpur', N'মিরপুর ১০', 5),
            (N'mirpur-11', N'mirpur', N'মিরপুর ১১', 6),
            (N'mirpur-12', N'mirpur', N'মিরপুর ১২', 7),
            (N'mirpur-13', N'mirpur', N'মিরপুর ১৩', 8),
            (N'mirpur-14', N'mirpur', N'মিরপুর ১৪', 9),
            (N'pallabi', N'mirpur', N'পল্লবী', 10),
            (N'kafrul', N'mirpur', N'কাফরুল', 11),
            (N'shah-ali', N'mirpur', N'শাহ আলী', 12),
            (N'rupnagar', N'mirpur', N'রূপনগর', 13),
            (N'tejgaon-industrial-area', N'tejgaon', N'তেজগাঁও শিল্প এলাকা', 1),
            (N'mohammadpur', N'tejgaon', N'মোহাম্মদপুর', 2),
            (N'adabor', N'tejgaon', N'আদাবর', 3),
            (N'sher-e-bangla-nagar', N'tejgaon', N'শেরেবাংলা নগর', 4),
            (N'karwan-bazar', N'tejgaon', N'কারওয়ান বাজার', 5),
            (N'gulshan-1', N'gulshan', N'গুলশান ১', 1),
            (N'gulshan-2', N'gulshan', N'গুলশান ২', 2),
            (N'banani', N'gulshan', N'বনানী', 3),
            (N'baridhara', N'gulshan', N'বারিধারা', 4),
            (N'niketon', N'gulshan', N'নিকেতন', 5),
            (N'cantonment', N'gulshan', N'ক্যান্টনমেন্ট', 6),
            (N'ecb-chattar', N'gulshan', N'ইসিবি চত্বর', 7),
            (N'shahbagh', N'ramna', N'শাহবাগ', 1),
            (N'ramna-area', N'ramna', N'রমনা', 2),
            (N'new-market', N'ramna', N'নিউমার্কেট', 3),
            (N'paltan', N'ramna', N'পল্টন', 4),
            (N'dhaka-university-area', N'ramna', N'ঢাকা বিশ্ববিদ্যালয় এলাকা', 5),
            (N'motijheel-area', N'motijheel', N'মতিঝিল', 1),
            (N'gopibagh', N'motijheel', N'গোপীবাগ', 2),
            (N'kamalapur', N'motijheel', N'কমলাপুর', 3),
            (N'khilgaon', N'motijheel', N'খিলগাঁও', 4),
            (N'sabujbagh', N'motijheel', N'সবুজবাগ', 5),
            (N'lalbagh-area', N'lalbagh', N'লালবাগ', 1),
            (N'chawkbazar', N'lalbagh', N'চকবাজার', 2),
            (N'azimpur', N'lalbagh', N'আজিমপুর', 3),
            (N'hazaribagh', N'lalbagh', N'হাজারীবাগ', 4),
            (N'kamrangirchar', N'lalbagh', N'কামরাঙ্গীরচর', 5),
            (N'wari-area', N'wari', N'ওয়ারী', 1),
            (N'sutrapur', N'wari', N'সূত্রাপুর', 2),
            (N'gendaria', N'wari', N'গেন্ডারিয়া', 3),
            (N'narinda', N'wari', N'নারিন্দা', 4),
            (N'shyampur', N'wari', N'শ্যামপুর', 5),
            (N'uttara-sector-01', N'uttara', N'সেক্টর ১', 1),
            (N'uttara-sector-02', N'uttara', N'সেক্টর ২', 2),
            (N'uttara-sector-03', N'uttara', N'সেক্টর ৩', 3),
            (N'uttara-sector-04', N'uttara', N'সেক্টর ৪', 4),
            (N'uttara-sector-05', N'uttara', N'সেক্টর ৫', 5),
            (N'uttara-sector-06', N'uttara', N'সেক্টর ৬', 6),
            (N'uttara-sector-07', N'uttara', N'সেক্টর ৭', 7),
            (N'uttara-sector-08', N'uttara', N'সেক্টর ৮', 8),
            (N'uttara-sector-09', N'uttara', N'সেক্টর ৯', 9),
            (N'uttara-sector-10', N'uttara', N'সেক্টর ১০', 10),
            (N'uttara-sector-11', N'uttara', N'সেক্টর ১১', 11),
            (N'uttara-sector-12', N'uttara', N'সেক্টর ১২', 12),
            (N'uttara-sector-13', N'uttara', N'সেক্টর ১৩', 13),
            (N'uttara-sector-14', N'uttara', N'সেক্টর ১৪', 14),
            (N'uttara-sector-15', N'uttara', N'সেক্টর ১৫', 15),
            (N'uttara-sector-16', N'uttara', N'সেক্টর ১৬', 16),
            (N'uttara-sector-17', N'uttara', N'সেক্টর ১৭', 17),
            (N'uttara-sector-18', N'uttara', N'সেক্টর ১৮', 18),
            (N'diabari', N'uttara', N'দিয়াবাড়ি', 19),
            (N'tongi-partial', N'uttara', N'টঙ্গী আংশিক', 20),
            (N'abdullahpur', N'uttara', N'আবদুল্লাহপুর', 21),
            (N'azampur', N'uttara', N'আজমপুর', 22)
    ) AS source (Id, DivisionId, NameBn, DisplayOrder)
    ON target.Id = source.Id
    WHEN MATCHED THEN
        UPDATE SET
            DivisionId = source.DivisionId,
            NameBn = source.NameBn,
            DisplayOrder = source.DisplayOrder
    WHEN NOT MATCHED THEN
        INSERT (Id, DivisionId, NameBn, DisplayOrder)
        VALUES (source.Id, source.DivisionId, source.NameBn, source.DisplayOrder);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    THROW;
END CATCH;
