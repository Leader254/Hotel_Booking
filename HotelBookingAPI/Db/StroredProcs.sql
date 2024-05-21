-- User stored procedure
-- Add a New User
CREATE PROCEDURE spAddUser @Email NVARCHAR(100),
@PasswordHash NVARCHAR(255),
@CreatedBy NVARCHAR(100),
@UserID INT OUTPUT,
@ErrorMessage NVARCHAR(255) OUTPUT AS BEGIN
SET NOCOUNT ON;
BEGIN TRY -- Check if email or password is null
IF @Email IS NULL
OR @PasswordHash IS NULL BEGIN
SET @ErrorMessage = 'Email and Password cannot be null.';
SET @UserID = -1;
RETURN;
END -- Check if email already exists in the system
IF EXISTS (
    SELECT 1
    FROM Users
    WHERE Email = @Email
) BEGIN
SET @ErrorMessage = 'A user with the given email already exists.';
SET @UserID = -1;
RETURN;
END -- Default role ID for new users
DECLARE @DefaultRoleID INT = 2;
-- Assuming 'Guest' role ID is 2
BEGIN TRANSACTION
INSERT INTO Users (
        RoleID,
        Email,
        PasswordHash,
        CreatedBy,
        CreatedDate
    )
VALUES (
        @DefaultRoleID,
        @Email,
        @PasswordHash,
        @CreatedBy,
        GETDATE()
    );
SET @UserID = SCOPE_IDENTITY();
-- Retrieve the newly created UserID
SET @ErrorMessage = NULL;
COMMIT TRANSACTION
END TRY BEGIN CATCH -- Handle exceptions
ROLLBACK TRANSACTION
SET @ErrorMessage = ERROR_MESSAGE();
SET @UserID = -1;
END CATCH
END;
GO -- Assign a Role to User
    CREATE PROCEDURE spAssignUserRole @UserID INT,
    @RoleID INT,
    @ErrorMessage NVARCHAR(255) OUTPUT AS BEGIN
SET NOCOUNT ON;
BEGIN TRY -- Check if the user exists
IF NOT EXISTS (
    SELECT 1
    FROM Users
    WHERE UserID = @UserID
) BEGIN
SET @ErrorMessage = 'User not found.';
RETURN;
END -- Check if the role exists
IF NOT EXISTS (
    SELECT 1
    FROM UserRoles
    WHERE RoleID = @RoleID
) BEGIN
SET @ErrorMessage = 'Role not found.';
RETURN;
END -- Update user role
BEGIN TRANSACTION
UPDATE Users
SET RoleID = @RoleID
WHERE UserID = @UserID;
COMMIT TRANSACTION
SET @ErrorMessage = NULL;
END TRY BEGIN CATCH -- Handle exceptions
ROLLBACK TRANSACTION
SET @ErrorMessage = ERROR_MESSAGE();
END CATCH
END;
GO -- List All Users
    CREATE PROCEDURE spListAllUsers @IsActive BIT = NULL -- Optional parameter to filter by IsActive status
    AS BEGIN
SET NOCOUNT ON;
-- Select users based on active status
IF @IsActive IS NULL BEGIN
SELECT UserID,
    Email,
    RoleID,
    IsActive,
    LastLogin,
    CreatedBy,
    CreatedDate
FROM Users;
END
ELSE BEGIN
SELECT UserID,
    Email,
    RoleID,
    IsActive,
    LastLogin,
    CreatedBy,
    CreatedDate
FROM Users
WHERE IsActive = @IsActive;
END
END;
GO -- Get User by ID
    CREATE PROCEDURE spGetUserByID @UserID INT,
    @ErrorMessage NVARCHAR(255) OUTPUT AS BEGIN
SET NOCOUNT ON;
-- Check if the user exists
IF NOT EXISTS (
    SELECT 1
    FROM Users
    WHERE UserID = @UserID
) BEGIN
SET @ErrorMessage = 'User not found.';
RETURN;
END -- Retrieve user details
SELECT UserID,
    Email,
    RoleID,
    IsActive,
    LastLogin,
    CreatedBy,
    CreatedDate
