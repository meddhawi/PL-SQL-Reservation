CREATE OR REPLACE PROCEDURE sp_create_lapangan(
    IN p_nama VARCHAR,
    IN p_tipe VARCHAR,
    IN p_lokasi VARCHAR,
    IN p_harga DECIMAL,
    INOUT p_is_success BOOLEAN DEFAULT FALSE,
    INOUT p_message TEXT DEFAULT ''
)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_harga < 0 THEN
        p_is_success := FALSE; p_message := 'Harga tidak boleh negatif.'; RETURN;
    END IF;
    
    INSERT INTO Lapangan (nama, tipe, lokasi, harga_per_jam, status)
    VALUES (p_nama, p_tipe, p_lokasi, p_harga, TRUE);
    
    p_is_success := TRUE; p_message := 'Lapangan berhasil ditambahkan.';
EXCEPTION WHEN OTHERS THEN
    p_is_success := FALSE; p_message := 'Error: ' || SQLERRM;
END;
$$;