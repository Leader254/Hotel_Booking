-- Create a new database called 'HotelDB'
-- Connect to the 'master' database to run this snippet
USE master
GO
-- Create the new database if it does not exist already
IF NOT EXISTS (
    SELECT [name]
        FROM sys.databases
        WHERE [name] = N'HotelDB'
)
CREATE DATABASE HotelDB
GO

-- Create a new table called '[UserRoles]' in schema '[dbo]'
-- Drop the table if it already exists
IF OBJECT_ID('[dbo].[UserRoles]', 'U') IS NOT NULL
DROP TABLE [dbo].[UserRoles]
GO
-- Create the table in the specified schema
CREATE TABLE [dbo].[UserRoles]
(
    [RoleID] INT PRIMARY KEY IDENTITY(1,1), 
    [RoleName] NVARCHAR(50),
    [IsActive] BIT DEFAULT 1,
    [Description] NVARCHAR(255)
);
GO

-- Create a new table called '[Users]' in schema '[dbo]'
-- Drop the table if it already exists
IF OBJECT_ID('[dbo].[Users]', 'U') IS NOT NULL
DROP TABLE [dbo].[Users]
GO
-- Create the table in the specified schema
CREATE TABLE [dbo].[Users]
(
    [UserID] INT PRIMARY KEY IDENTITY(1,1), -- Primary Key column
    [RoleID] INT,
    [Email] NVARCHAR(50) UNIQUE,
    [PasswordHash] NVARCHAR(255),
    [CreatedAt] DATETIME DEFAULT GETDATE(),
    [LastLogin] DATETIME,
    [IsActive] BIT DEFAULT 1,
    [CreatedBy] NVARCHAR(100),
    [CreatedDate] DATETIME DEFAULT GETDATE(),
    [ModifiedBy] NVARCHAR(100),
    [ModifiedDate] DATETIME,
    FOREIGN KEY (RoleID) REFERENCES UserRoles(RoleID)
);
GO

-- Create a new table called '[Countries]' in schema '[dbo]'
-- Drop the table if it already exists
IF OBJECT_ID('[dbo].[Countries]', 'U') IS NOT NULL
DROP TABLE [dbo].[Countries]
GO
-- Create the table in the specified schema
CREATE TABLE [dbo].[Countries]
(
    [CountryID] INT PRIMARY KEY IDENTITY(1,1), -- Primary Key column
    [CountryName] NVARCHAR(50),
    [CountryCode] NVARCHAR(10),
    [IsActive] BIT DEFAULT 1
);
GO

-- Create a new table called '[States]' in schema '[dbo]'
-- Drop the table if it already exists
IF OBJECT_ID('[dbo].[States]', 'U') IS NOT NULL
DROP TABLE [dbo].[States]
GO
-- Create the table in the specified schema
CREATE TABLE [dbo].[States]
(
    [SateID] INT PRIMARY KEY IDENTITY(1,1), -- Primary Key column
    [StateName] NVARCHAR(50),
    [CountryID] INT,
    [IsActive] BIT DEFAULT 1,
    FOREIGN KEY (CountryID) REFERENCES Countries(CountryID)
);
GO

-- Select rows from a Table or View '[States]' in schema '[dbo]'
SELECT * FROM [dbo].[States]

EXEC sp_rename 'States.SateID', 'StateID', 'COLUMN';

CREATE TABLE RoomTypes (
    RoomTypeID INT PRIMARY KEY IDENTITY(1,1),
    TypeName NVARCHAR(50),
    AccessibilityFeatures NVARCHAR(255),
    Description NVARCHAR(255),
    IsActive BIT DEFAULT 1,
    CreatedBy NVARCHAR(100),
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedBy NVARCHAR(100),
    ModifiedDate DATETIME
);
GO

