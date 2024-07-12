using System.ComponentModel.DataAnnotations;

namespace api.DTOs.AmenityDTOs
{
    public class AmenityInsertDTO
    {
        [Required]
        [StringLength(100, ErrorMessage = "Name Length can't be more than 100 chars")]
        public string Name { get; set; }
        [StringLength(255, ErrorMessage = "Description length can't be more than 255 chars")]
        public string Description { get; set; }
    }
}