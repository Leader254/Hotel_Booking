using System.Net;
using api.DTOs.RoomTypeDTOs;
using api.Models;
using api.Repository;
using Microsoft.AspNetCore.Mvc;

namespace api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RoomTypeController : ControllerBase
    {
        private readonly ILogger<RoomTypeController> _logger;
        private readonly RoomTypeRepository _roomTypeRepository;

        public RoomTypeController(ILogger<RoomTypeController> logger, RoomTypeRepository roomTypeRepository)
        {
            _roomTypeRepository = roomTypeRepository;
            _logger = logger;
        }

        [HttpGet("AllRoomTypes")]
        public async Task<APIResponse<List<RoomTypeDTO>>> GetAllRoomTypes(bool? IsActive = null)
        {
            _logger.LogInformation($"Request received for GetAllRoomTypes, IsActive: {IsActive}");
            try
            {
                var rooms = await _roomTypeRepository.RetrieveAllRoomTypesAsync(IsActive);
                return new APIResponse<List<RoomTypeDTO>>(rooms, "Retrived all room Types");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching room types");
                return new APIResponse<List<RoomTypeDTO>>(HttpStatusCode.InternalServerError, "Internal Server Error: " + ex.Message);
            }
        }

        [HttpGet("GetRoomType/{RoomTypeId}")]
        public async Task<APIResponse<RoomTypeDTO>> GetSingleRoomTypeById(int RoomTypeId)
        {
            _logger.LogInformation($"Request received for get single room type: {RoomTypeId}");

            try
            {
                var room = await _roomTypeRepository.RetrieveRoomTypeByIdAsync(RoomTypeId);
                if (room == null)
                {
                    return new APIResponse<RoomTypeDTO>(HttpStatusCode.NotFound, "Room Not Found");
                }
                return new APIResponse<RoomTypeDTO>(room, "Room fetched Successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching room");
                return new APIResponse<RoomTypeDTO>(HttpStatusCode.BadRequest, "Error fetching room type", ex.Message);
            }
        }

        [HttpPost("AddRoomType")]
        public async Task<APIResponse<CreateRoomTypeResponseDTO>> CreateRoomType([FromBody] CreateRoomTypeDTO payload)
        {
            _logger.LogInformation("Request received for creating a room type");
            if (!ModelState.IsValid)
            {
                _logger.LogInformation("Invalid Data in the request body");
                return new APIResponse<CreateRoomTypeResponseDTO>(HttpStatusCode.BadRequest, "Invalid Data in the request body");
            }
            try
            {
                var response = await _roomTypeRepository.CreateRoomType(payload);
                _logger.LogInformation("CreateRoomType Response From Repository: {@CreateRoomTypeResponseDTO}", response);

                if (response.IsCreated)
                {
                    return new APIResponse<CreateRoomTypeResponseDTO>(response, response.Message);
                }
                return new APIResponse<CreateRoomTypeResponseDTO>(HttpStatusCode.BadRequest, response.Message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error adding new room Type with Name {TypeName}", payload.TypeName);
                return new APIResponse<CreateRoomTypeResponseDTO>(HttpStatusCode.InternalServerError, "Room Type Creation failed", ex.Message);
            }
        }

        [HttpPut("Update/{RoomTypeId}")]
        public async Task<APIResponse<UpdateRoomTypeResponseDTO>> UpdateRoomType(int RoomTypeId, [FromBody] UpdateRoomTypeDTO request)
        {
            _logger.LogInformation("Request Received for UpdateRoomType {@UpdateRoomTypeDTO}", request);
            if (!ModelState.IsValid)
            {
                _logger.LogInformation("UpdateRoomType Invalid Request Body");
                return new APIResponse<UpdateRoomTypeResponseDTO>(HttpStatusCode.BadRequest, "Invalid Request Body");
            }
            if (RoomTypeId != request.RoomTypeID)
            {
                _logger.LogInformation("UpdateRoomType Mismatched Room Type ID");
                return new APIResponse<UpdateRoomTypeResponseDTO>(HttpStatusCode.BadRequest, "Mismatched Room Type ID.");
            }
            try
            {
                var response = await _roomTypeRepository.UpdateRoomType(request);
                if (response.IsUpdated)
                {
                    return new APIResponse<UpdateRoomTypeResponseDTO>(response, response.Message);
                }
                return new APIResponse<UpdateRoomTypeResponseDTO>(HttpStatusCode.BadRequest, response.Message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error Updating Room Type {RoomTypeId}", RoomTypeId);
                return new APIResponse<UpdateRoomTypeResponseDTO>(HttpStatusCode.InternalServerError, "Update Room Type Failed.", ex.Message);
            }
        }
        [HttpDelete("Delete/{RoomTypeId}")]
        public async Task<APIResponse<DeleteRoomTypeResponseDTO>> DeleteRoomType(int RoomTypeId)
        {
            _logger.LogInformation($"Request Received for DeleteRoomType, RoomTypeId: {RoomTypeId}");
            try
            {
                var roomType = await _roomTypeRepository.RetrieveRoomTypeByIdAsync(RoomTypeId);
                if (roomType == null)
                {
                    return new APIResponse<DeleteRoomTypeResponseDTO>(HttpStatusCode.NotFound, "RoomType not found.");
                }
                var response = await _roomTypeRepository.DeleteRoomType(RoomTypeId);
                if (response.IsDeleted)
                {
                    return new APIResponse<DeleteRoomTypeResponseDTO>(response, response.Message);
                }
                return new APIResponse<DeleteRoomTypeResponseDTO>(HttpStatusCode.BadRequest, response.Message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting RoomType {RoomTypeId}", RoomTypeId);
                return new APIResponse<DeleteRoomTypeResponseDTO>(HttpStatusCode.InternalServerError, "Internal server error: " + ex.Message);
            }
        }
        [HttpPost("ActiveInActive")]
        public async Task<IActionResult> ToggleActive(int RoomTypeId, bool IsActive)
        {
            try
            {
                var result = await _roomTypeRepository.ToggleRoomTypeActiveAsync(RoomTypeId, IsActive);
                if (result.Success)
                    return Ok(new { Message = "RoomType activation status updated successfully." });
                else
                    return BadRequest(new { Message = result.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error toggling active status for RoomTypeId {RoomTypeId}", RoomTypeId);
                return StatusCode(500, "An error occurred while processing your request.");
            }
        }
    }
}