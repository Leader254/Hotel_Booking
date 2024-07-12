
namespace api.Models
{
    public class Dtos
    {
        public class UserRole
        {
            public int RoleID { get; set; }
            public string RoleName { get; set; }
            public bool IsActive { get; set; }
            public string Description { get; set; }
        }

        public class User
        {
            public int UserID { get; set; }
            public int RoleID { get; set; }
            public string Email { get; set; }
            public string PasswordHash { get; set; }
            public DateTime CreatedAt { get; set; }
            public DateTime? LastLogin { get; set; }
            public bool IsActive { get; set; }
            public string CreatedBy { get; set; }
            public DateTime CreatedDate { get; set; }
            public string ModifiedBy { get; set; }
            public DateTime? ModifiedDate { get; set; }

            public UserRole UserRole { get; set; }
        }

        public class Country
        {
            public int CountryID { get; set; }
            public string CountryName { get; set; }
            public string CountryCode { get; set; }
            public bool IsActive { get; set; }
        }

        public class State
        {
            public int StateID { get; set; }
            public string StateName { get; set; }
            public int CountryID { get; set; }
            public bool IsActive { get; set; }

            public Country Country { get; set; }
        }

        public class RoomType
        {
            public int RoomTypeID { get; set; }
            public string TypeName { get; set; }
            public string AccessibilityFeatures { get; set; }
            public string Description { get; set; }
            public bool IsActive { get; set; }
            public string CreatedBy { get; set; }
            public DateTime CreatedDate { get; set; }
            public string ModifiedBy { get; set; }
            public DateTime? ModifiedDate { get; set; }
        }

        public class Room
        {
            public int RoomID { get; set; }
            public string RoomNumber { get; set; }
            public int RoomTypeID { get; set; }
            public decimal Price { get; set; }
            public string BedType { get; set; }
            public string ViewType { get; set; }
            public string Status { get; set; }
            public bool IsActive { get; set; }
            public string CreatedBy { get; set; }
            public DateTime CreatedDate { get; set; }
            public string ModifiedBy { get; set; }
            public DateTime? ModifiedDate { get; set; }

            public RoomType RoomType { get; set; }
        }

        public class Amenity
        {
            public int AmenityID { get; set; }
            public string Name { get; set; }
            public string Description { get; set; }
            public bool IsActive { get; set; }
            public string CreatedBy { get; set; }
            public DateTime CreatedDate { get; set; }
            public string ModifiedBy { get; set; }
            public DateTime? ModifiedDate { get; set; }
        }

        public class RoomAmenity
        {
            public int RoomTypeID { get; set; }
            public int AmenityID { get; set; }

            public RoomType RoomType { get; set; }
            public Amenity Amenity { get; set; }
        }

        public class Guest
        {
            public int GuestID { get; set; }
            public int UserID { get; set; }
            public string FirstName { get; set; }
            public string LastName { get; set; }
            public string Email { get; set; }
            public string Phone { get; set; }
            public string AgeGroup { get; set; }
            public string Address { get; set; }
            public int CountryID { get; set; }
            public int StateID { get; set; }
            public string CreatedBy { get; set; }
            public DateTime CreatedDate { get; set; }
            public string ModifiedBy { get; set; }
            public DateTime? ModifiedDate { get; set; }

            public User User { get; set; }
            public Country Country { get; set; }
            public State State { get; set; }
        }

        public class Reservation
        {
            public int ReservationID { get; set; }
            public int UserID { get; set; }
            public int RoomID { get; set; }
            public DateTime BookingDate { get; set; }
            public DateTime CheckInDate { get; set; }
            public DateTime CheckOutDate { get; set; }
            public int NumberOfGuests { get; set; }
            public string Status { get; set; }
            public string CreatedBy { get; set; }
            public DateTime CreatedDate { get; set; }
            public string ModifiedBy { get; set; }
            public DateTime? ModifiedDate { get; set; }

            public User User { get; set; }
            public Room Room { get; set; }
        }

        public class ReservationGuest
        {
            public int ReservationGuestID { get; set; }
            public int ReservationID { get; set; }
            public int GuestID { get; set; }

            public Reservation Reservation { get; set; }
            public Guest Guest { get; set; }
        }

        public class PaymentBatch
        {
            public int PaymentBatchID { get; set; }
            public int UserID { get; set; }
            public DateTime PaymentDate { get; set; }
            public decimal TotalAmount { get; set; }
            public string PaymentMethod { get; set; }

            public User User { get; set; }
        }

        public class Payment
        {
            public int PaymentID { get; set; }
            public int ReservationID { get; set; }
            public decimal Amount { get; set; }
            public int PaymentBatchID { get; set; }

            public Reservation Reservation { get; set; }
            public PaymentBatch PaymentBatch { get; set; }
        }

        public class Cancellation
        {
            public int CancellationID { get; set; }
            public int ReservationID { get; set; }
            public DateTime CancellationDate { get; set; }
            public string Reason { get; set; }
            public decimal CancellationFee { get; set; }
            public string CancellationStatus { get; set; }
            public string CreatedBy { get; set; }
            public DateTime CreatedDate { get; set; }
            public string ModifiedBy { get; set; }
            public DateTime? ModifiedDate { get; set; }

            public Reservation Reservation { get; set; }
        }

        public class RefundMethod
        {
            public int MethodID { get; set; }
            public string MethodName { get; set; }
            public bool IsActive { get; set; }
        }

        public class Refund
        {
            public int RefundID { get; set; }
            public int PaymentID { get; set; }
            public decimal RefundAmount { get; set; }
            public DateTime RefundDate { get; set; }
            public string RefundReason { get; set; }
            public int RefundMethodID { get; set; }
            public int ProcessedByUserID { get; set; }
            public string RefundStatus { get; set; }

            public Payment Payment { get; set; }
            public RefundMethod RefundMethod { get; set; }
            public User ProcessedByUser { get; set; }
        }

        public class Feedback
        {
            public int FeedbackID { get; set; }
            public int ReservationID { get; set; }
            public int GuestID { get; set; }
            public int Rating { get; set; }
            public string Comment { get; set; }
            public DateTime FeedbackDate { get; set; }

            public Reservation Reservation { get; set; }
            public Guest Guest { get; set; }
        }
    }
}