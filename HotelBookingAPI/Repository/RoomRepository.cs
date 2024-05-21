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
               throw new Exception($"Error updating room: {ex.Message}", ex); 
            }
        }

        public async Task<DeleteRoomResponseDTO> DeleteRoomAsync(int roomId)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();
            using var command = new SqlCommand("spDelete", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.AddWithValue("@RoomID", roomId);
            command.Parameters.Add("@StatusCode", SqlDbType.Int).Direction = ParameterDirection.Output;
            command.Parameters.Add("Message", SqlDbType.NVarChar).Direction = ParameterDirection.Output;

            try
            {
                await connection.OpenAsync();
                await command.ExecuteNonQueryAsync();

                return new DeleteRoomResponseDTO
                {
                    IsDeleted = (int)command.Parameters["@StatusCode"].Value == 0,
                    Message = (string)command.Parameters["@Message"].Value
                };
            }
            catch (Exception ex)
            {
                throw new Exception($"Error deleting room: {ex.Message}", ex);
            }
        }

        public async Task<RoomDetailsResponseDTO> GetSingleRoomAsync(int roomId){
            using var connection = _sqlConnectionFactory.CreateConnection();
            using var command = new SqlCommand("spGetRoomById", connection)
            {
                CommandType = CommandType.StoredProcedure
            };
            command.Parameters.AddWithValue("@RoomID", roomId);

            try
            {
                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();
                if (await reader.ReadAsync()){
                    return new RoomDetailsResponseDTO
                    {
                        RoomID = reader.GetInt32("RoomID"),
                        RoomNumber = reader.GetString("RoomNumber"),
                        RoomTypeID = reader.GetInt32("RoomTypeID"),
                        Price = reader.GetDecimal("Price"),
                        BedType = reader.GetString("BedType"),
                        ViewType = reader.GetString("ViewType"),
                        Status = reader.GetString("Status"),
                        IsActive = reader.GetBoolean("IsActive")
                    };
                }
                else {
                    return null;
                }
            }
            catch (Exception ex)
            {
                throw new Exception($"Error retrieving room by ID: {ex.Message}", ex);
            }
        }
        public async Task<List<RoomDetailsResponseDTO>> GetAllRoomsAsync(GetAllRoomsRequestDTO payload)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();
            using var command = new SqlCommand("spGetAllRoom", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@RoomTypeID", SqlDbType.Int)
            {
                Value = payload.RoomTypeID.HasValue ? payload.RoomTypeID.ToString() : DBNull.Value
            });

            command.Parameters.Add(new SqlParameter("@Status", SqlDbType.NVarChar, 50)
            {
                Value = string.IsNullOrEmpty(payload.Status) ? DBNull.Value : payload.Status
            });

            try
            {
                await connection.OpenAsync();
                var rooms = new List<RoomDetailsResponseDTO>();
                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    rooms.Add(new RoomDetailsResponseDTO
                    {
                        RoomID = reader.GetInt32("RoomID"),
                        RoomNumber = reader.GetString("RoomNumber"),
                        RoomTypeID = reader.GetInt32("RoomTypeID"),
                        Price = reader.GetDecimal("Price"),
                        BedType = reader.GetString("BedType"),
                        ViewType = reader.GetString("ViewType"),
                        Status = reader.GetString("Status"),
                        IsActive = reader.GetBoolean("IsActive")
                    });
                }
                return rooms;
            }
            catch (Exception ex)
            {
                throw new Exception($"Error retrieving all rooms: {ex.Message}", ex);
            }
        }
    }
}