-- Rooms of the Hotel
CREATE TABLE Rooms (
    RoomID INT PRIMARY KEY IDENTITY(1,1),
    RoomNumber NVARCHAR(10) UNIQUE,
    RoomTypeID INT,
    Price DECIMAL(10,2),
    BedType NVARCHAR(50),
    ViewType NVARCHAR(50),
    Status NVARCHAR(50) CHECK (Status IN ('Available', 'Under Maintenance', 'Occupied')),
    IsActive BIT DEFAULT 1,
    CreatedBy NVARCHAR(100),
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedBy NVARCHAR(100),
    ModifiedDate DATETIME,
    FOREIGN KEY (RoomTypeID) REFERENCES RoomTypes(RoomTypeID)
);
GO

-- Amenities Available in the hotel
CREATE TABLE Amenities (
    AmenityID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100),
    Description NVARCHAR(255),
    IsActive BIT DEFAULT 1,
    CreatedBy NVARCHAR(100),
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedBy NVARCHAR(100),
    ModifiedDate DATETIME
);
GO

-- Linking room types with amenities
CREATE TABLE RoomAmenities (
    RoomTypeID INT,
    AmenityID INT,
    FOREIGN KEY (RoomTypeID) REFERENCES RoomTypes(RoomTypeID),
    FOREIGN KEY (AmenityID) REFERENCES Amenities(AmenityID),
    PRIMARY KEY (RoomTypeID, AmenityID) -- Composite Primary Key to avoid duplicates
);
GO

-- The Guests who are going to stay in the hotel
CREATE TABLE Guests (
    GuestID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Email NVARCHAR(100),
    Phone NVARCHAR(15),
    AgeGroup NVARCHAR(20) CHECK (AgeGroup IN ('Adult', 'Child', 'Infant')),
    Address NVARCHAR(255),
    CountryID INT,
    StateID INT,
    CreatedBy NVARCHAR(100),
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedBy NVARCHAR(100),
    ModifiedDate DATETIME,
    FOREIGN KEY (UserID) REFERENCES Users(UserID),
    FOREIGN KEY (CountryID) REFERENCES Countries(CountryID),
    FOREIGN KEY (StateID) REFERENCES States(StateID)
);
GO

-- Storing Reservation Information
CREATE TABLE Reservations (
    ReservationID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT,
    RoomID INT,
    BookingDate DATE,
    CheckInDate DATE,
    CheckOutDate DATE,
    NumberOfGuests INT,
    Status NVARCHAR(50) CHECK (Status IN ('Reserved', 'Checked-in', 'Checked-out', 'Cancelled')),
    CreatedBy NVARCHAR(100),
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedBy NVARCHAR(100),
    ModifiedDate DATETIME,
    FOREIGN KEY (UserID) REFERENCES Users(UserID),
    FOREIGN KEY (RoomID) REFERENCES Rooms(RoomID),
    CONSTRAINT CHK_CheckOutDate CHECK (CheckOutDate > CheckInDate)  
);
GO

