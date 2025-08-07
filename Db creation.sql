
-- Drop and Create Database
DROP DATABASE IF EXISTS WasteManagement;
GO

CREATE DATABASE WasteManagement;
GO

USE WasteManagement;
GO

-- =====================================================
-- ADDRESS NORMALIZATION TABLES
-- =====================================================

-- States Table
CREATE TABLE States (
    StateId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    StateName NVARCHAR(100) NOT NULL UNIQUE,
    StateCode NVARCHAR(10),
    CountryId UNIQUEIDENTIFIER, -- For future country support
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE()
);

-- Cities Table
CREATE TABLE Cities (
    CityId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    StateId UNIQUEIDENTIFIER NOT NULL,
    CityName NVARCHAR(100) NOT NULL,
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (StateId) REFERENCES States(StateId),
    UNIQUE(StateId, CityName)
);

-- Streets Table
CREATE TABLE Streets (
    StreetId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    CityId UNIQUEIDENTIFIER NOT NULL,
    StreetName NVARCHAR(200) NOT NULL,
    PostalCode NVARCHAR(20),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (CityId) REFERENCES Cities(CityId),
    UNIQUE(CityId, StreetName, PostalCode)
);

-- =====================================================
-- TENANT AND ORGANIZATIONAL TABLES
-- =====================================================

-- Tenants Table (Multi-tenant support)
CREATE TABLE Tenants (
    TenantId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    TenantName NVARCHAR(100) NOT NULL,
    StreetId UNIQUEIDENTIFIER,
    Phone NVARCHAR(20),
    Email NVARCHAR(100),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (StreetId) REFERENCES Streets(StreetId)
);

-- Sites Table (A tenant can have multiple sites)
CREATE TABLE Sites (
    SiteId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    TenantId UNIQUEIDENTIFIER NOT NULL,
    SiteName NVARCHAR(100) NOT NULL,
    SitePrefix NVARCHAR(10) NOT NULL,
    StreetId UNIQUEIDENTIFIER,
    Phone NVARCHAR(20),
    Email NVARCHAR(100),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId),
    FOREIGN KEY (StreetId) REFERENCES Streets(StreetId)
);

-- Weighbridges Table (A site can have multiple weighbridges)
CREATE TABLE Weighbridges (
    WeighbridgeId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    SiteId UNIQUEIDENTIFIER NOT NULL,
    WeighbridgeName NVARCHAR(100) NOT NULL,
    WeighbridgePrefix NVARCHAR(10) NOT NULL,
    Location NVARCHAR(200), -- Loading point
    TotalDecks INT DEFAULT 1,
    Brand NVARCHAR(50) DEFAULT 'Rinstrum',
    SerialPortConfig NVARCHAR(50), -- RS-232 configuration
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (SiteId) REFERENCES Sites(SiteId)
);

-- =====================================================
-- VEHICLE AND DRIVER MANAGEMENT
-- =====================================================

-- Vehicles Table
CREATE TABLE Vehicles (
    VehicleId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    TenantId UNIQUEIDENTIFIER NOT NULL,
    RegistrationNumber NVARCHAR(20) NOT NULL UNIQUE,
    FleetNumber NVARCHAR(20),
    TareWeight DECIMAL(10,2), -- Empty vehicle weight
    TotalAxles INT DEFAULT 2, -- Number of axles/decks this vehicle has
    VehicleType NVARCHAR(50), -- 'Truck', 'Trailer', 'Semi-Trailer', etc.
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
);

-- Vehicle Axle Configuration Table (Dynamic axle limits per vehicle)
CREATE TABLE VehicleAxleConfig (
    AxleConfigId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    VehicleId UNIQUEIDENTIFIER NOT NULL,
    AxleNumber INT NOT NULL, -- 1, 2, 3, 4, etc.
    AxleType NVARCHAR(50), -- 'Steer', 'Drive', 'Trailer', etc.
    MaxAllowedWeight DECIMAL(10,2) NOT NULL,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (VehicleId) REFERENCES Vehicles(VehicleId) ON DELETE CASCADE,
    UNIQUE(VehicleId, AxleNumber)
);

