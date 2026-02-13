CREATE OR REPLACE PROCEDURE sp_verifikasi_pembayaran(
    IN p_reservasi_id INTEGER,
    IN p_admin_id INTEGER,
    INOUT p_is_success BOOLEAN DEFAULT FALSE,
    INOUT p_message TEXT DEFAULT ''
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE Pembayaran SET status = 'paid', verified_by = p_admin_id, verified_at = NOW()
    WHERE reservasi_id = p_reservasi_id;
    
    UPDATE Reservasi SET status = 'confirmed' WHERE id = p_reservasi_id;
    
    p_is_success := TRUE; p_message := 'Pembayaran diverifikasi.';
END;
$$;