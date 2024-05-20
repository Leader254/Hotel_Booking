using HotelBookingAPI.Connection;
using HotelBookingAPI.DTOs.RoomTypeDTOs;
using Microsoft.Data.SqlClient;
using System.Data;

namespace HotelBookingAPI.Repository
{
    public class RoomTypeRepository
    {
        private readonly SqlConnectionFactory _sqlConnectionFactory;

        public RoomTypeRepository(SqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }
        public async Task<List<RoomTypeDTO>> RetrieveAllRoomTypesAsync(bool? IsActive)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();
            var command = new SqlCommand("spGetAllRoomTypes", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.AddWithValue("@IsActive", (object)IsActive ?? DBNull.Value);
            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();

            var roomTypes = new List<RoomTypeDTO>();
            while (reader.Read())
            {
                roomTypes.Add(new RoomTypeDTO
                {
                    RoomTypeID = reader.GetInt32("RoomTypeID"),
                    TypeName = reader.GetString("TypeName"),
                    AccessibilityFeatures = reader.GetString("AccessibilityFeatures"),
                    Description = reader.GetString("Description"),
                    IsActive = reader.GetBoolean("IsActive")
                });
            }
            return roomTypes;
        }
        public async Task<RoomTypeDTO> RetrieveRoomTypeByIdAsync(int RoomTypeId)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();
            var command = new SqlCommand("spGetRoomTypeById", connection)
            {
                CommandType = CommandType.StoredProcedure
            };
            command.Parameters.AddWithValue("@RoomTypeID", RoomTypeId);
            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();

            if (!reader.Read())
            {
                return null;
            }

            var roomType = new RoomTypeDTO
            {
                RoomTypeID = RoomTypeId,
                TypeName = reader.GetString("TypeName"),
                AccessibilityFeatures = reader.GetString("AccessibilityFeatures"),
                Description = reader.GetString("Description"),
                IsActive = reader.GetBoolean("IsActive")
            };

            return roomType;
        }

        public async Task<CreateRoomTypeResponseDTO> CreateRoomType(CreateRoomTypeDTO payload)
        {
            CreateRoomTypeResponseDTO response = new CreateRoomTypeResponseDTO();

            using var connection = _sqlConnectionFactory.CreateConnection();
            var command = new SqlCommand("spCreateRoomType", connection)
            {
                CommandType = CommandType.StoredProcedure
            };
            command.Parameters.Add(new SqlParameter("@TypeName", payload.TypeName));
            command.Parameters.Add(new SqlParameter("@AccessibilityFeatures", payload.AccessibilityFeatures));
            command.Parameters.Add(new SqlParameter("@Description", payload.Description));
            command.Parameters.Add(new SqlParameter("@CreatedBy", "System"));

            var outputId = new SqlParameter("@NewRoomTypeID", SqlDbType.Int)
            {
                Direction = ParameterDirection.Output
            };

            var statusCode = new SqlParameter("@StatusCode", SqlDbType.Int)
            {
                Direction = ParameterDirection.Output
            };

            var message = new SqlParameter("@Message", SqlDbType.NVarChar, 255)
            {
                Direction = ParameterDirection.Output
            };
            command.Parameters.Add(outputId);
            command.Parameters.Add(statusCode);
            command.Parameters.Add(message);

            try
            {
                await connection.OpenAsync();
                await command.ExecuteNonQueryAsync();

                if ((int)statusCode.Value == 0)
                {
                    response.Message = message.Value.ToString();
                    response.IsCreated = true;
                    response.RoomTypeId = (int)outputId.Value;

                    return response;
                }

                response.Message = message.Value.ToString();
                response.IsCreated = false;
                return response;
            }
            catch (SqlException ex)
            {
                response.Message = ex.Message;
                response.IsCreated = false;

                return response;
            }
        }