-- Mapping table for guests linked to reservations
CREATE TABLE ReservationGuests (
    ReservationGuestID INT PRIMARY KEY IDENTITY(1,1),
    ReservationID INT,
    GuestID INT,
    FOREIGN KEY (ReservationID) REFERENCES Reservations(ReservationID),
    FOREIGN KEY (GuestID) REFERENCES Guests(GuestID)
);
GO
-- Table for tracking batch payments
CREATE TABLE PaymentBatches (
    PaymentBatchID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT,
    PaymentDate DATETIME,
    TotalAmount DECIMAL(10,2),
    PaymentMethod NVARCHAR(50),
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);
GO
-- Individual payments Linked to Reservations and Batch Payment
CREATE TABLE Payments (
    PaymentID INT PRIMARY KEY IDENTITY(1,1),
    ReservationID INT,
    Amount DECIMAL(10,2),
    PaymentBatchID INT,
    FOREIGN KEY (ReservationID) REFERENCES Reservations(ReservationID),
    FOREIGN KEY (PaymentBatchID) REFERENCES PaymentBatches(PaymentBatchID)
);
GO
-- Cancellations tracking with a fee
CREATE TABLE Cancellations (
    CancellationID INT PRIMARY KEY IDENTITY(1,1),
    ReservationID INT,
    CancellationDate DATETIME,
    Reason NVARCHAR(255),
    CancellationFee DECIMAL(10,2),
    CancellationStatus NVARCHAR(50) CHECK (CancellationStatus IN ('Pending', 'Approved', 'Denied')),
    CreatedBy NVARCHAR(100),
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedBy NVARCHAR(100),
    ModifiedDate DATETIME,
    FOREIGN KEY (ReservationID) REFERENCES Reservations(ReservationID)
);
GO
-- Table for Storing Refund Methods
CREATE TABLE RefundMethods (
    MethodID INT PRIMARY KEY IDENTITY(1,1),
    MethodName NVARCHAR(50),
    IsActive BIT DEFAULT 1,
);
GO
-- Table for tracking Refunds
CREATE TABLE Refunds (
    RefundID INT PRIMARY KEY IDENTITY(1,1),
    PaymentID INT,
    RefundAmount DECIMAL(10,2),
    RefundDate DATETIME DEFAULT GETDATE(),
    RefundReason NVARCHAR(255),
    RefundMethodID INT,
    ProcessedByUserID INT,
    RefundStatus NVARCHAR(50),
    FOREIGN KEY (PaymentID) REFERENCES Payments(PaymentID),
    FOREIGN KEY (RefundMethodID) REFERENCES RefundMethods(MethodID),
    FOREIGN KEY (ProcessedByUserID) REFERENCES Users(UserID)
);
GO
-- Feedback Table
CREATE TABLE Feedbacks (
    FeedbackID INT PRIMARY KEY IDENTITY(1,1),
    ReservationID INT,
    GuestID INT,
    Rating INT CHECK (Rating BETWEEN 1 AND 5),  -- Rating scale from 1 to 5
    Comment NVARCHAR(1000),  -- Optional detailed comment
    FeedbackDate DATETIME,  -- The date and time the feedback was submitted
    FOREIGN KEY (ReservationID) REFERENCES Reservations(ReservationID),
    FOREIGN KEY (GuestID) REFERENCES Guests(GuestID)
);
GO


-- Inserting Data into UserRoles table
INSERT INTO UserRoles (RoleName, Description) VALUES
('Admin', 'Administrator with full access'),
('Guest', 'Guest user with limited access'), -- You can replace Guest with User also
('Manager', 'Hotel manager with extended privileges');

-- Inserting Data into Countries and States tables
-- Insert Countries
INSERT INTO Countries (CountryName, CountryCode) VALUES
('India', 'IN'),
('USA', 'US'),
('UK', 'GB');

-- Assuming the IDs for countries are 1 for India, 2 for USA, and 3 for UK
-- Insert States
INSERT INTO States (StateName, CountryID) VALUES
('Maharashtra', 1),
('Delhi', 1),
('Texas', 2),
('California', 2),
('England', 3),
('Scotland', 3);

-- Inserting Data into RoomTypes table
INSERT INTO RoomTypes (TypeName, AccessibilityFeatures, Description, CreatedBy, ModifiedBy) VALUES
('Standard', 'Wheelchair ramps, Grab bars in bathroom', 'Basic room with essential amenities', 'System', 'System'),
('Deluxe', 'Wheelchair accessible, Elevator access', 'High-end room with luxurious amenities', 'System', 'System'),
('Executive', 'Wide door frames, Accessible bathroom', 'Room for business travelers with a work area', 'System', 'System'),
('Family', 'Child-friendly facilities, Safety features', 'Spacious room for families with children', 'System', 'System');

-- Inserting Data into Rooms table
-- Assuming the IDs for room types are 1 for Standard, 2 for Deluxe, 3 for Executive, and 4 for Family
INSERT INTO Rooms
    (RoomNumber, RoomTypeID, Price, BedType, ViewType, Status, CreatedBy, ModifiedBy)
VALUES
    ('101', 1, 100.00, 'Queen', 'Sea', 'Available', 'System', 'System'),
    ('102', 1, 100.00, 'Queen', 'City', 'Under Maintenance', 'System', 'System'),
    ('201', 2, 150.00, 'King', 'Garden', 'Occupied', 'System', 'System'),
    ('301', 3, 200.00, 'King', 'Sea', 'Available', 'System', 'System'),
    ('401', 4, 250.00, 'Twin', 'Pool', 'Occupied', 'System', 'System');