FROM Users
WHERE UserID = @UserID;
SET @ErrorMessage = NULL;
END;
GO -- Update User Information
    CREATE PROCEDURE spUpdateUserInformation @UserID INT,
    @Email NVARCHAR(100),
    @Password NVARCHAR(100),
    @ModifiedBy NVARCHAR(100),
    @ErrorMessage NVARCHAR(255) OUTPUT AS BEGIN
SET NOCOUNT ON;
BEGIN TRY -- Check user existence
IF NOT EXISTS (
    SELECT 1
    FROM Users
    WHERE UserID = @UserID
) BEGIN
SET @ErrorMessage = 'User not found.';
RETURN;
END -- Check email uniqueness except for the current user
IF EXISTS (
    SELECT 1
    FROM Users
    WHERE Email = @Email
        AND UserID <> @UserID
) BEGIN
SET @ErrorMessage = 'Email already used by another user.';
RETURN;
END -- Update user details
BEGIN TRANSACTION
UPDATE Users
SET Email = @Email,
    PasswordHash = @Password,
    ModifiedBy = @ModifiedBy,
    ModifiedDate = GETDATE()
WHERE UserID = @UserID;
COMMIT TRANSACTION
SET @ErrorMessage = NULL;
END TRY -- Handle exceptions
BEGIN CATCH ROLLBACK TRANSACTION
SET @ErrorMessage = ERROR_MESSAGE();
END CATCH
END;
GO -- Activate/Deactivate User
    -- This can also be used for deleting a User
    CREATE PROCEDURE spToggleUserActive @UserID INT,
    @IsActive BIT,
    @ErrorMessage NVARCHAR(255) OUTPUT AS BEGIN
SET NOCOUNT ON;
BEGIN TRY -- Check user existence
IF NOT EXISTS (
    SELECT 1
    FROM Users
    WHERE UserID = @UserID
) BEGIN
SET @ErrorMessage = 'User not found.';
RETURN;
END -- Update IsActive status
BEGIN TRANSACTION
UPDATE Users
SET IsActive = @IsActive
WHERE UserID = @UserID;
COMMIT TRANSACTION
SET @ErrorMessage = NULL;
END TRY -- Handle exceptions
BEGIN CATCH ROLLBACK TRANSACTION
SET @ErrorMessage = ERROR_MESSAGE();
END CATCH
END;
GO -- Login a User
    CREATE PROCEDURE spLoginUser @Email NVARCHAR(100),
    @PasswordHash NVARCHAR(255),
    @UserID INT OUTPUT,
    @ErrorMessage NVARCHAR(255) OUTPUT AS BEGIN -- Attempt to retrieve the user based on email and password hash
SELECT @UserID = UserID
FROM Users
WHERE Email = @Email
    AND PasswordHash = @PasswordHash;
-- Check if user ID was set (means credentials are correct)
IF @UserID IS NOT NULL BEGIN -- Check if the user is active
IF EXISTS (
    SELECT 1
    FROM Users
    WHERE UserID = @UserID
        AND IsActive = 1
) BEGIN -- Update the last login time
UPDATE Users
SET LastLogin = GETDATE()
WHERE UserID = @UserID;
SET @ErrorMessage = NULL;
-- Clear any previous error messages
END
ELSE BEGIN
SET @ErrorMessage = 'User account is not active.';
SET @UserID = NULL;
-- Reset the UserID as login should not be considered successful
END
END
ELSE BEGIN
SET @ErrorMessage = 'Invalid Credentials.';
END
END;
GO -- Stored Procedures for Room Types
    -- Create Room Type
    CREATE PROCEDURE spCreateRoomType @TypeName NVARCHAR(50),
    @AccessibilityFeatures NVARCHAR(255),
    @Description NVARCHAR(255),
    @CreatedBy NVARCHAR(100),
    @NewRoomTypeID INT OUTPUT,
    @StatusCode INT OUTPUT,
    @Message NVARCHAR(255) OUTPUT AS BEGIN
SET NOCOUNT ON;
BEGIN TRY BEGIN TRANSACTION IF NOT EXISTS (
    SELECT 1
    FROM RoomTypes
    WHERE TypeName = @TypeName
) BEGIN
INSERT INTO RoomTypes (
        TypeName,
        AccessibilityFeatures,
        Description,
        CreatedBy,
        CreatedDate
    )
