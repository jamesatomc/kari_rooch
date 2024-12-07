module kanari_network::liquiditypool {
    use kanari_network::object::{UID, ID};

    use moveos_std::tx_context::{Self, TxContext}; 
    use moveos_std::object::{Self, Object};
    use moveos_std::bcs;
    use moveos_std::address;
    use moveos_std::simple_map::{Self, SimpleMap};
    use moveos_std::copyable_any::{Self, Any};
    use moveos_std::type_info;
    use moveos_std::tx_meta::{TxMeta};
    use moveos_std::tx_result::{TxResult};
    use moveos_std::event;
    use moveos_std::account;
    use moveos_std::timestamp;

    use rooch_framework::coin_store::{Self, CoinStore};
    use kanari_network::balance::{Balance};
    use kanari_network::math;

    // Error constants
    const ERR_EXPIRED: u64 = 1;
    const ERR_INSUFFICIENT_AMOUNT: u64 = 2;
    const ERR_INSUFFICIENT_LIQUIDITY: u64 = 3;
    const ERR_SLIPPAGE_A: u64 = 4;
    const ERR_SLIPPAGE_B: u64 = 5;
    const ERR_INVALID_K: u64 = 6;

    // LP Token to track shares
    struct LPToken has key, store {
        id: UID,
        amount: u64
    }

     // Added key ability constraint to CoinTypeA and CoinTypeB
    struct Pool<phantom CoinTypeA: key, phantom CoinTypeB: key> {
        id: UID,
        coin_a: Object<CoinStore<CoinTypeA>>,  // Changed from CoinStore to Object<CoinStore>
        coin_b: Object<CoinStore<CoinTypeB>>,  // Changed from CoinStore to Object<CoinStore>
        reserve_a: u64,
        reserve_b: u64,
        total_supply: u64,
        lp_shares: SimpleMap<address, u64>,
        fee_percentage: u64,
    }
    
    struct AddLiquidity<phantom CoinTypeA: key + store, phantom CoinTypeB: key + store> {
        pool: Pool<CoinTypeA, CoinTypeB>,
        coin_a: CoinStore<CoinTypeA>,
        coin_b: CoinStore<CoinTypeB>,
        amount_a_desired: u64,
        amount_b_desired: u64,
        amount_a_min: u64,
        amount_b_min: u64,
        deadline: u64
    }


    // Event emitted when liquidity is added
    struct AddLiquidityEvent has copy, drop {
        provider: address,
        amount_a: u64,
        amount_b: u64,
        liquidity: u64,
    }

    public fun add_liquidity<CoinTypeA: key + store, CoinTypeB: key + store>(
        pool: &mut Pool<CoinTypeA, CoinTypeB>,
        coin_a: &mut Object<CoinStore<CoinTypeA>>, 
        coin_b: &mut Object<CoinStore<CoinTypeB>>,
        amount_a_desired: u64,
        amount_b_desired: u64,
        amount_a_min: u64,
        amount_b_min: u64,
        deadline: u64,
        ctx: &mut TxContext
    ): (u64, u64, u64) {
        // Check deadline
        assert!(timestamp::now_seconds() <= deadline, ERR_EXPIRED);
        
        // Calculate optimal amounts
        let (amount_a, amount_b) = calculate_optimal_amounts(
            pool.reserve_a,
            pool.reserve_b,
            amount_a_desired,
            amount_b_desired
        );
    
        // Verify slippage
        assert!(amount_a >= amount_a_min, ERR_SLIPPAGE_A);
        assert!(amount_b >= amount_b_min, ERR_SLIPPAGE_B);
    
        // Withdraw tokens with proper u256 conversion
        let coin_a_withdrawal = coin_store::withdraw(coin_a, (amount_a as u256));
        let coin_b_withdrawal = coin_store::withdraw(coin_b, (amount_b as u256));
    
        // Calculate and mint LP tokens
        let liquidity = calculate_liquidity(
            pool.reserve_a,
            pool.reserve_b,
            amount_a,
            amount_b,
            
        );

        // Deposit the withdrawn coins into the pool's coin stores
        coin_store::deposit(&mut pool.coin_a, coin_a_withdrawal);
        coin_store::deposit(&mut pool.coin_b, coin_b_withdrawal);
    
        // Update pool state
        pool.reserve_a = pool.reserve_a + amount_a;
        pool.reserve_b = pool.reserve_b + amount_b;
        pool.total_supply = pool.total_supply + liquidity;
        
        // Add liquidity shares using the sender's address without ctx parameter
        simple_map::add(&mut pool.lp_shares, tx_context::sender(), liquidity);
    
    
        (amount_a, amount_b, liquidity)
    }
    


    fun calculate_liquidity(
        amount_a: u64,
        amount_b: u64,
        reserve_a: u64,
        reserve_b: u64
    ): u64 {
        if (reserve_a == 0 && reserve_b == 0) {
            // For the first deposit, liquidity is the geometric mean of amounts
            math::sqrt(math::mul(amount_a, amount_b))
        } else {
            // For subsequent deposits, take the minimum to maintain price ratio
            let liquidity_a = math::mul(amount_a, reserve_b) / reserve_a;
            let liquidity_b = math::mul(amount_b, reserve_a) / reserve_b;
            if (liquidity_a < liquidity_b) {
                liquidity_a
            } else {
                liquidity_b
            }
        }
    }

    fun calculate_optimal_amounts(
        reserve_a: u64,
        reserve_b: u64,
        amount_a_desired: u64,
        amount_b_desired: u64
    ): (u64, u64) {
        if (reserve_a == 0 && reserve_b == 0) {
            return (amount_a_desired, amount_b_desired)
        };
        
        let amount_b_optimal = quote(amount_a_desired, reserve_a, reserve_b);
        if (amount_b_optimal <= amount_b_desired) {
            return (amount_a_desired, amount_b_optimal)
        };
    
        let amount_a_optimal = quote(amount_b_desired, reserve_b, reserve_a);
        (amount_a_optimal, amount_b_desired)
    }
    
    fun quote(
        amount_x: u64,
        reserve_x: u64,
        reserve_y: u64
    ): u64 {
        assert!(amount_x > 0, ERR_INSUFFICIENT_AMOUNT);
        assert!(reserve_x > 0 && reserve_y > 0, ERR_INSUFFICIENT_LIQUIDITY);
        
        ((amount_x as u128) * (reserve_y as u128) / (reserve_x as u128) as u64)
    }



}

