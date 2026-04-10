# API Backend MES - Módulo de Registro de Embarques

## Información General

| Campo | Valor |
|-------|-------|
| Base URL | `https://tu-backend-mes.azurewebsites.net/api` |
| Autenticación | Bearer Token (JWT) |
| Content-Type | `application/json` |

---

## Endpoints Requeridos

### 1. Autenticación

#### `POST /auth/login`

Autentica un operador y retorna un token JWT.

**Request:**
```json
{
  "username": "1247",
  "password": "contraseña"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "1247",
    "username": "1247",
    "full_name": "Operador 1247",
    "department": "Almacén de Embarques",
    "shift": "A"
  }
}
```

**Response (401 Unauthorized):**
```json
{
  "success": false,
  "message": "Usuario o contraseña incorrectos"
}
```

**Query SQL sugerida:**
```sql
SELECT id, full_name, department, shift 
FROM operators 
WHERE id = ? AND password_hash = ? AND is_active = TRUE;
```

---

#### `POST /auth/logout`

Invalida el token actual (opcional).

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Sesión cerrada correctamente"
}
```

---

### 2. Consulta de Calidad

#### `GET /quality/{boxId}`

Consulta el estatus de calidad de un Box ID.

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "box_id": "BOX-2026-001847",
  "product_name": "Componente electrónico A",
  "lot_number": "LOT-2026-0218A",
  "quality_status": "released",
  "validated_by": "1249",
  "validated_at": "2026-03-12T10:30:00Z",
  "rejection_reason": null
}
```

**Response (404 Not Found):**
```json
{
  "success": false,
  "message": "Box ID no encontrado en el sistema"
}
```

**Query SQL:**
```sql
SELECT box_id, product_name, lot_number, quality_status, 
       validated_by, validated_at, rejection_reason
FROM quality_validations
WHERE box_id = ?;
```

---

### 3. Registro de Embarques

#### `POST /shipping/entries`

Registra una nueva entrada de embarque.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "box_id": "BOX-2026-001850",
  "quality_status": "released",
  "scanned_by": "1247",
  "product_name": "Componente electrónico A",
  "lot_number": "LOT-2026-0218A",
  "warehouse_zone": "A1",
  "notes": "Sin observaciones",
  "device_id": "PDA-TC15-001",
  "scanned_at": "2026-03-12T14:32:00Z"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "id": 1234,
  "message": "Entrada registrada correctamente"
}
```

**Response (400 Bad Request):**
```json
{
  "success": false,
  "message": "El campo box_id es requerido"
}
```

**Query SQL:**
```sql
INSERT INTO shipping_entries 
  (box_id, quality_status, scanned_at, scanned_by, product_name, 
   lot_number, warehouse_zone, notes, device_id)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
```

---

#### `GET /shipping/entries`

Obtiene el historial de escaneos con filtros.

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `limit` | int | Máximo de registros (default: 50) |
| `offset` | int | Offset para paginación (default: 0) |
| `status` | string | Filtrar por estatus: `released`, `pending`, `rejected`, `in_process` |
| `search` | string | Buscar en box_id o product_name |
| `from_date` | ISO8601 | Fecha inicial |
| `to_date` | ISO8601 | Fecha final |

**Ejemplo:**
```
GET /shipping/entries?status=released&limit=20&offset=0
```

**Response (200 OK):**
```json
{
  "success": true,
  "total": 156,
  "entries": [
    {
      "id": 1234,
      "box_id": "BOX-2026-001847",
      "quality_status": "released",
      "scanned_at": "2026-03-12T14:32:00Z",
      "scanned_by": "1247",
      "product_name": "Componente electrónico A",
      "lot_number": "LOT-2026-0218A"
    }
  ]
}
```

**Query SQL:**
```sql
SELECT id, box_id, quality_status, scanned_at, scanned_by, 
       product_name, lot_number
FROM shipping_entries
WHERE 1=1
  AND (? IS NULL OR quality_status = ?)
  AND (? IS NULL OR box_id LIKE ? OR product_name LIKE ?)
  AND (? IS NULL OR scanned_at >= ?)
  AND (? IS NULL OR scanned_at <= ?)
ORDER BY scanned_at DESC
LIMIT ? OFFSET ?;
```

---

### 4. Estadísticas

#### `GET /shipping/stats/today`

Obtiene estadísticas del día actual.

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `date` | string | Fecha en formato YYYY-MM-DD (default: hoy) |

**Response (200 OK):**
```json
{
  "date": "2026-03-12",
  "total": 47,
  "released": 38,
  "pending": 5,
  "rejected": 2,
  "in_process": 2
}
```

**Query SQL:**
```sql
SELECT 
  COUNT(*) AS total,
  SUM(CASE WHEN quality_status = 'released' THEN 1 ELSE 0 END) AS released,
  SUM(CASE WHEN quality_status = 'pending' THEN 1 ELSE 0 END) AS pending,
  SUM(CASE WHEN quality_status = 'rejected' THEN 1 ELSE 0 END) AS rejected,
  SUM(CASE WHEN quality_status = 'in_process' THEN 1 ELSE 0 END) AS in_process
FROM shipping_entries
WHERE DATE(scanned_at) = ?;
```

---

## Códigos de Error HTTP

| Código | Significado |
|--------|-------------|
| 200 | OK - Solicitud exitosa |
| 201 | Created - Recurso creado |
| 400 | Bad Request - Datos inválidos |
| 401 | Unauthorized - Token inválido o expirado |
| 404 | Not Found - Recurso no encontrado |
| 500 | Internal Server Error - Error del servidor |

---

## Notas de Implementación

1. **JWT Token**: Usar una librería como `jsonwebtoken` (Node.js) o `System.IdentityModel.Tokens.Jwt` (.NET).

2. **Validación de Password**: Usar bcrypt para hashear passwords. Nunca almacenar en texto plano.

3. **CORS**: Configurar CORS para permitir requests desde la app Flutter:
   ```
   Access-Control-Allow-Origin: *
   Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
   Access-Control-Allow-Headers: Content-Type, Authorization
   ```

4. **Rate Limiting**: Considerar límites de requests por usuario/IP para prevenir abuso.

5. **Logging**: Registrar todas las operaciones de escaneo para auditoría.
