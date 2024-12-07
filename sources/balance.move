module kanari_network::balance {
    /// Balance holds a value of type T
    struct Balance<phantom T> has store {
        value: u64
    }

    /// Create a new balance with zero value
    public fun zero<T>(): Balance<T> {
        Balance { value: 0 }
    }

    /// Get the value of the balance
    public fun value<T>(balance: &Balance<T>): u64 {
        balance.value
    }

    /// Deposit value into balance
    public fun deposit<T>(balance: &mut Balance<T>, amount: u64) {
        balance.value = balance.value + amount;
    }

    /// Withdraw value from balance if sufficient
    public fun withdraw<T>(balance: &mut Balance<T>, amount: u64): Balance<T> {
        assert!(balance.value >= amount, 1); // Insufficient balance
        balance.value = balance.value - amount;
        Balance { value: amount }
    }

    /// Join two balances
    public fun join<T>(balance1: &mut Balance<T>, balance2: Balance<T>) {
        let Balance { value } = balance2;
        deposit(balance1, value);
    }

    /// Split balance into two
    public fun split<T>(balance: &mut Balance<T>, amount: u64): Balance<T> {
        withdraw(balance, amount)
    }
}