        public async Task<UpdateRoomTypeResponseDTO> UpdateRoomType(UpdateRoomTypeDTO payload)
        {
            var response = new UpdateRoomTypeResponseDTO()
            {
                RoomTypeID = payload.RoomTypeID
            };

            using var connection = _sqlConnectionFactory.CreateConnection();
            var command = new SqlCommand("spUpdateRoomType", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@RoomTypeID", payload.RoomTypeID));
            command.Parameters.Add(new SqlParameter("@TypeName", payload.TypeName));
            command.Parameters.Add(new SqlParameter("@AccessibilityFeatures", payload.AccessibilityFeatures));
            command.Parameters.Add(new SqlParameter("@Description", payload.Description));
            command.Parameters.Add(new SqlParameter("@ModifiedBy", "System"));

            var statusCode = new SqlParameter("StatusCode", SqlDbType.Int)
            {
                Direction = ParameterDirection.Output
            };
            var message = new SqlParameter("@Message", SqlDbType.NVarChar, 255)
            {
                Direction = ParameterDirection.Output
            };
            command.Parameters.Add(message);
            command.Parameters.Add(statusCode);

            try
            {
                await connection.OpenAsync();
                await command.ExecuteNonQueryAsync();
                response.Message = message.Value.ToString();
                response.IsUpdated = (int)statusCode.Value == 0;

                return response;
            }
            catch (SqlException ex)
            {
                response.Message = ex.Message;
                response.IsUpdated = false;

                return response;
            }
        }

        public async Task<DeleteRoomTypeResponseDTO> DeleteRoomType(int RoomTypeID)
        {
            DeleteRoomTypeResponseDTO deleteRoomTypeResponseDTO = new DeleteRoomTypeResponseDTO();
            using var connection = _sqlConnectionFactory.CreateConnection();
            //If you want to Delete the Record Permanentlt, then use spDeleteRoomType Stored Procedure
            var command = new SqlCommand("spToggleRoomTypeActive", connection)
            {
                CommandType = CommandType.StoredProcedure
            };
            command.Parameters.Add(new SqlParameter("@RoomTypeID", RoomTypeID));
            command.Parameters.AddWithValue("@IsActive", false);
            var statusCode = new SqlParameter("@StatusCode", SqlDbType.Int)
            {
                Direction = ParameterDirection.Output
            };
            var message = new SqlParameter("@Message", SqlDbType.NVarChar, 255)
            {
                Direction = ParameterDirection.Output
            };
            command.Parameters.Add(statusCode);
            command.Parameters.Add(message);
            try
            {
                await connection.OpenAsync();
                await command.ExecuteNonQueryAsync();
                deleteRoomTypeResponseDTO.Message = "Room Type Deleted Successfully";
                deleteRoomTypeResponseDTO.IsDeleted = (int)statusCode.Value == 0;
                return deleteRoomTypeResponseDTO;
            }
            catch (SqlException ex)
            {
                deleteRoomTypeResponseDTO.Message = ex.Message;
                deleteRoomTypeResponseDTO.IsDeleted = false;
                return deleteRoomTypeResponseDTO;
            }
        }

        public async Task<(bool Success, string Message)> ToggleRoomTypeActiveAsync(int RoomTypeID, bool IsActive)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();
            using var command = new SqlCommand("spToggleRoomTypeActive", connection)
            {
                CommandType = CommandType.StoredProcedure
            };
            command.Parameters.Add(new SqlParameter("@RoomTypeID", RoomTypeID));
            command.Parameters.AddWithValue("@IsActive", IsActive);
            var statusCode = new SqlParameter("@StatusCode", SqlDbType.Int)
            {
                Direction = ParameterDirection.Output
            };
            var message = new SqlParameter("@Message", SqlDbType.NVarChar, 255)
            {
                Direction = ParameterDirection.Output
            };
            command.Parameters.Add(statusCode);
            command.Parameters.Add(message);
            await connection.OpenAsync();
            await command.ExecuteNonQueryAsync();
            var ResponseMessage = message.Value.ToString();
            var success = (int)statusCode.Value == 0;
            return (success, ResponseMessage);
        }
    }
}