VALUES (
        @TypeName,
        @AccessibilityFeatures,
        @Description,
        @CreatedBy,
        GETDATE()
    )
SET @NewRoomTypeID = SCOPE_IDENTITY()
SET @StatusCode = 0 -- Success
SET @Message = 'Room type created successfully.'
END
ELSE BEGIN
SET @StatusCode = 1 -- Failure due to duplicate name
SET @Message = 'Room type name already exists.'
END COMMIT TRANSACTION
END TRY BEGIN CATCH ROLLBACK TRANSACTION
SET @StatusCode = ERROR_NUMBER() -- SQL Server error number
SET @Message = ERROR_MESSAGE()
END CATCH
END
GO -- Update Room Type
    CREATE PROCEDURE spUpdateRoomType @RoomTypeID INT,
    @TypeName NVARCHAR(50),
    @AccessibilityFeatures NVARCHAR(255),
    @Description NVARCHAR(255),
    @ModifiedBy NVARCHAR(100),
    @StatusCode INT OUTPUT,
    @Message NVARCHAR(255) OUTPUT AS BEGIN
SET NOCOUNT ON;
BEGIN TRY BEGIN TRANSACTION -- Check if the updated type name already exists in another record
IF NOT EXISTS (
    SELECT 1
    FROM RoomTypes
    WHERE TypeName = @TypeName
        AND RoomTypeID <> @RoomTypeID
) BEGIN IF EXISTS (
    SELECT 1
    FROM RoomTypes
    WHERE RoomTypeID = @RoomTypeID
) BEGIN
UPDATE RoomTypes
SET TypeName = @TypeName,
    AccessibilityFeatures = @AccessibilityFeatures,
    Description = @Description,
    ModifiedBy = @ModifiedBy,
    ModifiedDate = GETDATE()
WHERE RoomTypeID = @RoomTypeID
SET @StatusCode = 0 -- Success
SET @Message = 'Room type updated successfully.'
END
ELSE BEGIN
SET @StatusCode = 2 -- Failure due to not found
SET @Message = 'Room type not found.'
END
END
ELSE BEGIN
SET @StatusCode = 1 -- Failure due to duplicate name
SET @Message = 'Another room type with the same name already exists.'
END COMMIT TRANSACTION
END TRY BEGIN CATCH ROLLBACK TRANSACTION
SET @StatusCode = ERROR_NUMBER() -- SQL Server error number
SET @Message = ERROR_MESSAGE()
END CATCH
END
GO -- Delete Room Type By Id
    CREATE PROCEDURE spDeleteRoomType @RoomTypeID INT,
    @StatusCode INT OUTPUT,
    @Message NVARCHAR(255) OUTPUT AS BEGIN
SET NOCOUNT ON;
BEGIN TRY BEGIN TRANSACTION -- Check for existing rooms linked to this room type
IF NOT EXISTS (
    SELECT 1
    FROM Rooms
    WHERE RoomTypeID = @RoomTypeID
) BEGIN IF EXISTS (
    SELECT 1
    FROM RoomTypes
    WHERE RoomTypeID = @RoomTypeID
) BEGIN
DELETE FROM RoomTypes
WHERE RoomTypeID = @RoomTypeID
SET @StatusCode = 0 -- Success
SET @Message = 'Room type deleted successfully.'
END
ELSE BEGIN
SET @StatusCode = 2 -- Failure due to not found
SET @Message = 'Room type not found.'
END
END
ELSE BEGIN
SET @StatusCode = 1 -- Failure due to dependency
SET @Message = 'Cannot delete room type as it is being referenced by one or more rooms.'
END COMMIT TRANSACTION
END TRY BEGIN CATCH ROLLBACK TRANSACTION
SET @StatusCode = ERROR_NUMBER() -- SQL Server error number
SET @Message = ERROR_MESSAGE()
END CATCH
END
GO -- Get Room Type By Id
    CREATE PROCEDURE spGetRoomTypeById @RoomTypeID INT AS BEGIN
SET NOCOUNT ON;
SELECT RoomTypeID,
    TypeName,
    AccessibilityFeatures,
    Description,
    IsActive
