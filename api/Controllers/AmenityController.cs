using System.Net;
using api.DTOs.AmenityDTOs;
using api.Models;
using api.Repository;
using Microsoft.AspNetCore.Mvc;

namespace api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AmenityController : ControllerBase
    {
        private readonly AmenityRepository _amenityRepository;
        private readonly ILogger<AmenityController> _logger;

        public AmenityController(AmenityRepository amenityRepository, ILogger<AmenityController> logger)
        {
            _amenityRepository = amenityRepository;
            _logger = logger;
        }

        [HttpGet("Fetch")]
        public async Task<APIResponse<AmenityFetchResultDTO>> FetchAmenities(bool? isActive = null)
        {
            try
            {
                var response = await _amenityRepository.FetchAmenitiesAsync(isActive);
                if (response.IsSuccess)
                {
                    return new APIResponse<AmenityFetchResultDTO>(response, "Retrieved all amenities");
                }

                return new APIResponse<AmenityFetchResultDTO>(HttpStatusCode.BadRequest, response.Message);
            }
            catch (Exception ex)
            {
                _logger.LogInformation(ex, "Error occurred while fetching amenities.");
                return new APIResponse<AmenityFetchResultDTO>(HttpStatusCode.InternalServerError, "An error occurred while processing your request.", ex.Message);
            }
        }

        [HttpGet("Fetch/{id}")]
        public async Task<APIResponse<AmenityDetailsDTO>> FetchAmenityById(int amenityId)
        {
            try
            {
                var response = await _amenityRepository.FetchAmenityByIdAsync(amenityId);
                if (response != null)
                {
                    return new APIResponse<AmenityDetailsDTO>(response, "Amenity Retreived Successfully");
                }

                return new APIResponse<AmenityDetailsDTO>(HttpStatusCode.NotFound, $"Amenity with Id ${amenityId}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occured while fetching amenity");
                return new APIResponse<AmenityDetailsDTO>(HttpStatusCode.InternalServerError, "An error occured while processing your request", ex.Message);
            }
        }

        [HttpPost("Add")]
        public async Task<APIResponse<AmenityInsertResponseDTO>> AddAmenity([FromBody] AmenityInsertDTO payload)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return new APIResponse<AmenityInsertResponseDTO>(HttpStatusCode.BadRequest, "Invalid Data in the Request Body");
                }
                var response = await _amenityRepository.AddAmenityAsync(payload);
                if (response.IsCreated)
                {
                    return new APIResponse<AmenityInsertResponseDTO>(response, response.Message);
                }
                return new APIResponse<AmenityInsertResponseDTO>(HttpStatusCode.BadRequest, response.Message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred while adding amenity");
                return new APIResponse<AmenityInsertResponseDTO>(HttpStatusCode.InternalServerError, "Amenity Creation Failed", ex.Message);
            }
        }

        [HttpPut("Update/{id}")]
        public async Task<APIResponse<AmenityUpdateResponseDTO>> UpdateAmenity(int id, [FromBody] AmenityUpdateDTO payload)
        {
            try
            {
                if (id != payload.AmenityID)
                {
                    _logger.LogInformation("Id didn't match");
                    return new APIResponse<AmenityUpdateResponseDTO>(HttpStatusCode.BadRequest, "Mismatched Amenity ID");
                }
                if (!ModelState.IsValid)
                {
                    return new APIResponse<AmenityUpdateResponseDTO>(HttpStatusCode.BadRequest, "Invalid Request Body");
                }

                var response = await _amenityRepository.UpdateAmenityAsync(payload);
                if (response.IsUpdated)
                {
                    return new APIResponse<AmenityUpdateResponseDTO>(response, response.Message);
                }

                return new APIResponse<AmenityUpdateResponseDTO>(HttpStatusCode.BadRequest, response.Message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred while updating amenity");
                return new APIResponse<AmenityUpdateResponseDTO>(HttpStatusCode.InternalServerError, "Error occurred while processing your request", ex.Message);
            }
        }

        [HttpDelete("Delete/{id}")]
        public async Task<APIResponse<AmenityDeleteResponseDTO>> DeleteAmenity(int id)
        {
            try
            {
                var amenity = await _amenityRepository.FetchAmenityByIdAsync(id);
                if(amenity == null){
                    return new APIResponse<AmenityDeleteResponseDTO>(HttpStatusCode.NotFound, $"Amenity with Id{id} is not found");
                }
                var response = await _amenityRepository.DeleteAmenityAsync(id);
                if(response.IsDeleted){
                    return new APIResponse<AmenityDeleteResponseDTO>(response, response.Message);
                }
                return new APIResponse<AmenityDeleteResponseDTO>(HttpStatusCode.BadRequest, response.Message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred while deleting amenity.");
                return new APIResponse<AmenityDeleteResponseDTO>(HttpStatusCode.InternalServerError, "Error occurred while trying to process your request", ex.Message);
            }
        }
    }
}