-- Inserting Data into Amenities table
INSERT INTO Amenities (Name, Description, CreatedBy, ModifiedBy) VALUES
('Wi-Fi', 'High-speed wireless internet access', 'System', 'System'),
('Pool', 'Outdoor swimming pool with lifeguard', 'System', 'System'),
('SPA', 'Full-service spa and wellness center', 'System', 'System'),
('Fitness Center', 'Gym with modern equipment', 'System', 'System');

-- Linking Room Types with Amenities
-- Assuming the IDs for amenities are 1 for Wi-Fi, 2 for Pool, 3 for SPA, and 4 for Fitness Center
INSERT INTO RoomAmenities (RoomTypeID, AmenityID) VALUES
(1, 1), (1, 4),  -- Standard rooms have Wi-Fi and access to Fitness Center
(2, 1), (2, 2), (2, 3), (2, 4),  -- Deluxe rooms have all amenities
(3, 1), (3, 4),  -- Executive rooms have Wi-Fi and Fitness Center
(4, 1), (4, 2), (4, 3), (4, 4);  -- Family rooms have all amenities

-- Inserting Data into RefundMethods table
INSERT INTO RefundMethods (MethodName) VALUES
('Cash'),
('Credit Card'),
('Online Transfer'),
<<<<<<< HEAD
('Check');
=======
('Check');


-- Add a New User
CREATE PROCEDURE spAddUser
    @Email NVARCHAR(100),
    @PasswordHash NVARCHAR(255),
    @CreatedBy NVARCHAR(100),
    @UserID INT OUTPUT,
    @ErrorMessage NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Check if email or password is null
        IF @Email IS NULL OR @PasswordHash IS NULL
        BEGIN
            SET @ErrorMessage = 'Email and Password cannot be null.';
            SET @UserID = -1;
            RETURN;
        END

        -- Check if email already exists in the system
        IF EXISTS (SELECT 1 FROM Users WHERE Email = @Email)
        BEGIN
            SET @ErrorMessage = 'A user with the given email already exists.';
            SET @UserID = -1;
            RETURN;
        END

        -- Default role ID for new users
        DECLARE @DefaultRoleID INT = 2; -- Assuming 'Guest' role ID is 2

        BEGIN TRANSACTION
            INSERT INTO Users (RoleID, Email, PasswordHash, CreatedBy, CreatedDate)
            VALUES (@DefaultRoleID, @Email, @PasswordHash, @CreatedBy, GETDATE());

            SET @UserID = SCOPE_IDENTITY(); -- Retrieve the newly created UserID
            SET @ErrorMessage = NULL;
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        -- Handle exceptions
        ROLLBACK TRANSACTION
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @UserID = -1;
    END CATCH
END;
GO

-- Assign a Role to User
CREATE PROCEDURE spAssignUserRole
    @UserID INT,
    @RoleID INT,
    @ErrorMessage NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Check if the user exists
        IF NOT EXISTS (SELECT 1 FROM Users WHERE UserID = @UserID)
        BEGIN
            SET @ErrorMessage = 'User not found.';
            RETURN;
        END

        -- Check if the role exists
        IF NOT EXISTS (SELECT 1 FROM UserRoles WHERE RoleID = @RoleID)
        BEGIN
            SET @ErrorMessage = 'Role not found.';
            RETURN;
        END

        -- Update user role
        BEGIN TRANSACTION
            UPDATE Users SET RoleID = @RoleID WHERE UserID = @UserID;
        COMMIT TRANSACTION

        SET @ErrorMessage = NULL;
    END TRY
    BEGIN CATCH
        -- Handle exceptions
        ROLLBACK TRANSACTION
        SET @ErrorMessage = ERROR_MESSAGE();
    END CATCH
END;
GO

-- List All Users
CREATE PROCEDURE spListAllUsers
    @IsActive BIT = NULL  -- Optional parameter to filter by IsActive status
