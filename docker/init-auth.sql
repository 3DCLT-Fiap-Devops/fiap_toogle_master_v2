-- --- Auth Service Tables ---
CREATE TABLE IF NOT EXISTS api_keys (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    key_hash VARCHAR(64) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Insert a default API key for testing
-- Key: tm_key_f54b81bc161a5b84c277ed954384ae950c87adb8c795892db4abfaef75aaacab
INSERT INTO api_keys (name, key_hash) 
VALUES ('Default Test Key', '8cfe60ccf86afc21b71ebb7c1550c3fcfa0e796379c4da95007b9aa41ea2b86c')
ON CONFLICT (key_hash) DO NOTHING;
