using System.Net;
using HotelBookingAPI.DTOs.AmenityDTOs;
using HotelBookingAPI.Models;
using HotelBookingAPI.Repository;
using Microsoft.AspNetCore.Mvc;

namespace HotelBookingAPI.Controllers
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
    }
}