AS
BEGIN
    SET NOCOUNT ON;

    -- Select users based on active status
    IF @IsActive IS NULL
    BEGIN
        SELECT UserID, Email, RoleID, IsActive, LastLogin, CreatedBy, CreatedDate FROM Users;
    END
    ELSE
    BEGIN
        SELECT UserID, Email, RoleID, IsActive, LastLogin, CreatedBy, CreatedDate FROM Users 
  WHERE IsActive = @IsActive;
    END
END;
GO

-- Get User by ID
CREATE PROCEDURE spGetUserByID
    @UserID INT,
    @ErrorMessage NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if the user exists
    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserID = @UserID)
    BEGIN
        SET @ErrorMessage = 'User not found.';
        RETURN;
    END

    -- Retrieve user details
    SELECT UserID, Email, RoleID, IsActive, LastLogin, CreatedBy, CreatedDate FROM Users WHERE UserID = @UserID;
    SET @ErrorMessage = NULL;
END;
GO

-- Update User Information
CREATE PROCEDURE spUpdateUserInformation
    @UserID INT,
    @Email NVARCHAR(100),
    @Password NVARCHAR(100),
    @ModifiedBy NVARCHAR(100),
    @ErrorMessage NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Check user existence
        IF NOT EXISTS (SELECT 1 FROM Users WHERE UserID = @UserID)
        BEGIN
            SET @ErrorMessage = 'User not found.';
            RETURN;
        END

        -- Check email uniqueness except for the current user
        IF EXISTS (SELECT 1 FROM Users WHERE Email = @Email AND UserID <> @UserID)
        BEGIN
            SET @ErrorMessage = 'Email already used by another user.';
            RETURN;
        END

        -- Update user details
        BEGIN TRANSACTION
            UPDATE Users
            SET Email = @Email, PasswordHash =@Password, ModifiedBy = @ModifiedBy, ModifiedDate = GETDATE()
            WHERE UserID = @UserID;
        COMMIT TRANSACTION

        SET @ErrorMessage = NULL;
    END TRY
    -- Handle exceptions
    BEGIN CATCH
        ROLLBACK TRANSACTION
        SET @ErrorMessage = ERROR_MESSAGE();
    END CATCH
END;
GO

-- Activate/Deactivate User
-- This can also be used for deleting a User
CREATE PROCEDURE spToggleUserActive
    @UserID INT,
    @IsActive BIT,
    @ErrorMessage NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Check user existence
        IF NOT EXISTS (SELECT 1 FROM Users WHERE UserID = @UserID)
        BEGIN
            SET @ErrorMessage = 'User not found.';
            RETURN;
        END

        -- Update IsActive status
        BEGIN TRANSACTION
            UPDATE Users SET IsActive = @IsActive WHERE UserID = @UserID;
        COMMIT TRANSACTION

        SET @ErrorMessage = NULL;
    END TRY
    -- Handle exceptions
    BEGIN CATCH
        ROLLBACK TRANSACTION
        SET @ErrorMessage = ERROR_MESSAGE();
    END CATCH
END;
GO

-- Login a User
CREATE PROCEDURE spLoginUser
    @Email NVARCHAR(100),
    @PasswordHash NVARCHAR(255),
    @UserID INT OUTPUT,
    @ErrorMessage NVARCHAR(255) OUTPUT
AS
BEGIN
    -- Attempt to retrieve the user based on email and password hash
    SELECT @UserID = UserID FROM Users WHERE Email = @Email AND PasswordHash = @PasswordHash;

    -- Check if user ID was set (means credentials are correct)
    IF @UserID IS NOT NULL
    BEGIN
        -- Check if the user is active
        IF EXISTS (SELECT 1 FROM Users WHERE UserID = @UserID AND IsActive = 1)
        BEGIN
            -- Update the last login time
            UPDATE Users SET LastLogin = GETDATE() WHERE UserID = @UserID;
            SET @ErrorMessage = NULL; -- Clear any previous error messages
        END
        ELSE
        BEGIN
            SET @ErrorMessage = 'User account is not active.';
            SET @UserID = NULL; -- Reset the UserID as login should not be considered successful
        END
    END
    ELSE
    BEGIN
        SET @ErrorMessage = 'Invalid Credentials.';
    END
END;
GO
>>>>>>> 582d2de (first commit)
