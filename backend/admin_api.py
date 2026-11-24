
"""
Parkir Pintar - Backend Admin
========================================
Login admin, autentikasi token,
kelola akun admin, dan SQLite.

Backend XGBoost tetap di flutter_api.py.

Jalankan:
python -m uvicorn admin_api:app --host 0.0.0.0 --port 8001
"""

from __future__ import annotations

import hashlib
import hmac
import os
import re
import secrets
import sqlite3

from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Iterator

from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import (
    HTTPAuthorizationCredentials,
    HTTPBearer,
)
from pydantic import BaseModel, Field

from flutter_api import app


# =========================================
# KONFIGURASI
# =========================================

BASE_DIR = Path(__file__).resolve().parent
DB_PATH = BASE_DIR / "data" / "admin_demo.sqlite3"

TOKEN_VALID_HOURS = 12
HASH_ITERATIONS = 260_000

router = APIRouter(
    prefix="/api/admin",
    tags=["Admin Demo"],
)

bearer = HTTPBearer(auto_error=False)


# =========================================
# MODEL REQUEST
# =========================================

class LoginBody(BaseModel):
    username: str
    password: str


class TambahAdminBody(BaseModel):
    nama: str
    username: str
    password: str = Field(min_length=12)


class GantiPasswordBody(BaseModel):
    password_baru: str = Field(min_length=12)


class StatusAdminBody(BaseModel):
    aktif: bool


# =========================================
# DATABASE
# =========================================

@contextmanager
def database() -> Iterator[sqlite3.Connection]:
    DB_PATH.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    con = sqlite3.connect(
        DB_PATH,
        timeout=15,
    )

    con.row_factory = sqlite3.Row
    con.execute("PRAGMA foreign_keys=ON")

    try:
        yield con
        con.commit()
    except Exception:
        con.rollback()
        raise
    finally:
        con.close()


def now_utc() -> datetime:
    return datetime.now(timezone.utc)


# =========================================
# PASSWORD DAN TOKEN
# =========================================

def pass_hash(password: str, salt: str) -> str:
    result = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        bytes.fromhex(salt),
        HASH_ITERATIONS,
    )

    return result.hex()


def hash_token(token: str) -> str:
    return hashlib.sha256(
        token.encode("utf-8")
    ).hexdigest()


def public_admin(row: sqlite3.Row) -> dict:
    return {
        "id": int(row["id"]),
        "nama": str(row["nama"]),
        "username": str(row["username"]),
        "aktif": bool(row["aktif"]),
    }


def validate_username(username: str) -> str:
    normalized = username.strip().lower()

    valid = re.fullmatch(
        r"[a-z][a-z0-9_.-]{2,29}",
        normalized,
    )

    if not valid:
        raise HTTPException(
            status_code=422,
            detail=(
                "Username harus 3-30 karakter, "
                "dimulai huruf kecil."
            ),
        )

    return normalized


# =========================================
# MEMBUAT DATABASE DAN ADMIN PERTAMA
# =========================================

def prepare_database() -> None:
    with database() as con:
        con.executescript(
            """
            CREATE TABLE IF NOT EXISTS admins (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nama TEXT NOT NULL,
                username TEXT NOT NULL UNIQUE,
                salt TEXT NOT NULL,
                password_hash TEXT NOT NULL,
                role TEXT NOT NULL
                    CHECK(role IN ('superadmin', 'admin')),
                aktif INTEGER NOT NULL DEFAULT 1
                    CHECK(aktif IN (0, 1)),
                created_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS sessions (
                token_hash TEXT PRIMARY KEY,
                admin_id INTEGER NOT NULL
                    REFERENCES admins(id),
                expires_at TEXT NOT NULL,
                created_at TEXT NOT NULL
            );
            """
        )

        count = con.execute(
            "SELECT COUNT(*) FROM admins"
        ).fetchone()[0]

        if count != 0:
            return

        username = os.getenv(
            "PARKIR_ADMIN_USER", ""
        ).strip()

        password = os.getenv(
            "PARKIR_ADMIN_PASSWORD", ""
        )

        name = os.getenv(
            "PARKIR_ADMIN_NAME",
            "Pengelola Parkir",
        ).strip()

        if not username or not password:
            print(
                "[Admin] Akun belum dibuat. "
                "Isi PARKIR_ADMIN_USER dan "
                "PARKIR_ADMIN_PASSWORD."
            )
            return

        if len(password) < 12:
            raise RuntimeError(
                "Password admin minimal 12 karakter."
            )

        username = validate_username(username)
        salt = secrets.token_hex(16)

        con.execute(
            """
            INSERT INTO admins (
                nama,
                username,
                salt,
                password_hash,
                role,
                aktif,
                created_at
            )
            VALUES (?, ?, ?, ?, ?, 1, ?)
            """,
            (
                name,
                username,
                salt,
                pass_hash(password, salt),
                "superadmin",
                now_utc().isoformat(),
            ),
        )

        print(
            f"[Admin] Superadmin dibuat: {username}"
        )