-- Drivers Table
CREATE TABLE Drivers (
    DriverId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    TenantId UNIQUEIDENTIFIER NOT NULL,
    DriverName NVARCHAR(100) NOT NULL,
    StreetId UNIQUEIDENTIFIER,
    Phone NVARCHAR(20),
    Email NVARCHAR(100),
    LicenseNumber NVARCHAR(50),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId),
    FOREIGN KEY (StreetId) REFERENCES Streets(StreetId)
);

-- =====================================================
-- CUSTOMER AND PRODUCT MANAGEMENT
-- =====================================================

-- Customers Table
CREATE TABLE Customers (
    CustomerId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    TenantId UNIQUEIDENTIFIER NOT NULL,
    CustomerName NVARCHAR(100) NOT NULL,
    StreetId UNIQUEIDENTIFIER,
    Phone NVARCHAR(20),
    Email NVARCHAR(100),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId),
    FOREIGN KEY (StreetId) REFERENCES Streets(StreetId)
);

-- Products Table
CREATE TABLE Products (
    ProductId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    TenantId UNIQUEIDENTIFIER NOT NULL,
    ProductCode NVARCHAR(20) NOT NULL,
    ProductName NVARCHAR(100) NOT NULL,
    ProductDescription NVARCHAR(500),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
);

-- =====================================================
-- JOB AND TRANSACTION MANAGEMENT
-- =====================================================

-- Jobs Table (Created when truck is ready to load)
CREATE TABLE Jobs (
    JobId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    TenantId UNIQUEIDENTIFIER NOT NULL,
    JobNumber NVARCHAR(50) NOT NULL UNIQUE,
    SourceSiteId UNIQUEIDENTIFIER NOT NULL,
    DestinationSiteId UNIQUEIDENTIFIER,
    ProductId UNIQUEIDENTIFIER NOT NULL,
    DriverId UNIQUEIDENTIFIER NOT NULL,
    VehicleId UNIQUEIDENTIFIER NOT NULL,
    CustomerId UNIQUEIDENTIFIER NOT NULL,
    JobStatus NVARCHAR(20) DEFAULT 'Created', -- Created, InProgress, Completed, Cancelled
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId),
    FOREIGN KEY (SourceSiteId) REFERENCES Sites(SiteId),
    FOREIGN KEY (DestinationSiteId) REFERENCES Sites(SiteId),
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId),
    FOREIGN KEY (DriverId) REFERENCES Drivers(DriverId),
    FOREIGN KEY (VehicleId) REFERENCES Vehicles(VehicleId),
    FOREIGN KEY (CustomerId) REFERENCES Customers(CustomerId)
);

-- Weighing Transactions Table (Main weighing records)
CREATE TABLE WeighingTransactions (
    TransactionId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    DocketNumber NVARCHAR(50) NOT NULL UNIQUE,
    JobId UNIQUEIDENTIFIER NOT NULL,
    WeighbridgeId UNIQUEIDENTIFIER NOT NULL,
    VehicleId UNIQUEIDENTIFIER NOT NULL,
    DriverId UNIQUEIDENTIFIER NOT NULL,
    CustomerId UNIQUEIDENTIFIER NOT NULL,
    ProductId UNIQUEIDENTIFIER NOT NULL,
    
    -- Weight measurements (calculated from deck weights)
    GrossWeight DECIMAL(10,2) DEFAULT 0,
    TareWeight DECIMAL(10,2),
    NetWeight AS (GrossWeight - ISNULL(TareWeight, 0)),
    
    -- Status and validation
    IsOverloaded BIT DEFAULT 0,
    DocketIssued BIT DEFAULT 0,
    
    -- Location information
    SourceSiteId UNIQUEIDENTIFIER,
    DestinationSiteId UNIQUEIDENTIFIER,
    
    -- Timestamps
    WeighingDateTime DATETIME2 DEFAULT GETDATE(),
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE(),
    
    -- Offline sync support
    IsSynced BIT DEFAULT 0,
    LocalTransactionId NVARCHAR(50), -- For offline transactions
    
    FOREIGN KEY (JobId) REFERENCES Jobs(JobId),
    FOREIGN KEY (WeighbridgeId) REFERENCES Weighbridges(WeighbridgeId),
    FOREIGN KEY (VehicleId) REFERENCES Vehicles(VehicleId),
    FOREIGN KEY (DriverId) REFERENCES Drivers(DriverId),
    FOREIGN KEY (CustomerId) REFERENCES Customers(CustomerId),
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId),
    FOREIGN KEY (SourceSiteId) REFERENCES Sites(SiteId),
    FOREIGN KEY (DestinationSiteId) REFERENCES Sites(SiteId)
);

