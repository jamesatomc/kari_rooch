module kanari_network::object {
    use moveos_std::bcs;
    use moveos_std::address;
    use moveos_std::tx_context;
    use moveos_std::tx_context::TxContext;
    
    /// UID represents a unique identifier for objects in the system
    /// It wraps an ID to provide object identification functionality
    struct UID has store {
        id: ID
    }

    /// ID is an internal wrapper around an address that represents
    /// the core identifier value
    struct ID has store, copy, drop {
        bytes: address
    }
 
    /// Creates a new UID from an ID
    public fun new_uid(id: ID): UID {
        UID { id }
    }

    /// Creates a new UID from an address
    public fun new_uid_from_address(addr: address): UID {
        UID { id: ID { bytes: addr } }
    }
    
    /// Extracts the ID from a UID
    public fun uid_to_id(uid: &UID): &ID {
        &uid.id
    }

    /// Extracts the address from a UID
    public fun uid_to_address(uid: &UID): address {
        uid.id.bytes
    }

    /// Compares two UIDs for equality
    public fun uid_equals(uid1: &UID, uid2: &UID): bool {
        uid1.id.bytes == uid2.id.bytes
    }

    /// Destroys a UID
    public fun delete_uid(uid: UID) {
        let UID { id: _ } = uid;
    }

    /// Get the raw bytes of a `ID`
    public fun id_to_bytes(id: &ID): vector<u8> {
        bcs::to_bytes(&id.bytes)
    }

    /// Get the inner bytes of `id` as an address.
    public fun id_to_address(id: &ID): address {
        id.bytes
    }

    /// Make an `ID` from raw bytes
    public fun id_from_bytes(bytes: vector<u8>): ID {
        // Create an ID directly from the address
        ID { bytes: address::from_bytes(bytes) }
    }

    /// Make an `ID` from an address.
    public fun id_from_address(bytes: address): ID {
        ID { bytes }
    }

    /// The hardcoded ID for the singleton ROOCH System State Object.
    const ROOCH_SYSTEM_STATE_OBJECT_ID: address = @0x5;

    /// Sender is not @0x0 the system address.
    const ENotSystemAddress: u64 = 0;

    /// The hardcoded ID for the singleton Clock Object.
    const ROOCH_CLOCK_OBJECT_ID: address = @0x6;

    /// The hardcoded ID for the singleton AuthenticatorState Object.
    const ROOCH_AUTHENTICATOR_STATE_ID: address = @0x7;

    /// The hardcoded ID for the singleton Random Object.
    const ROOCH_RANDOM_ID: address = @0x8;

    /// The hardcoded ID for the singleton DenyList.
    const ROOCH_DENY_LIST_OBJECT_ID: address = @0x403;

    /// The hardcoded ID for the Bridge Object.
    const ROOCH_BRIDGE_ID: address = @0x9;

    // === uid ===
    fun rooch_system_state(): UID {
        // sender() is a global function that doesn't need ctx parameter
        assert!(tx_context::sender() == @0x0, ENotSystemAddress);
        UID {
            id: ID { bytes: ROOCH_SYSTEM_STATE_OBJECT_ID },
        }
    }
    
    /// Create the `UID` for the singleton `Clock` object.
    /// This should only be called once from `clock`.
    public(friend) fun clock(): UID {
        UID {
            id: ID { bytes: ROOCH_CLOCK_OBJECT_ID },
        }
    }

    /// Create the `UID` for the singleton `AuthenticatorState` object.
    /// This should only be called once from `authenticator_state`.
    public(friend) fun authenticator_state(): UID {
        UID {
            id: ID { bytes:  ROOCH_AUTHENTICATOR_STATE_ID },
        }
    }

    /// Create the `UID` for the singleton `Random` object.
    /// This should only be called once from `random`.
    public(friend) fun randomness_state(): UID {
        UID {
            id: ID { bytes: ROOCH_RANDOM_ID },
        }
    }

    /// Create the `UID` for the singleton `DenyList` object.
    /// This should only be called once from `deny_list`.
    public(friend) fun rooch_deny_list_object_id(): UID {
        UID {
            id: ID { bytes: ROOCH_DENY_LIST_OBJECT_ID },
        }
    }

    #[allow(unused_function)]
    /// Create the `UID` for the singleton `Bridge` object.
    /// This should only be called once from `bridge`.
    fun bridge(): UID {
        UID {
            id: ID { bytes: ROOCH_BRIDGE_ID },
        }
    }

    /// Get the inner `ID` of `uid`
    public fun uid_as_inner(uid: &UID): &ID {
        &uid.id
    }

    /// Get the raw bytes of a `uid`'s inner `ID`
    public fun uid_to_inner(uid: &UID): ID {
        uid.id
    }

    /// Get the raw bytes of a `UID`
    public fun uid_to_bytes(uid: &UID): vector<u8> {
        bcs::to_bytes(&uid.id.bytes)
    }

    // === any object ===

    /// Create a new object. Returns the `UID` that must be stored in a ROOCH object.
    /// This is the only way to create `UID`s.
    public fun new(ctx: &mut TxContext): UID {
        UID {
            id: ID { bytes: tx_context::fresh_address() }
        }
    }

    
    /// Internal helper to handle UID deletion
    native fun delete_impl(id: address);

    /// Internal helper to record new UIDs 
    native fun record_new_uid(id: address);




    #[test]
    fun test_new() {
        use moveos_std::tx_context;
        
        let ctx = tx_context::borrow_mut();
        let uid = new(ctx);
        
        // Verify UID was created with a fresh address
        assert!(uid_to_address(&uid) != @0x0, 0);
        
        delete_uid(uid);
    }

    #[test] 
    fun test_clock() {
        let uid = clock();
        assert!(uid_to_address(&uid) == ROOCH_CLOCK_OBJECT_ID, 0);
        delete_uid(uid);
    }

    #[test]
    fun test_rooch_system_state() {
        // Set up test context 
        tx_context::set_ctx_sender_for_testing(@0x0);
        
        // Test the function
        let uid = rooch_system_state();
        
        assert!(uid_to_address(&uid) == ROOCH_SYSTEM_STATE_OBJECT_ID, 0);
        delete_uid(uid);
    }

    #[test]
    fun test_uid_operations() {
        let addr = @0x1;
        let uid = new_uid_from_address(addr);
        assert!(uid_to_address(&uid) == addr, 0);
        
        let id = ID { bytes: addr };
        let uid2 = new_uid(id);
        assert!(uid_equals(&uid, &uid2), 1);
        
        // Clean up resources
        delete_uid(uid);
        delete_uid(uid2);
    }

    #[test]
    fun test_id_operations() {
        // Test address-based operations
        let addr = @0x1;
        let id = id_from_address(addr);
        assert!(id_to_address(&id) == addr, 0);
        
        // Test bytes-based operations
        let bytes = bcs::to_bytes(&addr);
        let id2 = id_from_bytes(bytes);
        assert!(id_to_address(&id2) == addr, 1);
        
        // Test byte conversion roundtrip
        let bytes2 = id_to_bytes(&id);
        let id3 = id_from_bytes(bytes2);
        assert!(id_to_address(&id) == id_to_address(&id3), 2);
        
        // Test direct equality
        assert!(id_to_address(&id) == id_to_address(&id2), 3);
    }
    
    #[test]
    fun test_uid_with_id() {
        let addr = @0x1;
        let id = id_from_address(addr);
        let uid = new_uid(id);
        
        assert!(uid_to_address(&uid) == addr, 0);
        let extracted_id = uid_to_id(&uid);
        assert!(id_to_address(extracted_id) == addr, 1);
        
        delete_uid(uid);
    }

}