FROM RoomTypes
WHERE RoomTypeID = @RoomTypeID
END
GO -- Get All Room Type
    CREATE PROCEDURE spGetAllRoomTypes @IsActive BIT = NULL -- Optional parameter to filter by IsActive status
    AS BEGIN
SET NOCOUNT ON;
-- Select users based on active status
IF @IsActive IS NULL BEGIN
SELECT RoomTypeID,
    TypeName,
    AccessibilityFeatures,
    Description,
    IsActive
FROM RoomTypes
END
ELSE BEGIN
SELECT RoomTypeID,
    TypeName,
    AccessibilityFeatures,
    Description,
    IsActive
FROM RoomTypes
WHERE IsActive = @IsActive;
END
END
GO -- Activate/Deactivate RoomType
    CREATE PROCEDURE spToggleRoomTypeActive @RoomTypeID INT,
    @IsActive BIT,
    @StatusCode INT OUTPUT,
    @Message NVARCHAR(255) OUTPUT AS BEGIN
SET NOCOUNT ON;
BEGIN TRY -- Check user existence
IF NOT EXISTS (
    SELECT 1
    FROM RoomTypes
    WHERE RoomTypeID = @RoomTypeID
) BEGIN
SET @StatusCode = 1 -- Failure due to not found
SET @Message = 'Room type not found.'
END -- Update IsActive status
BEGIN TRANSACTION
UPDATE RoomTypes
SET IsActive = @IsActive
WHERE RoomTypeID = @RoomTypeID;
SET @StatusCode = 0 -- Success
SET @Message = 'Room type activated/deactivated successfully.' COMMIT TRANSACTION
END TRY -- Handle exceptions
BEGIN CATCH ROLLBACK TRANSACTION
SET @StatusCode = ERROR_NUMBER() -- SQL Server error number
SET @Message = ERROR_MESSAGE()
END CATCH
END;
GO -- Stored procedure Room Management
    -- Create Room
    CREATE
    OR ALTER PROCEDURE spCreateRoom @RoomNumber NVARCHAR(10),
    @RoomTypeID INT,
    @Price DECIMAL(10, 2),
    @BedType NVARCHAR(50),
    @ViewType NVARCHAR(50),
    @Status NVARCHAR(50),
    @IsActive BIT,
    @CreatedBy NVARCHAR(100),
    @NewRoomID INT OUTPUT,
    @StatusCode INT OUTPUT,
    @Message NVARCHAR(255) OUTPUT AS BEGIN
SET NOCOUNT ON;
BEGIN TRY BEGIN TRANSACTION -- Check if the provided RoomTypeID exists in the RoomTypes table
IF EXISTS (
    SELECT 1
    FROM RoomTypes
    WHERE RoomTypeID = @RoomTypeID
) BEGIN -- Ensure the room number is unique
IF NOT EXISTS (
    SELECT 1
    FROM Rooms
    WHERE RoomNumber = @RoomNumber
) BEGIN
INSERT INTO Rooms (
        RoomNumber,
        RoomTypeID,
        Price,
        BedType,
        ViewType,
        Status,
        IsActive,
        CreatedBy,
        CreatedDate
    )
VALUES (
        @RoomNumber,
        @RoomTypeID,
        @Price,
        @BedType,
        @ViewType,
        @Status,
        @IsActive,
        @CreatedBy,
        GETDATE()
    )
SET @NewRoomID = SCOPE_IDENTITY()
SET @StatusCode = 0 -- Success
SET @Message = 'Room created successfully.'
END
ELSE BEGIN
SET @StatusCode = 1 -- Failure due to duplicate room number
SET @Message = 'Room number already exists.'
END
END
ELSE BEGIN
SET @StatusCode = 3 -- Failure due to invalid RoomTypeID
SET @Message = 'Invalid Room Type ID provided.'
END COMMIT TRANSACTION
END TRY BEGIN CATCH ROLLBACK TRANSACTION
SET @StatusCode = ERROR_NUMBER()
SET @Message = ERROR_MESSAGE()
END CATCH
END
GO -- Update Room
    CREATE
    OR ALTER PROCEDURE spUpdateRoom @RoomID INT,
    @RoomNumber NVARCHAR(10),
    @RoomTypeID INT,
    @Price DECIMAL(10, 2),
    @BedType NVARCHAR(50),
    @ViewType NVARCHAR(50),
    @Status NVARCHAR(50),
    @IsActive BIT,
    @ModifiedBy NVARCHAR(100),
    @StatusCode INT OUTPUT,
    @Message NVARCHAR(255) OUTPUT AS BEGIN
