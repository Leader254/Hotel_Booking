using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using HotelBookingAPI.Repository;
using Microsoft.AspNetCore.Mvc;

namespace HotelBookingAPI.Controllers
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
    }
}