using System.Data;
using api.Connection;
using api.DTOs.AmenityDTOs;
using Microsoft.Data.SqlClient;

namespace api.Repository
{
    public class AmenityRepository
    {
        private readonly SqlConnectionFactory _connectionFactory;

        public AmenityRepository(SqlConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        // Fetch amenities
        public async Task<AmenityFetchResultDTO> FetchAmenitiesAsync(bool? isActive)
        {
            using var connection = _connectionFactory.CreateConnection();
            using var command = new SqlCommand("spFetcAmenities", connection);

            command.CommandType = CommandType.StoredProcedure;
            command.Parameters.AddWithValue("@IsActive", (object)isActive ?? DBNull.Value);

            var statusCode = new SqlParameter("@Status", SqlDbType.Int) { Direction = ParameterDirection.Output };
            var message = new SqlParameter("@Message", SqlDbType.NVarChar, 255) { Direction = ParameterDirection.Output };
            command.Parameters.Add(statusCode);
            command.Parameters.Add(message);

            await connection.OpenAsync();
            var amenities = new List<AmenityDetailsDTO>();

            using (SqlDataReader reader = await command.ExecuteReaderAsync())
            {
                while (await reader.ReadAsync())
                {
                    amenities.Add(new AmenityDetailsDTO
                    {
                        AmenityID = reader.GetInt32(reader.GetOrdinal("AmenityID")),
                        Name = reader.GetString(reader.GetOrdinal("Name")),
                        Description = reader.GetString(reader.GetOrdinal("Description")),
                        IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive"))
                    });
                }
            }

            return new AmenityFetchResultDTO
            {
                Amenities = amenities,
                IsSuccess = Convert.ToBoolean(statusCode.Value),
                Message = message.Value.ToString()
            };
        }

        // get single amenity by id
        public async Task<AmenityDetailsDTO> FetchAmenityByIdAsync(int amenityId)
        {
            using var connection = _connectionFactory.CreateConnection();
            using var command = new SqlCommand("spFetchAmenityByID", connection);
            command.CommandType = CommandType.StoredProcedure;
            command.Parameters.AddWithValue("@AmenityID", amenityId);
            await connection.OpenAsync();
            var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                return new AmenityDetailsDTO
                {
                    AmenityID = reader.GetInt32(reader.GetOrdinal("AmenityID")),
                    Name = reader.GetString(reader.GetOrdinal("Name")),
                    Description = reader.GetString(reader.GetOrdinal("Description")),
                    IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive"))
                };
            }
            else
            {
                return null;
            }
        }

        // Delete a single amenity 
        public async Task<AmenityDeleteResponseDTO> DeleteAmenityAsync(int amenityId)
        {
            using var connection = _connectionFactory.CreateConnection();
            using var command = new SqlCommand("spDeleteAmenity", connection);
            command.CommandType = CommandType.StoredProcedure;
            command.Parameters.AddWithValue("@AmenityID", amenityId);
            command.Parameters.Add("@Status", SqlDbType.Bit).Direction = ParameterDirection.Output;
            command.Parameters.Add("@Message", SqlDbType.NVarChar, 255).Direction = ParameterDirection.Output;
            await connection.OpenAsync();
            await command.ExecuteNonQueryAsync();
            return new AmenityDeleteResponseDTO
            {
                IsDeleted = Convert.ToBoolean(command.Parameters["@Status"].Value),
                Message = command.Parameters["@Message"].Value.ToString()
            };
        }