SET NOCOUNT ON;
BEGIN TRY BEGIN TRANSACTION -- Check if the RoomTypeID is valid and room number is unique for other rooms
IF EXISTS (
    SELECT 1
    FROM RoomTypes
    WHERE RoomTypeID = @RoomTypeID
)
AND NOT EXISTS (
    SELECT 1
    FROM Rooms
    WHERE RoomNumber = @RoomNumber
        AND RoomID <> @RoomID
) BEGIN -- Verify the room exists before updating
IF EXISTS (
    SELECT 1
    FROM Rooms
    WHERE RoomID = @RoomID
) BEGIN
UPDATE Rooms
SET RoomNumber = @RoomNumber,
    RoomTypeID = @RoomTypeID,
    Price = @Price,
    BedType = @BedType,
    ViewType = @ViewType,
    Status = @Status,
    IsActive = @IsActive,
    ModifiedBy = @ModifiedBy,
    ModifiedDate = GETDATE()
WHERE RoomID = @RoomID
SET @StatusCode = 0 -- Success
SET @Message = 'Room updated successfully.'
END
ELSE BEGIN
SET @StatusCode = 2 -- Failure due to room not found
SET @Message = 'Room not found.'
END
END
ELSE BEGIN
SET @StatusCode = 1 -- Failure due to invalid RoomTypeID or duplicate room number
SET @Message = 'Invalid Room Type ID or duplicate room number.'
END COMMIT TRANSACTION
END TRY BEGIN CATCH ROLLBACK TRANSACTION
SET @StatusCode = ERROR_NUMBER()
SET @Message = ERROR_MESSAGE()
END CATCH
END
GO -- Delete Room (Soft Delete)
    CREATE
    OR ALTER PROCEDURE spDeleteRoom @RoomID INT,
    @StatusCode INT OUTPUT,
    @Message NVARCHAR(255) OUTPUT AS BEGIN
SET NOCOUNT ON;
BEGIN TRY BEGIN TRANSACTION -- Ensure no active reservations exist for the room
IF NOT EXISTS (
    SELECT 1
    FROM Reservations
    WHERE RoomID = @RoomID
        AND Status NOT IN ('Checked-out', 'Cancelled')
) BEGIN -- Verify the room exists and is currently active before deactivating
IF EXISTS (
    SELECT 1
    FROM Rooms
    WHERE RoomID = @RoomID
        AND IsActive = 1
) BEGIN -- Instead of deleting, we update the IsActive flag to false
UPDATE Rooms
SET IsActive = 0 -- Set IsActive to false to indicate the room is no longer active
WHERE RoomID = @RoomID
SET @StatusCode = 0 -- Success
SET @Message = 'Room deactivated successfully.'
END
ELSE BEGIN
SET @StatusCode = 2 -- Failure due to room not found or already deactivated
SET @Message = 'Room not found or already deactivated.'
END
END
ELSE BEGIN
SET @StatusCode = 1 -- Failure due to active reservations
SET @Message = 'Room cannot be deactivated, there are active reservations.'
END COMMIT TRANSACTION
END TRY BEGIN CATCH ROLLBACK TRANSACTION
SET @StatusCode = ERROR_NUMBER()
SET @Message = ERROR_MESSAGE()
END CATCH
END
GO-- Get Room by Id
    CREATE
    OR ALTER PROCEDURE spGetRoomById @RoomID INT AS BEGIN
SELECT RoomID,
    RoomNumber,
    RoomTypeID,
    Price,
    BedType,
    ViewType,
    Status,
    IsActive
FROM Rooms
WHERE RoomID = @RoomID
END
GO -- Get All Rooms with Optional Filtering
    CREATE
    OR ALTER PROCEDURE spGetAllRoom @RoomTypeID INT = NULL,
    -- Optional filter by Room Type
    @Status NVARCHAR(50) = NULL -- Optional filter by Status
    AS BEGIN
