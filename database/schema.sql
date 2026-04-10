-- ═══════════════════════════════════════════════════════════════════════════
-- SCRIPT SQL PARA REGISTRO DE ENTRADAS DE EMBARQUES
-- Base de datos: mes_production (MySQL 8.0 en Azure)
-- ═══════════════════════════════════════════════════════════════════════════
-- 
-- Ejecutar este script en tu base de datos MySQL para crear las tablas
-- necesarias para el módulo de registro de embarques.
--
-- Conexión (solo para backend/servidor, NUNCA en cliente):
--   Host:     4.236.163.153
--   Port:     3306
--   Database: mes_production
--   User:     mes_admin
-- ═══════════════════════════════════════════════════════════════════════════

USE mes_production;

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLA: operators
-- Usuarios/operadores que usan la aplicación
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS operators (
    id VARCHAR(20) PRIMARY KEY COMMENT 'Número de empleado',
    full_name VARCHAR(100) NOT NULL,
    department VARCHAR(50) NULL,
    shift ENUM('A', 'B', 'C', 'admin') DEFAULT 'A',
    password_hash VARCHAR(255) NOT NULL COMMENT 'Hash bcrypt del password',
    is_active BOOLEAN DEFAULT TRUE,
    last_login DATETIME NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Operadores del sistema de registro de embarques';

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLA: quality_validations
-- Estatus de calidad de los Box IDs (alimentada por otra aplicación)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS quality_validations (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    box_id VARCHAR(50) NOT NULL,
    product_name VARCHAR(150) NULL,
    lot_number VARCHAR(50) NULL,
    quality_status ENUM('released', 'pending', 'rejected', 'in_process') NOT NULL DEFAULT 'pending',
    validated_by VARCHAR(20) NULL COMMENT 'ID del inspector de calidad',
    validated_at DATETIME NULL,
    rejection_reason TEXT NULL COMMENT 'Motivo de rechazo si aplica',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE INDEX idx_box_id_unique (box_id),
    INDEX idx_quality_status (quality_status),
    INDEX idx_lot_number (lot_number),
    INDEX idx_validated_at (validated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Validaciones de calidad de Box IDs (alimentada por QA app)';

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLA: shipping_entries
-- Registro de escaneos/entradas de embarques
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS shipping_entries (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    box_id VARCHAR(50) NOT NULL,
    quality_status ENUM('released', 'pending', 'rejected', 'in_process') NOT NULL,
    scanned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    scanned_by VARCHAR(20) NOT NULL COMMENT 'ID del operador que escaneó',
    product_name VARCHAR(150) NULL,
    lot_number VARCHAR(50) NULL,
    warehouse_zone VARCHAR(20) NULL COMMENT 'Zona del almacén (A1, B2, etc.)',
    notes TEXT NULL COMMENT 'Notas adicionales del operador',
    device_id VARCHAR(50) NULL COMMENT 'ID del dispositivo PDA',
    synced_at DATETIME NULL COMMENT 'Timestamp de sincronización',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_box_id (box_id),
    INDEX idx_scanned_at (scanned_at),
    INDEX idx_scanned_by (scanned_by),
    INDEX idx_quality_status (quality_status),
    INDEX idx_lot_number (lot_number),
    INDEX idx_warehouse_zone (warehouse_zone),
    
    -- Foreign key al operador (opcional, comentar si no se requiere)
    -- CONSTRAINT fk_shipping_operator FOREIGN KEY (scanned_by) 
    --     REFERENCES operators(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Registro de escaneos de Box IDs en almacén de embarques';

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLA: shipping_entry_logs (Auditoría - Opcional)
-- Historial de cambios en entradas de embarque
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS shipping_entry_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    entry_id BIGINT UNSIGNED NOT NULL,
    action ENUM('created', 'updated', 'deleted') NOT NULL,
    changed_by VARCHAR(20) NOT NULL,
    changed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    old_values JSON NULL,
    new_values JSON NULL,
    
    INDEX idx_entry_id (entry_id),
    INDEX idx_changed_at (changed_at),
    
    CONSTRAINT fk_log_entry FOREIGN KEY (entry_id) 
        REFERENCES shipping_entries(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Auditoría de cambios en registros de embarque';

-- ═══════════════════════════════════════════════════════════════════════════
-- DATOS DE PRUEBA (comentar en producción)
-- ═══════════════════════════════════════════════════════════════════════════

-- Insertar operadores de prueba
-- Password '1247' hasheado con bcrypt (cost 10)
-- En producción, generar hashes reales con tu backend
INSERT INTO operators (id, full_name, department, shift, password_hash) VALUES
('1247', 'Operador 1247', 'Almacén de Embarques', 'A', '$2a$10$PLACEHOLDER_HASH_1247'),
('1248', 'Operador 1248', 'Almacén de Embarques', 'B', '$2a$10$PLACEHOLDER_HASH_1248'),
('1249', 'Operador 1249', 'Control de Calidad', 'A', '$2a$10$PLACEHOLDER_HASH_1249'),
('admin', 'Administrador Sistema', 'TI', 'admin', '$2a$10$PLACEHOLDER_HASH_ADMIN')
ON DUPLICATE KEY UPDATE full_name = VALUES(full_name);

-- Insertar validaciones de calidad de prueba
INSERT INTO quality_validations (box_id, product_name, lot_number, quality_status, validated_by, validated_at) VALUES
('BOX-2026-001847', 'Componente electrónico A', 'LOT-2026-0218A', 'released', '1249', NOW()),
('BOX-2026-001846', 'Arnés de cableado B', 'LOT-2026-0218B', 'released', '1249', NOW()),
('BOX-2026-001845', 'Sensor de temperatura C', 'LOT-2026-0217C', 'pending', NULL, NULL),
('BOX-2026-001844', 'Conector tipo D', 'LOT-2026-0217D', 'rejected', '1249', NOW()),
('BOX-2026-001843', 'Módulo de control E', 'LOT-2026-0216E', 'released', '1249', NOW()),
('BOX-2026-001842', 'Placa base F', 'LOT-2026-0216F', 'in_process', NULL, NULL)
ON DUPLICATE KEY UPDATE quality_status = VALUES(quality_status);

-- ═══════════════════════════════════════════════════════════════════════════
-- VISTAS ÚTILES
-- ═══════════════════════════════════════════════════════════════════════════

-- Vista: Estadísticas diarias de escaneos
CREATE OR REPLACE VIEW v_daily_shipping_stats AS
SELECT 
    DATE(scanned_at) AS scan_date,
    COUNT(*) AS total,
    SUM(CASE WHEN quality_status = 'released' THEN 1 ELSE 0 END) AS released,
    SUM(CASE WHEN quality_status = 'pending' THEN 1 ELSE 0 END) AS pending,
    SUM(CASE WHEN quality_status = 'rejected' THEN 1 ELSE 0 END) AS rejected,
    SUM(CASE WHEN quality_status = 'in_process' THEN 1 ELSE 0 END) AS in_process
FROM shipping_entries
GROUP BY DATE(scanned_at)
ORDER BY scan_date DESC;

-- Vista: Últimos escaneos con info de calidad
CREATE OR REPLACE VIEW v_recent_scans AS
SELECT 
    se.id,
    se.box_id,
    se.quality_status,
    se.scanned_at,
    se.scanned_by,
    o.full_name AS operator_name,
    se.product_name,
    se.lot_number,
    se.warehouse_zone,
    qv.rejection_reason
FROM shipping_entries se
LEFT JOIN operators o ON se.scanned_by = o.id
LEFT JOIN quality_validations qv ON se.box_id = qv.box_id
ORDER BY se.scanned_at DESC
LIMIT 100;

-- ═══════════════════════════════════════════════════════════════════════════
-- PROCEDIMIENTOS ALMACENADOS (Opcional - para lógica en BD)
-- ═══════════════════════════════════════════════════════════════════════════

DELIMITER //

-- Procedimiento: Obtener estadísticas del día
CREATE PROCEDURE IF NOT EXISTS sp_get_today_stats()
BEGIN
    SELECT 
        COUNT(*) AS total,
        SUM(CASE WHEN quality_status = 'released' THEN 1 ELSE 0 END) AS released,
        SUM(CASE WHEN quality_status = 'pending' THEN 1 ELSE 0 END) AS pending,
        SUM(CASE WHEN quality_status = 'rejected' THEN 1 ELSE 0 END) AS rejected,
        SUM(CASE WHEN quality_status = 'in_process' THEN 1 ELSE 0 END) AS in_process
    FROM shipping_entries
    WHERE DATE(scanned_at) = CURDATE();
END //

-- Procedimiento: Registrar entrada de embarque
CREATE PROCEDURE IF NOT EXISTS sp_register_shipping_entry(
    IN p_box_id VARCHAR(50),
    IN p_scanned_by VARCHAR(20),
    IN p_warehouse_zone VARCHAR(20),
    IN p_notes TEXT,
    IN p_device_id VARCHAR(50)
)
BEGIN
    DECLARE v_status ENUM('released', 'pending', 'rejected', 'in_process');
    DECLARE v_product_name VARCHAR(150);
    DECLARE v_lot_number VARCHAR(50);
    
    -- Obtener estatus de calidad actual
    SELECT quality_status, product_name, lot_number
    INTO v_status, v_product_name, v_lot_number
    FROM quality_validations
    WHERE box_id = p_box_id
    LIMIT 1;
    
    -- Si no existe en quality_validations, usar 'pending'
    IF v_status IS NULL THEN
        SET v_status = 'pending';
    END IF;
    
    -- Insertar registro
    INSERT INTO shipping_entries (
        box_id, quality_status, scanned_by, product_name, 
        lot_number, warehouse_zone, notes, device_id
    ) VALUES (
        p_box_id, v_status, p_scanned_by, v_product_name,
        v_lot_number, p_warehouse_zone, p_notes, p_device_id
    );
    
    -- Retornar el registro creado
    SELECT LAST_INSERT_ID() AS entry_id, v_status AS quality_status,
           v_product_name AS product_name, v_lot_number AS lot_number;
END //

DELIMITER ;

-- ═══════════════════════════════════════════════════════════════════════════
-- FIN DEL SCRIPT
-- ═══════════════════════════════════════════════════════════════════════════
