CREATE OR REPLACE PROCEDURE sp_delete_lapangan(
    IN p_lapangan_id INTEGER,
    INOUT p_is_success BOOLEAN DEFAULT FALSE,
    INOUT p_message TEXT DEFAULT ''
)
LANGUAGE plpgsql AS $$
DECLARE v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count FROM Reservasi WHERE lapangan_id = p_lapangan_id;
    
    IF v_count > 0 THEN
        UPDATE Lapangan SET status = FALSE WHERE id = p_lapangan_id;
        p_message := 'Soft Delete: Lapangan dinonaktifkan karena ada riwayat transaksi.';
    ELSE
        DELETE FROM Lapangan WHERE id = p_lapangan_id;
        p_message := 'Hard Delete: Lapangan dihapus permanen.';
    END IF;
    p_is_success := TRUE;
EXCEPTION WHEN OTHERS THEN
    p_is_success := FALSE; p_message := 'Error: ' || SQLERRM;
END;
$$;