SET NOCOUNT ON;
DECLARE @SQL NVARCHAR(MAX) -- Start building the dynamic SQL query
SET @SQL = 'SELECT RoomID, RoomNumber, RoomTypeID, Price, BedType, ViewType, Status, IsActive FROM Rooms WHERE 1=1' -- Append conditions based on the presence of optional parameters
    IF @RoomTypeID IS NOT NULL
SET @SQL = @SQL + ' AND RoomTypeID = @RoomTypeID' IF @Status IS NOT NULL
SET @SQL = @SQL + ' AND Status = @Status' -- Execute the dynamic SQL statement
    EXEC sp_executesql @SQL,
    N '@RoomTypeID INT, @Status NVARCHAR(50)',
    @RoomTypeID,
    @Status
END
GO -- Amenities procedure
    -- Description: Fetches amenities based on their active status.
    -- If @IsActive is provided, it returns amenities filtered by the active status.
    CREATE
    OR ALTER PROCEDURE spFetchAmenities @IsActive BIT = NULL,
    @Status BIT OUTPUT,
    @Message NVARCHAR(255) OUTPUT AS BEGIN
SET NOCOUNT ON;
BEGIN TRY -- Retrieve all amenities or filter by active status based on the input parameter.
IF @IsActive IS NULL
SELECT *
FROM Amenities;
ELSE
SELECT *
FROM Amenities
WHERE IsActive = @IsActive;
-- Return success status and message.
SET @Status = 1;
-- Success
SET @Message = 'Data retrieved successfully.';
END TRY BEGIN CATCH -- Handle errors and return failure status.
SET @Status = 0;
-- Failure
SET @Message = ERROR_MESSAGE();
END CATCH;
END;
GO -- Description: Fetches a specific amenity based on its ID.
    -- Returns the details of the amenity if it exists.
    CREATE
    OR ALTER PROCEDURE spFetchAmenityByID @AmenityID INT AS BEGIN
SET NOCOUNT ON;
SELECT AmenityID,
    Name,
    Description,
    IsActive
FROM Amenities
WHERE AmenityID = @AmenityID;
END;
GO -- Description: Inserts a new amenity into the Amenities table.
    -- Prevents duplicates based on the amenity name.
    CREATE
    OR ALTER PROCEDURE spAddAmenity @Name NVARCHAR(100),
    @Description NVARCHAR(255),
    @CreatedBy NVARCHAR(100),
    @AmenityID INT OUTPUT,
    @Status BIT OUTPUT,
    @Message NVARCHAR(255) OUTPUT AS BEGIN
SET NOCOUNT ON;
BEGIN TRY BEGIN TRANSACTION -- Check if an amenity with the same name already exists to avoid duplication.
IF EXISTS (
    SELECT 1
    FROM Amenities
    WHERE Name = @Name
) BEGIN
SET @Status = 0;
SET @Message = 'Amenity already exists.';
END
ELSE BEGIN -- Insert the new amenity record.
INSERT INTO Amenities (
        Name,
        Description,
        CreatedBy,
        CreatedDate,
        IsActive
    )
VALUES (@Name, @Description, @CreatedBy, GETDATE(), 1);
-- Retrieve the ID of the newly inserted amenity.
SET @AmenityID = SCOPE_IDENTITY();
SET @Status = 1;
SET @Message = 'Amenity added successfully.';
END COMMIT TRANSACTION;
END TRY BEGIN CATCH ROLLBACK TRANSACTION;
SET @Status = 0;
SET @Message = ERROR_MESSAGE();
END CATCH;
END;
GO -- Description: Updates an existing amenity's details in the Amenities table.
    -- Checks if the amenity exists before attempting an update.
    CREATE
    OR ALTER PROCEDURE spUpdateAmenity @AmenityID INT,
    @Name NVARCHAR(100),
    @Description NVARCHAR(255),
    @IsActive BIT,
    @ModifiedBy NVARCHAR(100),
    @Status BIT OUTPUT,
    @Message NVARCHAR(255) OUTPUT AS BEGIN
