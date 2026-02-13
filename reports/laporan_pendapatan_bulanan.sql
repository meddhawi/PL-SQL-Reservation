CREATE OR REPLACE VIEW vw_laporan_pendapatan AS
SELECT 
    TO_CHAR(r.start_time, 'YYYY-MM') AS periode,
    COUNT(r.id) AS total_booking,
    COUNT(CASE WHEN p.status = 'paid' THEN 1 END) AS total_lunas,
    SUM(CASE WHEN p.status = 'paid' THEN p.jumlah ELSE 0 END) AS revenue
FROM Reservasi r JOIN Pembayaran p ON r.id = p.reservasi_id
GROUP BY 1 ORDER BY 1 DESC;