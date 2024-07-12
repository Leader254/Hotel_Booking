using System.ComponentModel.DataAnnotations;

namespace api.DTOs.UserDTOs
{
    public class UserRoleDTO
    {
        [Required(ErrorMessage = "User Id is Required")]
        public int UserID { get; set; }
        [Required(ErrorMessage = "Role Id is Required")]
        public int RoleID { get; set; }
    }
}
