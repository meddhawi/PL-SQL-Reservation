-- 1. Tabel Users (Authentication dengan role)
CREATE TABLE Users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,  -- Hash dengan bcrypt
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'manager', 'user')) DEFAULT 'user',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Grant privileges berdasarkan role (contoh untuk manager)
GRANT SELECT, INSERT, UPDATE, DELETE ON Users TO admin;
GRANT SELECT, INSERT, UPDATE ON Users TO manager;  -- Manager bisa edit user non-admin
GRANT SELECT ON Users TO user_role;  -- User lihat profil sendiri

-- 2. Tabel Lapangan
CREATE TABLE Lapangan (
    id SERIAL PRIMARY KEY,
    nama VARCHAR(100) NOT NULL,
    tipe VARCHAR(20) NOT NULL CHECK (tipe IN ('futsal', 'badminton')),
    lokasi VARCHAR(200),
    harga_per_jam DECIMAL(10, 2) NOT NULL,
    status BOOLEAN DEFAULT TRUE,  -- True: available
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

GRANT ALL ON Lapangan TO admin, manager;
GRANT SELECT ON Lapangan TO user_role;

-- 3. Tabel Slot (Predefined slot per lapangan)
CREATE TABLE Slot (
    id SERIAL PRIMARY KEY,
    lapangan_id INTEGER NOT NULL REFERENCES Lapangan(id) ON DELETE CASCADE,
    waktu_mulai TIMESTAMP WITH TIME ZONE NOT NULL,
    durasi INTERVAL NOT NULL DEFAULT '1 hour'::INTERVAL,
    status VARCHAR(20) DEFAULT 'available' CHECK (status IN ('available', 'booked', 'maintenance')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(lapangan_id, waktu_mulai)
);

GRANT ALL ON Slot TO admin, manager;
GRANT SELECT ON Slot TO user_role;

-- 4. Tabel Reservasi (Dengan exclusion untuk anti-double-booking)
CREATE TABLE Reservasi (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    lapangan_id INTEGER NOT NULL REFERENCES Lapangan(id) ON DELETE RESTRICT,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    slot_id INTEGER REFERENCES Slot(id),  -- Opsional jika pakai predefined slot
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    EXCLUDE USING GIST (lapangan_id WITH =, waktu_range WITH &&)  -- Cegah overlap per lapangan
);

GRANT ALL ON Reservasi TO admin, manager;
GRANT SELECT, INSERT, UPDATE ON Reservasi TO user_role WHERE user_id = current_setting('app.current_user_id')::integer;  -- User akses sendiri (butuh set variabel)

-- 5. Tabel Pembayaran (Bukti dan info pembayaran)
CREATE TABLE Pembayaran (
    id SERIAL PRIMARY KEY,
    reservasi_id INTEGER NOT NULL UNIQUE REFERENCES Reservasi(id) ON DELETE CASCADE,
    jumlah DECIMAL(10, 2) NOT NULL,
    metode VARCHAR(50) NOT NULL,  -- e.g., 'transfer', 'qris'
    bukti_path VARCHAR(255),  -- Path file bukti (upload gambar/PDF)
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'failed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

GRANT ALL ON Pembayaran TO admin, manager;
GRANT SELECT, UPDATE ON Pembayaran TO user_role;  -- User update status sendiri

-- 6. Tabel Riwayat (History reservasi dan pembayaran)
CREATE TABLE Riwayat (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    reservasi_id INTEGER REFERENCES Reservasi(id) ON DELETE SET NULL,
    pembayaran_id INTEGER REFERENCES Pembayaran(id) ON DELETE SET NULL,
    aksi VARCHAR(50) NOT NULL,  -- e.g., 'create_reservation', 'pay', 'cancel'
    deskripsi TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

GRANT ALL ON Riwayat TO admin;
GRANT SELECT ON Riwayat TO manager, user_role;  -- Manager lihat semua, user lihat sendiri

-- Index untuk performa
CREATE INDEX idx_reservasi_waktu ON Reservasi USING GIST (waktu_range);
CREATE INDEX idx_reservasi_lapangan ON Reservasi (lapangan_id);