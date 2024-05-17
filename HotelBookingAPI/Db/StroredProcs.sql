-- User stored procedure
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

-- Create Stored Procedures for Room Types and Rooms
-- Create Room Type
CREATE PROCEDURE spCreateRoomType
    @TypeName NVARCHAR(50),
    @AccessibilityFeatures NVARCHAR(255),
    @Description NVARCHAR(255),
    @CreatedBy NVARCHAR(100),
    @NewRoomTypeID INT OUTPUT,
    @StatusCode INT OUTPUT,
    @Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION
            IF NOT EXISTS (SELECT 1 FROM RoomTypes WHERE TypeName = @TypeName)
            BEGIN
                INSERT INTO RoomTypes (TypeName, AccessibilityFeatures, Description, CreatedBy, CreatedDate)
                VALUES (@TypeName, @AccessibilityFeatures, @Description, @CreatedBy, GETDATE())

                SET @NewRoomTypeID = SCOPE_IDENTITY()
                SET @StatusCode = 0 -- Success
                SET @Message = 'Room type created successfully.'
            END
            ELSE
            BEGIN
                SET @StatusCode = 1 -- Failure due to duplicate name
                SET @Message = 'Room type name already exists.'
            END
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        SET @StatusCode = ERROR_NUMBER() -- SQL Server error number
        SET @Message = ERROR_MESSAGE()
    END CATCH
END
GO

-- Update Room Type
CREATE PROCEDURE spUpdateRoomType
    @RoomTypeID INT,
    @TypeName NVARCHAR(50),
    @AccessibilityFeatures NVARCHAR(255),
    @Description NVARCHAR(255),
    @ModifiedBy NVARCHAR(100),
    @StatusCode INT OUTPUT,
    @Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION
            -- Check if the updated type name already exists in another record
            IF NOT EXISTS (SELECT 1 FROM RoomTypes WHERE TypeName = @TypeName AND RoomTypeID <> @RoomTypeID)
            BEGIN
                IF EXISTS (SELECT 1 FROM RoomTypes WHERE RoomTypeID = @RoomTypeID)
                BEGIN
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
                ELSE
                BEGIN
                    SET @StatusCode = 2 -- Failure due to not found
                    SET @Message = 'Room type not found.'
                END
            END
            ELSE
            BEGIN
                SET @StatusCode = 1 -- Failure due to duplicate name
                SET @Message = 'Another room type with the same name already exists.'
            END
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        SET @StatusCode = ERROR_NUMBER() -- SQL Server error number
        SET @Message = ERROR_MESSAGE()
    END CATCH
END
GO

-- Delete Room Type By Id
CREATE PROCEDURE spDeleteRoomType
    @RoomTypeID INT,
    @StatusCode INT OUTPUT,
    @Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION
   
            -- Check for existing rooms linked to this room type
            IF NOT EXISTS (SELECT 1 FROM Rooms WHERE RoomTypeID = @RoomTypeID)
            BEGIN
                IF EXISTS (SELECT 1 FROM RoomTypes WHERE RoomTypeID = @RoomTypeID)
                BEGIN
                    DELETE FROM RoomTypes WHERE RoomTypeID = @RoomTypeID
                    SET @StatusCode = 0 -- Success
                    SET @Message = 'Room type deleted successfully.'
                END
                ELSE
                BEGIN
                    SET @StatusCode = 2 -- Failure due to not found
                    SET @Message = 'Room type not found.'
                END
            END
            ELSE
            BEGIN
                SET @StatusCode = 1 -- Failure due to dependency
                SET @Message = 'Cannot delete room type as it is being referenced by one or more rooms.'
            END
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        SET @StatusCode = ERROR_NUMBER() -- SQL Server error number
        SET @Message = ERROR_MESSAGE()
    END CATCH
END
GO

-- Get Room Type By Id
CREATE PROCEDURE spGetRoomTypeById
    @RoomTypeID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT RoomTypeID, TypeName, AccessibilityFeatures, Description, IsActive FROM RoomTypes WHERE RoomTypeID = @RoomTypeID
END
GO

-- Get All Room Type
CREATE PROCEDURE spGetAllRoomTypes
 @IsActive BIT = NULL  -- Optional parameter to filter by IsActive status
AS
BEGIN
    SET NOCOUNT ON;
    -- Select users based on active status
    IF @IsActive IS NULL
    BEGIN
        SELECT RoomTypeID, TypeName, AccessibilityFeatures, Description, IsActive FROM RoomTypes
    END
    ELSE
    BEGIN
        SELECT RoomTypeID, TypeName, AccessibilityFeatures, Description, IsActive FROM RoomTypes WHERE IsActive = @IsActive;
    END
END
GO

-- Activate/Deactivate RoomType
CREATE PROCEDURE spToggleRoomTypeActive
    @RoomTypeID INT,
    @IsActive BIT,
    @StatusCode INT OUTPUT,
    @Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Check user existence
        IF NOT EXISTS (SELECT 1 FROM RoomTypes WHERE RoomTypeID = @RoomTypeID)
        BEGIN
             SET @StatusCode = 1 -- Failure due to not found
             SET @Message = 'Room type not found.'
        END

        -- Update IsActive status
        BEGIN TRANSACTION
             UPDATE RoomTypes SET IsActive = @IsActive WHERE RoomTypeID = @RoomTypeID;
                SET @StatusCode = 0 -- Success
             SET @Message = 'Room type activated/deactivated successfully.'
        COMMIT TRANSACTION

    END TRY
    -- Handle exceptions
    BEGIN CATCH
        ROLLBACK TRANSACTION
        SET @StatusCode = ERROR_NUMBER() -- SQL Server error number
        SET @Message = ERROR_MESSAGE()
    END CATCH
END;
GO