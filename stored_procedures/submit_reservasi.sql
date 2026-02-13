CREATE OR REPLACE PROCEDURE sp_submit_reservasi(
    IN p_user_id INTEGER,
    IN p_lapangan_id INTEGER,
    IN p_start_time TIMESTAMP,
    IN p_end_time TIMESTAMP,
    IN p_metode_pembayaran VARCHAR,
    INOUT p_reservasi_id INTEGER DEFAULT 0, 
    INOUT p_total_bayar DECIMAL DEFAULT 0,
    INOUT p_is_success BOOLEAN DEFAULT FALSE,
    INOUT p_message TEXT DEFAULT ''
)
LANGUAGE plpgsql AS $$
DECLARE
    v_harga DECIMAL; v_durasi DECIMAL; v_aktif BOOLEAN;
BEGIN
    -- Validasi
    IF p_start_time >= p_end_time THEN
        p_is_success := FALSE; p_message := 'Waktu mulai harus sebelum selesai.'; RETURN;
    END IF;

    SELECT harga_per_jam, status INTO v_harga, v_aktif FROM Lapangan WHERE id = p_lapangan_id;
    
    IF NOT FOUND OR v_aktif = FALSE THEN
        p_is_success := FALSE; p_message := 'Lapangan tidak tersedia.'; RETURN;
    END IF;

    -- Hitung Biaya
    v_durasi := EXTRACT(EPOCH FROM (p_end_time - p_start_time)) / 3600;
    p_total_bayar := v_harga * v_durasi;

    -- Transaksi
    BEGIN
        INSERT INTO Reservasi (user_id, lapangan_id, start_time, end_time, status, waktu_range)
        VALUES (p_user_id, p_lapangan_id, p_start_time, p_end_time, 'pending', tsrange(p_start_time, p_end_time, '[)'))
        RETURNING id INTO p_reservasi_id;

        INSERT INTO Pembayaran (reservasi_id, jumlah, metode, status)
        VALUES (p_reservasi_id, p_total_bayar, p_metode_pembayaran, 'pending');

        p_is_success := TRUE; p_message := 'Reservasi berhasil dibuat. Total: ' || p_total_bayar;
    EXCEPTION 
        WHEN exclusion_violation THEN
            p_is_success := FALSE; p_message := 'Gagal: Jadwal bentrok dengan user lain.';
        WHEN OTHERS THEN
            p_is_success := FALSE; p_message := 'Error: ' || SQLERRM;
    END;
END;
$$;