-- Deck Weights Table (Dynamic deck support)
CREATE TABLE DeckWeights (
    DeckWeightId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    TransactionId UNIQUEIDENTIFIER NOT NULL,
    DeckNumber INT NOT NULL, -- 1, 2, 3, 4, etc.
    Weight DECIMAL(10,2) NOT NULL DEFAULT 0,
    AxleType NVARCHAR(50), -- 'Steer', 'Drive', 'Trailer', etc.
    MaxAllowedWeight DECIMAL(10,2), -- From vehicle configuration
    IsOverloaded BIT DEFAULT 0,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (TransactionId) REFERENCES WeighingTransactions(TransactionId) ON DELETE CASCADE,
    UNIQUE(TransactionId, DeckNumber)
);

-- Overload Records Table (For tracking overloaded transactions)
CREATE TABLE OverloadRecords (
    OverloadId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    TransactionId UNIQUEIDENTIFIER NOT NULL,
    WeighbridgeId UNIQUEIDENTIFIER NOT NULL,
    VehicleId UNIQUEIDENTIFIER NOT NULL,
    OverloadAmount DECIMAL(10,2),
    AxleOverloads NVARCHAR(200), -- JSON or comma-separated axle overload details
    RecordedDateTime DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (TransactionId) REFERENCES WeighingTransactions(TransactionId),
    FOREIGN KEY (WeighbridgeId) REFERENCES Weighbridges(WeighbridgeId),
    FOREIGN KEY (VehicleId) REFERENCES Vehicles(VehicleId)
);

-- =====================================================
-- USER MANAGEMENT AND SECURITY
-- =====================================================

-- Roles Table
CREATE TABLE Roles (
    RoleId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    RoleName NVARCHAR(50) NOT NULL UNIQUE,
    RoleDescription NVARCHAR(200),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE()
);

-- Users Table
CREATE TABLE Users (
    UserId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    TenantId UNIQUEIDENTIFIER, -- NULL for Super Admin
    Username NVARCHAR(100) NOT NULL UNIQUE, -- Email address
    Email NVARCHAR(100) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(256) NOT NULL,
    PasswordSalt NVARCHAR(128) NOT NULL,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    IsActive BIT DEFAULT 1,
    PasswordExpiryDate DATETIME2,
    LastLoginDate DATETIME2,
    FailedLoginAttempts INT DEFAULT 0,
    IsLocked BIT DEFAULT 0,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
);

-- User Roles Table (Many-to-many relationship)
CREATE TABLE UserRoles (
    UserRoleId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    RoleId UNIQUEIDENTIFIER NOT NULL,
    AssignedDate DATETIME2 DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1,
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (RoleId) REFERENCES Roles(RoleId),
    UNIQUE(UserId, RoleId)
);

-- Audit Log Table
CREATE TABLE AuditLogs (
    AuditId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER,
    TenantId UNIQUEIDENTIFIER,
    Action NVARCHAR(100) NOT NULL,
    TableName NVARCHAR(100),
    RecordId NVARCHAR(50),
    OldValues NVARCHAR(MAX), -- JSON format
    NewValues NVARCHAR(MAX), -- JSON format
    IPAddress NVARCHAR(45),
    UserAgent NVARCHAR(500),
    ActionDateTime DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
);