# =========================================
# AUTENTIKASI
# =========================================

def current_admin(
    credentials: HTTPAuthorizationCredentials | None = Depends(
        bearer
    ),
) -> sqlite3.Row:

    if (
        credentials is None
        or credentials.scheme.lower() != "bearer"
    ):
        raise HTTPException(
            status_code=401,
            detail="Token admin diperlukan.",
        )

    with database() as con:
        row = con.execute(
            """
            SELECT a.*, s.expires_at
            FROM sessions s
            JOIN admins a ON a.id = s.admin_id
            WHERE s.token_hash = ?
            """,
            (
                hash_token(
                    credentials.credentials
                ),
            ),
        ).fetchone()

    if row is None or not row["aktif"]:
        raise HTTPException(
            status_code=401,
            detail="Sesi admin tidak valid.",
        )

    expired = datetime.fromisoformat(
        row["expires_at"]
    ) <= now_utc()

    if expired:
        raise HTTPException(
            status_code=401,
            detail="Sesi admin sudah berakhir.",
        )

    return row


def superadmin(
    admin: sqlite3.Row = Depends(current_admin),
) -> sqlite3.Row:

    if admin["role"] != "superadmin":
        raise HTTPException(
            status_code=403,
            detail="Hanya superadmin yang diizinkan.",
        )

    return admin


# =========================================
# LOGIN ADMIN
# =========================================

@router.post("/login")
def login(body: LoginBody) -> dict:
    username = body.username.strip().lower()

    with database() as con:
        row = con.execute(
            """
            SELECT *
            FROM admins
            WHERE username = ?
            """,
            (username,),
        ).fetchone()

        if row is None or not row["aktif"]:
            raise HTTPException(
                status_code=401,
                detail="Username atau password salah.",
            )

        digest = pass_hash(
            body.password,
            row["salt"],
        )

        if not hmac.compare_digest(
            digest,
            row["password_hash"],
        ):
            raise HTTPException(
                status_code=401,
                detail="Username atau password salah.",
            )

        token = secrets.token_urlsafe(40)

        created = now_utc()
        expires = created + timedelta(
            hours=TOKEN_VALID_HOURS
        )

        con.execute(
            """
            INSERT INTO sessions (
                token_hash,
                admin_id,
                expires_at,
                created_at
            )
            VALUES (?, ?, ?, ?)
            """,
            (
                hash_token(token),
                row["id"],
                expires.isoformat(),
                created.isoformat(),
            ),
        )

        return {
            "access_token": token,
            "token_type": "bearer",
            "admin": public_admin(row),
            "expires_at": expires.isoformat(),
        }


# =========================================
# PROFIL ADMIN
# =========================================

@router.get("/me")
def me(
    admin: sqlite3.Row = Depends(current_admin),
) -> dict:
    return public_admin(admin)


# =========================================
# LOGOUT ADMIN
# =========================================

@router.post("/logout")
def logout(
    credentials: HTTPAuthorizationCredentials | None = Depends(
        bearer
    ),
    admin: sqlite3.Row = Depends(current_admin),
) -> dict:
    assert credentials is not None

    with database() as con:
        con.execute(
            """
            DELETE FROM sessions
            WHERE token_hash = ?
            """,
            (
                hash_token(
                    credentials.credentials
                ),
            ),
        )

    return {"berhasil": True}


# =========================================
# DAFTAR ADMIN
# =========================================

@router.get("/admins")
def list_admins(
    _: sqlite3.Row = Depends(superadmin),
) -> list[dict]:

    with database() as con:
        rows = con.execute(
            """
            SELECT *
            FROM admins
            ORDER BY id
            """
        ).fetchall()

    return [
        public_admin(row)
        for row in rows
    ]