SET NOCOUNT ON;
BEGIN TRY BEGIN TRANSACTION -- Check if the amenity exists before updating.
IF NOT EXISTS (
    SELECT 1
    FROM Amenities
    WHERE AmenityID = @AmenityID
) BEGIN
SET @Status = 0;
SET @Message = 'Amenity does not exist.';
ROLLBACK TRANSACTION;
RETURN;
END -- Check for name uniqueness excluding the current amenity.
IF EXISTS (
    SELECT 1
    FROM Amenities
    WHERE Name = @Name
        AND AmenityID <> @AmenityID
) BEGIN
SET @Status = 0;
SET @Message = 'The name already exists for another amenity.';
ROLLBACK TRANSACTION;
RETURN;
END -- Update the amenity details.
UPDATE Amenities
SET Name = @Name,
    Description = @Description,
    IsActive = @IsActive,
    ModifiedBy = @ModifiedBy,
    ModifiedDate = GETDATE()
WHERE AmenityID = @AmenityID;
-- Check if the update was successful
IF @@ROWCOUNT = 0 BEGIN
SET @Status = 0;
SET @Message = 'No records updated.';
ROLLBACK TRANSACTION;
END
ELSE BEGIN
SET @Status = 1;
SET @Message = 'Amenity updated successfully.';
COMMIT TRANSACTION;
END
END TRY BEGIN CATCH -- Handle exceptions and roll back the transaction if an error occurs.
ROLLBACK TRANSACTION;
SET @Status = 0;
SET @Message = ERROR_MESSAGE();
END CATCH;
END;
GO -- Description: Soft deletes an amenity by setting its IsActive flag to 0.
    -- Checks if the amenity exists before marking it as inactive.
    CREATE
    OR ALTER PROCEDURE spDeleteAmenity @AmenityID INT,
    @Status BIT OUTPUT,
    @Message NVARCHAR(255) OUTPUT AS BEGIN
SET NOCOUNT ON;
BEGIN TRY BEGIN TRANSACTION -- Check if the amenity exists before attempting to delete.
IF NOT EXISTS (
    SELECT 1
    FROM Amenities
    WHERE AmenityID = @AmenityID
) BEGIN
SET @Status = 0;
SET @Message = 'Amenity does not exist.';
END
ELSE BEGIN -- Update the IsActive flag to 0 to soft delete the amenity.
UPDATE Amenities
SET IsActive = 0
WHERE AmenityID = @AmenityID;
SET @Status = 1;
SET @Message = 'Amenity deleted successfully.';
END COMMIT TRANSACTION;
END TRY BEGIN CATCH -- Roll back the transaction if an error occurs.
ROLLBACK TRANSACTION;
SET @Status = 0;
SET @Message = ERROR_MESSAGE();
END CATCH;
END;
GO -- Creating a User-Defined Table Type for Bulk Insert
    CREATE TYPE AmenityInsertType AS TABLE (
        Name NVARCHAR(100),
        Description NVARCHAR(255),
        CreatedBy NVARCHAR(100)
    );
GO -- Description: Performs a bulk insert of amenities into the Amenities table.
    -- Ensures that no duplicate names are inserted.
    CREATE
    OR ALTER PROCEDURE spBulkInsertAmenities @Amenities AmenityInsertType READONLY,
    @Status BIT OUTPUT,
    @Message NVARCHAR(255) OUTPUT AS BEGIN
SET NOCOUNT ON;
BEGIN TRY BEGIN TRANSACTION -- Check for duplicate names within the insert dataset.
IF EXISTS (
    SELECT 1
    FROM @Amenities
    GROUP BY Name
    HAVING COUNT(*) > 1
) BEGIN
SET @Status = 0;
SET @Message = 'Duplicate names found within the new data.';
ROLLBACK TRANSACTION;
RETURN;
END -- Check for existing names in the Amenities table that might conflict with the new data.
IF EXISTS (
    SELECT 1
    FROM @Amenities a
    WHERE EXISTS (
            SELECT 1
            FROM Amenities
            WHERE Name = a.Name
        )
) BEGIN
SET @Status = 0;
SET @Message = 'One or more names conflict with existing records.';
ROLLBACK TRANSACTION;
RETURN;
END -- Insert new amenities ensuring there are no duplicates by name.
INSERT INTO Amenities (
        Name,
        Description,
        CreatedBy,
        CreatedDate,
        IsActive
    )