        // Add amenity
        public async Task<AmenityInsertResponseDTO> AddAmenityAsync(AmenityInsertDTO amenity)
        {
            AmenityInsertResponseDTO amenityInsertResponseDTO = new AmenityInsertResponseDTO();
            using var connection = _connectionFactory.CreateConnection();
            using var command = new SqlCommand("spAddAmenity", connection);
            command.CommandType = CommandType.StoredProcedure;
            command.Parameters.AddWithValue("@Name", amenity.Name);
            command.Parameters.AddWithValue("@Description", amenity.Description);
            command.Parameters.AddWithValue("@CreatedBy", "System");
            command.Parameters.Add("@AmenityID", SqlDbType.Int).Direction = ParameterDirection.Output;
            command.Parameters.Add("@Status", SqlDbType.Bit).Direction = ParameterDirection.Output;
            command.Parameters.Add("@Message", SqlDbType.NVarChar, 255).Direction = ParameterDirection.Output;

            try
            {
                await connection.OpenAsync();
                await command.ExecuteNonQueryAsync();

                // if the conversion results is true
                if (Convert.ToBoolean(command.Parameters["@Status"].Value))
                {
                    amenityInsertResponseDTO.Message = Convert.ToString(command.Parameters["@Message"].Value);
                    amenityInsertResponseDTO.IsCreated = true;
                    amenityInsertResponseDTO.AmenityID = Convert.ToInt32(command.Parameters["@AmenityID"].Value);
                }
                return amenityInsertResponseDTO;
            }
            catch (SqlException ex)
            {
                amenityInsertResponseDTO.Message = ex.Message;
                amenityInsertResponseDTO.IsCreated = false;

                return amenityInsertResponseDTO;
            }
        }

        // update amenity
        public async Task<AmenityUpdateResponseDTO> UpdateAmenityAsync(AmenityUpdateDTO amenity)
        {
            AmenityUpdateResponseDTO amenityUpdateResponseDTO = new AmenityUpdateResponseDTO()
            {
                AmenityID = amenity.AmenityID
            };
            using var connection = _connectionFactory.CreateConnection();
            using var command = new SqlCommand("spUpdateAmenity", connection);
            command.CommandType = CommandType.StoredProcedure;
            command.Parameters.AddWithValue("@AmenityID", amenity.AmenityID);
            command.Parameters.AddWithValue("@Name", amenity.Name);
            command.Parameters.AddWithValue("@Description", amenity.Description);
            command.Parameters.AddWithValue("@IsActive", amenity.IsActive);
            command.Parameters.AddWithValue("@ModifiedBy", "System");
            command.Parameters.Add("@Status", SqlDbType.Bit).Direction = ParameterDirection.Output;
            command.Parameters.Add("@Message", SqlDbType.NVarChar, 255).Direction = ParameterDirection.Output;
            try
            {
                await connection.OpenAsync();
                await command.ExecuteNonQueryAsync();
                amenityUpdateResponseDTO.Message = command.Parameters["@Message"].Value.ToString();
                amenityUpdateResponseDTO.IsUpdated = Convert.ToBoolean(command.Parameters["@Status"].Value);
                return amenityUpdateResponseDTO;
            }
            catch (SqlException ex)
            {
                amenityUpdateResponseDTO.Message = ex.Message;
                amenityUpdateResponseDTO.IsUpdated = false;
                return amenityUpdateResponseDTO;
            }
        }

        public async Task<AmenityBulkOperationResultDTO> BulkInsertAmenitiesAsync(List<AmenityInsertDTO> amenities)
        {
            using var connection = _connectionFactory.CreateConnection();
            using var command = new SqlCommand("spBulkInsertAmenities", connection);
            command.CommandType = CommandType.StoredProcedure;
            var amenitiesTable = new DataTable();
            amenitiesTable.Columns.Add("Name", typeof(string));
            amenitiesTable.Columns.Add("Description", typeof(string));
            amenitiesTable.Columns.Add("CreatedBy", typeof(string));
            foreach (var amenity in amenities)
            {
                amenitiesTable.Rows.Add(amenity.Name, amenity.Description, "System");
            }
            var param = command.Parameters.AddWithValue("@Amenities", amenitiesTable);
            param.SqlDbType = SqlDbType.Structured;
            command.Parameters.Add("@Status", SqlDbType.Bit).Direction = ParameterDirection.Output;
            command.Parameters.Add("@Message", SqlDbType.NVarChar, 255).Direction = ParameterDirection.Output;
            await connection.OpenAsync();
            await command.ExecuteNonQueryAsync();
            return new AmenityBulkOperationResultDTO
            {
                IsSuccess = Convert.ToBoolean(command.Parameters["@Status"].Value),
                Message = command.Parameters["@Message"].Value.ToString()
            };
        }
    }
}