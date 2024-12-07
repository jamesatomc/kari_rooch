module kanari_network::math {
    const ERR_OVERFLOW: u64 = 101;

    public fun mul(a: u64, b: u64): u64 {
        let result = (a as u128) * (b as u128);
        assert!(result <= 18446744073709551615, ERR_OVERFLOW); // u64::MAX
        (result as u64)
    }

    public fun sqrt(x: u64): u64 {
        if (x == 0) {
            return 0
        };

        let z = x;
        let y = (z + 1) / 2;
        
        while (y < z) {
            z = y;
            y = (z + x / z) / 2;
        };

        z
    }

    // Optional: Add division function with checks
    public fun safe_div(a: u64, b: u64): u64 {
        assert!(b != 0, ERR_OVERFLOW);
        a / b
    }

    // Optional: Add additional helper functions as needed
    public fun min(a: u64, b: u64): u64 {
        if (a < b) a else b
    }
}