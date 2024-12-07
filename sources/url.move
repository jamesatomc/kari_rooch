module kanari_network::url {
    use std::ascii::{String, string};


    /// Standard Uniform Resource Locator (URL) string.
    struct Url has store, copy, drop {
        // TODO: validate URL format
        url: String,
    }

    /// Create a `Url`, with no validation
    fun new_unsafe(url: String): Url {
        Url { url }
    }

    /// Create a `Url` from raw bytes, with no validation
    public fun new_unsafe_from_bytes(bytes: vector<u8>): Url {
        let url_string = string(bytes);
        new_unsafe(url_string)
    }

    /// Get inner URL
    fun inner_url(self: &Url): String {
        self.url
    }

    /// Update the inner URL
    fun update(self: &mut Url, url: String) {
        self.url = url;
    }
}