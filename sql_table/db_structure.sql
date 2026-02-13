-- 1. Extension untuk Exclusion Constraint
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- 2. Tabel Users
CREATE TABLE Users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) CHECK (role IN ('admin', 'manager', 'user')) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 3. Tabel Lapangan
CREATE TABLE Lapangan (
    id SERIAL PRIMARY KEY,
    nama VARCHAR(100) NOT NULL,
    tipe VARCHAR(20) CHECK (tipe IN ('futsal', 'badminton')),
    lokasi VARCHAR(200),
    harga_per_jam DECIMAL(10, 2) NOT NULL CHECK (harga_per_jam >= 0),
    status BOOLEAN DEFAULT TRUE, -- TRUE = Available, FALSE = Maintenance/Deleted
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 4. Tabel Reservasi (Dengan Exclusion Constraint)
CREATE TABLE Reservasi (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES Users(id),
    lapangan_id INTEGER REFERENCES Lapangan(id),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    waktu_range TSRANGE NOT NULL, -- Kolom teknis untuk validasi bentrok
    status VARCHAR(20) CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')) DEFAULT 'pending',
    catatan TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    
    -- Constraint Anti-Bentrok: Mencegah overlap waktu pada lapangan yang sama
    EXCLUDE USING GIST (lapangan_id WITH =, waktu_range WITH &&)
);

-- 5. Tabel Pembayaran
CREATE TABLE Pembayaran (
    id SERIAL PRIMARY KEY,
    reservasi_id INTEGER UNIQUE REFERENCES Reservasi(id),
    jumlah DECIMAL(10, 2) NOT NULL,
    metode VARCHAR(50), -- transfer, qris, cash
    bukti_path VARCHAR(255),
    status VARCHAR(20) CHECK (status IN ('pending', 'paid', 'failed', 'refund_pending')) DEFAULT 'pending',
    verified_by INTEGER REFERENCES Users(id),
    verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 6. Tabel Riwayat (Audit Trail)
CREATE TABLE Riwayat (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES Users(id),
    reservasi_id INTEGER REFERENCES Reservasi(id),
    aksi VARCHAR(50) NOT NULL, -- create, update_status, cancel
    deskripsi TEXT,
    timestamp TIMESTAMP DEFAULT NOW()
);