module kanari_network::user {
    use kanari_network::object::{UID, ID};

    struct User has store {
        uid: UID,
        name: vector<u8>,
        email: vector<u8>,
        phone: vector<u8>,
        address: vector<u8>,
        created_at: u64,
        updated_at: u64,
    }

    public fun new_user(uid: UID, name: vector<u8>, email: vector<u8>, phone: vector<u8>, address: vector<u8>, created_at: u64, updated_at: u64): User {
        User { uid, name, email, phone, address, created_at, updated_at }
    }

}