SELECT Name,
    Description,
    CreatedBy,
    GETDATE(),
    1
FROM @Amenities;
-- Check if any records were actually inserted.
IF @@ROWCOUNT = 0 BEGIN
SET @Status = 0;
SET @Message = 'No records inserted. Please check the input data.';
ROLLBACK TRANSACTION;
END
ELSE BEGIN
SET @Status = 1;
SET @Message = 'Bulk insert completed successfully.';
COMMIT TRANSACTION;
END
END TRY BEGIN CATCH -- Handle any errors that occur during the transaction.
ROLLBACK TRANSACTION;
SET @Status = 0;
SET @Message = ERROR_MESSAGE();
END CATCH;
END;
GO -- Creating User-Defined Table Type for Bulk Update
    CREATE TYPE AmenityUpdateType AS TABLE (
        AmenityID INT,
        Name NVARCHAR(100),
        Description NVARCHAR(255),
        IsActive BIT
    );
GO -- Description: Updates multiple amenities in the Amenities table using a provided list.
    -- Applies updates to the Name, Description, and IsActive status.
    CREATE
    OR ALTER PROCEDURE spBulkUpdateAmenities @AmenityUpdates AmenityUpdateType READONLY,
    @Status BIT OUTPUT,
    @Message NVARCHAR(255) OUTPUT AS BEGIN
SET NOCOUNT ON;
BEGIN TRY BEGIN TRANSACTION -- Check for duplicate names within the update dataset.
IF EXISTS (
    SELECT 1
    FROM @AmenityUpdates u
    GROUP BY u.Name
    HAVING COUNT(*) > 1
) BEGIN
SET @Status = 0;
SET @Message = 'Duplicate names found within the update data.';
ROLLBACK TRANSACTION;
RETURN;
END -- Check for duplicate names in existing data.
IF EXISTS (
    SELECT 1
    FROM @AmenityUpdates u
        JOIN Amenities a ON u.Name = a.Name
        AND u.AmenityID != a.AmenityID
) BEGIN
SET @Status = 0;
SET @Message = 'One or more names conflict with existing records.';
ROLLBACK TRANSACTION;
RETURN;
END -- Update amenities based on the provided data.
UPDATE a
SET a.Name = u.Name,
    a.Description = u.Description,
    a.IsActive = u.IsActive
FROM Amenities a
    INNER JOIN @AmenityUpdates u ON a.AmenityID = u.AmenityID;
-- Check if any records were actually updated.
IF @@ROWCOUNT = 0 BEGIN
SET @Status = 0;
SET @Message = 'No records updated. Please check the input data.';
END
ELSE BEGIN
SET @Status = 1;
SET @Message = 'Bulk update completed successfully.';
END COMMIT TRANSACTION;
END TRY BEGIN CATCH -- Roll back the transaction and handle the error.
ROLLBACK TRANSACTION;
SET @Status = 0;
SET @Message = ERROR_MESSAGE();
END CATCH;
END;
GO -- Creating a User-Defined Table Type for Bulk Active and InActive
    CREATE TYPE AmenityStatusType AS TABLE (AmenityID INT, IsActive BIT);
GO -- Description: Updates the active status of multiple amenities in the Amenities table.
    -- Takes a list of amenity IDs and their new IsActive status.
    CREATE
    OR ALTER PROCEDURE spBulkUpdateAmenityStatus @AmenityStatuses AmenityStatusType READONLY,
    @Status BIT OUTPUT,
    @Message NVARCHAR(255) OUTPUT AS BEGIN
SET NOCOUNT ON;
BEGIN TRY BEGIN TRANSACTION -- Update the IsActive status for amenities based on the provided AmenityID.
UPDATE a
SET a.IsActive = s.IsActive
FROM Amenities a
    INNER JOIN @AmenityStatuses s ON a.AmenityID = s.AmenityID;
-- Check if any records were actually updated.
SET @Status = 1;
-- Success
SET @Message = 'Bulk status update completed successfully.';
COMMIT TRANSACTION;
END TRY BEGIN CATCH -- Roll back the transaction if an error occurs.
ROLLBACK TRANSACTION;
SET @Status = 0;
-- Failure
SET @Message = ERROR_MESSAGE();
END CATCH;
END;
GO