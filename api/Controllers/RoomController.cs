using System.Net;
using api.DTOs.RoomDTOs;
using api.Models;
using api.Repository;
using Microsoft.AspNetCore.Mvc;

namespace api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RoomController : ControllerBase
    {
        private readonly RoomRepository _roomRepository;
        private readonly ILogger<RoomController> _logger;

        public RoomController(RoomRepository roomRepository, ILogger<RoomController> logger)
        {
            _roomRepository = roomRepository;
            _logger = logger;
        }

        [HttpGet("All")]
        public async Task<APIResponse<List<RoomDetailsResponseDTO>>> GetAllRooms([FromQuery] GetAllRoomsRequestDTO payload)
        {
            _logger.LogInformation("Request Received for CreateRoom: {@GetAllRoomsRequestDTO}", payload);
            if (!ModelState.IsValid)
            {
                _logger.LogInformation("Invalid Data in the Request Body");
                return new APIResponse<List<RoomDetailsResponseDTO>>(HttpStatusCode.BadRequest, "Invalid Data in the Query String");
            }

            try
            {
                var rooms = await _roomRepository.GetAllRoomsAsync(payload);
                return new APIResponse<List<RoomDetailsResponseDTO>>(rooms, "Retrieved all Rooms");
            }
            catch (Exception ex)
            {
                _logger.LogInformation(ex, "Error getting rooms");
                return new APIResponse<List<RoomDetailsResponseDTO>>(HttpStatusCode.InternalServerError, "Internal Server error: " + ex.Message);
            }
        }
        [HttpGet("{id}")]
        public async Task<APIResponse<RoomDetailsResponseDTO>> GetRoomByIdAsync(int id)
        {
            _logger.LogInformation($"Request Received for GetRoomById, id: {id}");
            try
            {
                var response = await _roomRepository.GetSingleRoomAsync(id);
                if (response == null)
                {
                    return new APIResponse<RoomDetailsResponseDTO>(HttpStatusCode.NotFound, "Room Id not found");
                }
                return new APIResponse<RoomDetailsResponseDTO>(response, "Room fetched successfully.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting room by id {id}", id);
                return new APIResponse<RoomDetailsResponseDTO>(HttpStatusCode.InternalServerError, "Internal Server Error", ex.Message);
            }
        }
        [HttpPost("Create")]
        public async Task<APIResponse<CreateRoomResponseDTO>> CreateRoom([FromBody] CreateRoomRequestDTO payload)
        {
            _logger.LogInformation("Request Received for CreateRoom: {@CreateRoomRequestDTO}", payload);
            if (!ModelState.IsValid)
            {
                _logger.LogInformation("Invalid Data in the Request Body");
                return new APIResponse<CreateRoomResponseDTO>(HttpStatusCode.BadRequest, "Invalid Data in the Request Body");
            }

            try
            {
                var response = await _roomRepository.CreateRoomAsync(payload);
                _logger.LogInformation("CreateRoom Response From Repository: {@CreateRoomResponseDTO}", response);
                if (response.IsCreated)
                {
                    return new APIResponse<CreateRoomResponseDTO>(response, response.Message);
                }
                return new APIResponse<CreateRoomResponseDTO>(HttpStatusCode.BadRequest, response.Message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error adding new Room");
                return new APIResponse<CreateRoomResponseDTO>(HttpStatusCode.InternalServerError, "Room Creation Failed.", ex.Message);
            }
        }
        [HttpPut("Update/{id}")]
        public async Task<APIResponse<UpdateRoomResponseDTO>> UpdateRoom(int id, [FromBody] UpdateRoomRequestDTO payload)
        {
            _logger.LogInformation("Request Received for UpdateRoom {@UpdateRoomRequestDTO}", payload);
            if (!ModelState.IsValid)
            {
                _logger.LogInformation("UpdateRoom Invalid Request Body");
                return new APIResponse<UpdateRoomResponseDTO>(HttpStatusCode.BadRequest, "Invalid Request Body");
            }
            if (id != payload.RoomID)
            {
                _logger.LogInformation("UpdateRoom Mismatched Room ID");
                return new APIResponse<UpdateRoomResponseDTO>(HttpStatusCode.BadRequest, "Mismatched Room ID.");
            }
            try
            {
                var response = await _roomRepository.UpdateRoomAsync(payload);
                if (response.IsUpdated)
                {
                    return new APIResponse<UpdateRoomResponseDTO>(response, response.Message);
                }
                return new APIResponse<UpdateRoomResponseDTO>(HttpStatusCode.BadRequest, response.Message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error Updating Room {id}", id);
                return new APIResponse<UpdateRoomResponseDTO>(HttpStatusCode.InternalServerError, "Update Room Failed.", ex.Message);
            }
        }
        [HttpDelete("Delete/{id}")]
        public async Task<APIResponse<DeleteRoomResponseDTO>> DeleteRoom(int id)
        {
            _logger.LogInformation($"Request Received for DeleteRoom, id: {id}");
            try
            {
                var room = await _roomRepository.GetSingleRoomAsync(id);
                if (room == null)
                {
                    return new APIResponse<DeleteRoomResponseDTO>(HttpStatusCode.NotFound, "Room not found.");
                }
                var response = await _roomRepository.DeleteRoomAsync(id);
                if (response.IsDeleted)
                {
                    return new APIResponse<DeleteRoomResponseDTO>(response, response.Message);
                }
                return new APIResponse<DeleteRoomResponseDTO>(HttpStatusCode.BadRequest, response.Message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting Room {id}", id);
                return new APIResponse<DeleteRoomResponseDTO>(HttpStatusCode.InternalServerError, "Internal server error: " + ex.Message);
            }
        }
    }
}