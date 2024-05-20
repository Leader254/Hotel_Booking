using System.Data;
using HotelBookingAPI.Connection;
using HotelBookingAPI.DTOs.RoomDTOs;
using Microsoft.Data.SqlClient;

namespace HotelBookingAPI.Repository
{
    public class RoomRepository
    {
        private readonly SqlConnectionFactory _sqlConnectionFactory;
        public RoomRepository(SqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<CreateRoomResponseDTO> CreateRoomAsync(CreateRoomRequestDTO payload)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();
            using var command = new SqlCommand("spCreateRoom", connection)
            {
                CommandType = CommandType.StoredProcedure
            };
            command.Parameters.AddWithValue("@RoomNumber", payload.RoomNumber);
            command.Parameters.AddWithValue("@RoomTypeID", payload.RoomTypeID);
            command.Parameters.AddWithValue("@Price", payload.Price);
            command.Parameters.AddWithValue("@BedType", payload.BedType);
            command.Parameters.AddWithValue("@ViewType", payload.ViewType);
            command.Parameters.AddWithValue("@Status", payload.Status);
            command.Parameters.AddWithValue("@IsActive", payload.IsActive);
            command.Parameters.AddWithValue("@CreatedBy", "System");
            command.Parameters.Add("@NewRoomID", SqlDbType.Int).Direction = ParameterDirection.Output;
            command.Parameters.Add("@StatusCode", SqlDbType.Int).Direction = ParameterDirection.Output;
            command.Parameters.Add("@Message", SqlDbType.NVarChar, 255).Direction = ParameterDirection.Output;

            try
            {
                await connection.OpenAsync();
                await command.ExecuteNonQueryAsync();

                var outputRoomID = command.Parameters["@NewRoomID"].Value;
                var newRoomID = outputRoomID != DBNull.Value ? Convert.ToInt32(outputRoomID) : 0;

                return new CreateRoomResponseDTO
                {
                    RoomID = newRoomID,
                    IsCreated = (int)command.Parameters["@StatusCode"].Value == 0,
                    Message = (string)command.Parameters["@Message"].Value
                };
            }
            catch (Exception ex)
            {
                throw new Exception($"Error creating room: {ex.Message}", ex);
            }
        }

        public async Task<UpdateRoomResponseDTO> UpdateRoomAsync(UpdateRoomRequestDTO payload)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();
            using var command = new SqlCommand("spUpdateRoom", connection)
            {
                CommandType = CommandType.StoredProcedure
            };
            command.Parameters.AddWithValue("@RoomID", payload.RoomID);
            command.Parameters.AddWithValue("@RoomNumber", payload.RoomNumber);
            command.Parameters.AddWithValue("@RoomTypeID", payload.RoomTypeID);
            command.Parameters.AddWithValue("@Price", payload.Price);
            command.Parameters.AddWithValue("@BedType", payload.BedType);
            command.Parameters.AddWithValue("@ViewType", payload.ViewType);
            command.Parameters.AddWithValue("@Status", payload.Status);
            command.Parameters.AddWithValue("@IsActive", payload.IsActive);
            command.Parameters.AddWithValue("@ModifiedBy", "System");
            command.Parameters.Add("@StatusCode", SqlDbType.Int).Direction = ParameterDirection.Output;
            command.Parameters.Add("@Message", SqlDbType.NVarChar, 255).Direction = ParameterDirection.Output;

            try
            {
                await connection.OpenAsync();
                await command.ExecuteNonQueryAsync();

                return new UpdateRoomResponseDTO{
                    RoomID = payload.RoomID,
                    IsUpdated = (int)command.Parameters["@StatusCode"].Value == 0,
                    Message = (string)command.Parameters["@Message"].Value
                };
            }
            catch (Exception ex)
            {
               throw new Exception($"Error updating room: {ex.Message}"); 
            }
        }
    }
}