public class PaymentService {
    
    public String processPayment(User user, PaymentRequest request) {
        // Line 42 - BUG: No null check on user
        String email = user.getEmail();  // NPE for guest checkouts!
        
        PaymentProcessor processor = new PaymentProcessor();
        return processor.charge(email, request.getAmount());
    }
    
    public String processGuestPayment(PaymentRequest request) {
        // Guest checkout - user is null!
        User guest = null;
        return processPayment(guest, request);  // CRASH HERE
    }
}