# =========================================
# TAMBAH ADMIN
# =========================================

@router.post("/admins", status_code=201)
def tambah_admin(
    body: TambahAdminBody,
    _: sqlite3.Row = Depends(superadmin),
) -> dict:

    username = validate_username(
        body.username
    )

    name = body.nama.strip()

    if len(name) < 3 or len(name) > 80:
        raise HTTPException(
            status_code=422,
            detail="Nama harus 3-80 karakter.",
        )

    salt = secrets.token_hex(16)

    with database() as con:
        try:
            cursor = con.execute(
                """
                INSERT INTO admins (
                    nama,
                    username,
                    salt,
                    password_hash,
                    role,
                    aktif,
                    created_at
                )
                VALUES (?, ?, ?, ?, ?, 1, ?)
                """,
                (
                    name,
                    username,
                    salt,
                    pass_hash(
                        body.password,
                        salt,
                    ),
                    "admin",
                    now_utc().isoformat(),
                ),
            )

        except sqlite3.IntegrityError:
            raise HTTPException(
                status_code=409,
                detail="Username sudah digunakan.",
            ) from None

        row = con.execute(
            """
            SELECT *
            FROM admins
            WHERE id = ?
            """,
            (cursor.lastrowid,),
        ).fetchone()

    return public_admin(row)


# =========================================
# GANTI PASSWORD ADMIN
# =========================================

@router.put("/admins/{admin_id}/password")
def ganti_password(
    admin_id: int,
    body: GantiPasswordBody,
    _: sqlite3.Row = Depends(superadmin),
) -> dict:

    salt = secrets.token_hex(16)

    with database() as con:
        target = con.execute(
            """
            SELECT *
            FROM admins
            WHERE id = ?
            """,
            (admin_id,),
        ).fetchone()

        if target is None:
            raise HTTPException(
                status_code=404,
                detail="Admin tidak ditemukan.",
            )

        con.execute(
            """
            UPDATE admins
            SET salt = ?, password_hash = ?
            WHERE id = ?
            """,
            (
                salt,
                pass_hash(
                    body.password_baru,
                    salt,
                ),
                admin_id,
            ),
        )

        # Semua sesi lama akun tersebut dibatalkan.
        con.execute(
            """
            DELETE FROM sessions
            WHERE admin_id = ?
            """,
            (admin_id,),
        )

        changed = con.execute(
            """
            SELECT *
            FROM admins
            WHERE id = ?
            """,
            (admin_id,),
        ).fetchone()

    return public_admin(changed)


# =========================================
# AKTIF / NONAKTIF ADMIN
# =========================================

@router.put("/admins/{admin_id}/aktif")
def set_aktif(
    admin_id: int,
    body: StatusAdminBody,
    admin: sqlite3.Row = Depends(superadmin),
) -> dict:

    with database() as con:
        target = con.execute(
            """
            SELECT *
            FROM admins
            WHERE id = ?
            """,
            (admin_id,),
        ).fetchone()

        if target is None:
            raise HTTPException(
                status_code=404,
                detail="Admin tidak ditemukan.",
            )

        if (
            admin_id == admin["id"]
            and not body.aktif
        ):
            raise HTTPException(
                status_code=400,
                detail=(
                    "Tidak boleh menonaktifkan "
                    "akun sendiri."
                ),
            )

        if (
            target["role"] == "superadmin"
            and not body.aktif
        ):
            raise HTTPException(
                status_code=400,
                detail=(
                    "Superadmin tidak boleh "
                    "dinonaktifkan."
                ),
            )

        con.execute(
            """
            UPDATE admins
            SET aktif = ?
            WHERE id = ?
            """,
            (
                int(body.aktif),
                admin_id,
            ),
        )

        if not body.aktif:
            con.execute(
                """
                DELETE FROM sessions
                WHERE admin_id = ?
                """,
                (admin_id,),
            )

        updated = con.execute(
            """
            SELECT *
            FROM admins
            WHERE id = ?
            """,
            (admin_id,),
        ).fetchone()

    return public_admin(updated)


# =========================================
# REGISTRASI ENDPOINT
# =========================================

prepare_database()

# Memakai aplikasi FastAPI yang sudah ada,
# sehingga endpoint XGBoost tetap tersedia.
app.include_router(router)
