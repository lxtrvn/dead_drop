program dead_drop.aleo {
    const ADMIN: address = aleo1f6hhrs823257c4p8efy26cwp4fwga4wjl2s0383e52ngw3xhnq9q2dlwl7;
    const TAX: u16 = 93u16;
    record Token{
        owner: address,
        amount: u64
    }
    mapping balance: address => u64;
    transition  mint (private receiver: address, private amount: u64) -> Token {
        assert_eq(self.caller, ADMIN);
        let token: Token = Token {
            owner: receiver,
            amount: amount
        };
        return token;
    }

    transition transfer(
         old_token: Token,
         private receiver: address, 
         private amount: u64
     ) -> (Token, Token) {
        let change_amount: u64 = old_token.amount - amount;
        let change_token: Token = Token {
            owner: old_token.owner,
            amount: change_amount
        };
        let receiver_token: Token = Token {
            owner: receiver,
            amount: amount
        };
        return (change_token, receiver_token);
    }
    async transition mint_public(public receiver: address, public amount: u64) -> Future {
        assert_eq(self.caller, ADMIN);
        return finalize_mint(receiver, amount);
    }
    async function finalize_mint(receiver: address, amount: u64){
        let old_balance: u64 = balance.get_or_use(receiver, 0u64);
        let new_balance: u64 = old_balance + amount;
        balance.set(receiver, new_balance);
    }
    
    async transition transfer_public(public receiver: address, public amount: u64) -> Future {
        return finalize_transfer(self.caller, receiver, amount);
    }
    async function finalize_transfer(sender: address, receiver: address, amount: u64){
        let pertax: u64 = TAX as u64;
        let tax_amount: u64 = amount*pertax/10000u64;
        let taxed_amount: u64 = amount - tax_amount;
        let admin_old_balance: u64 = balance.get_or_use(ADMIN, 0u64);
        let admin_new_balance: u64 = admin_old_balance + tax_amount;
        balance.set(ADMIN, admin_new_balance);

        let receiver_old_balance: u64 = balance.get_or_use(receiver, 0u64);
        let receiver_new_balance: u64 = receiver_old_balance + taxed_amount;
        balance.set(receiver, receiver_new_balance);
        
        let sender_old_balance: u64 = balance.get_or_use(sender, 0u64);
        let sender_new_balance: u64 = sender_old_balance - amount;
        balance.set(sender, sender_new_balance);
    }
    async transition transfer_private_to_public(
         old_token: Token,
         private receiver: address, 
         private amount: u64
     ) -> (Token, Future) {
        let change_amount: u64 = old_token.amount - amount ;
        let change_token: Token = Token {
            owner: old_token.owner,
            amount: change_amount
        };
        let transfer_future: Future = finalize_private_to_public(receiver, amount);
        return (change_token, transfer_future); // Notice we return both a record and a Future
    }
    async function finalize_private_to_public(receiver: address, amount: u64){
        // Add to receiver balance
        let pertax: u64 = TAX as u64;
        let tax_amount: u64 = amount*pertax/10000u64;
        let taxed_amount: u64 = amount - tax_amount;
        let admin_old_balance: u64 = balance.get_or_use(ADMIN, 0u64);
        let admin_new_balance: u64 = admin_old_balance + tax_amount;
        balance.set(ADMIN, admin_new_balance);
        
        let receiver_old_balance: u64 = balance.get_or_use(receiver, 0u64);
        let receiver_new_balance: u64 = receiver_old_balance + taxed_amount;
        balance.set(receiver, receiver_new_balance);
    }
    async transition transfer_public_to_private(
         private receiver: address, 
         private amount: u64
     ) -> (Token, Future) {
        let receiver_token: Token = Token {
            owner: receiver,
            amount: amount
        };
        let transfer_future: Future = finalize_public_to_private(self.caller, amount);
        return (receiver_token, transfer_future); // Notice we return both a record and a Future
    }
    async function finalize_public_to_private(sender: address, amount: u64){
        // Remove from sender balance
        let pertax: u64 = TAX as u64;
        let tax_amount: u64 = amount*pertax/10000u64;
        let taxed_amount: u64 = amount - tax_amount;
        let admin_old_balance: u64 = balance.get_or_use(ADMIN, 0u64);
        let admin_new_balance: u64 = admin_old_balance + tax_amount;
        balance.set(ADMIN, admin_new_balance);
        
        let sender_old_balance: u64 = balance.get_or_use(sender, 0u64);
        let sender_new_balance: u64 = sender_old_balance - amount;
        balance.set(sender, sender_new_balance);
    }
}
