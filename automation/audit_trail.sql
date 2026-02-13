CREATE OR REPLACE FUNCTION tf_log_riwayat_reservasi()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_desc TEXT;
BEGIN
    IF (TG_OP = 'INSERT') THEN
        v_desc := 'Reservasi dibuat (ID: ' || NEW.id || ')';
        INSERT INTO Riwayat (user_id, reservasi_id, aksi, deskripsi, timestamp)
        VALUES (NEW.user_id, NEW.id, 'create', v_desc, NOW());
        RETURN NEW;
    ELSIF (TG_OP = 'UPDATE') THEN
        IF OLD.status IS DISTINCT FROM NEW.status THEN
            v_desc := 'Status berubah: ' || OLD.status || ' -> ' || NEW.status;
            INSERT INTO Riwayat (user_id, reservasi_id, aksi, deskripsi, timestamp)
            VALUES (NEW.user_id, NEW.id, 'update_status', v_desc, NOW());
        END IF;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_audit_reservasi
AFTER INSERT OR UPDATE ON Reservasi
FOR EACH ROW EXECUTE FUNCTION tf_log_riwayat_reservasi();