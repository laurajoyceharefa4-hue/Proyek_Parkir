
"""
Parkir Pintar - Backend Final Historis

Fitur:
1. Pengaturan ambang status parkir.
2. Rekap statistik keterisian historis.
3. Audit konsistensi dataset.
4. Penanda hari penuh dan parsial.
5. Ekspor CSV.
6. Sinkronisasi status API mobile.

Jalankan:
python -m uvicorn final_api:app --host 0.0.0.0 --port 8001
"""

from __future__ import annotations

import csv
import io
import json
import math
import sqlite3

from collections import defaultdict
from dataclasses import dataclass
from datetime import date, datetime
from pathlib import Path
from statistics import mean
from typing import Any

from fastapi import (
    Depends,
    HTTPException,
    Query,
    Request,
)

from fastapi.responses import JSONResponse, Response
from pydantic import BaseModel, Field

from admin_api import (
    app,
    current_admin,
    database,
    now_utc,
    superadmin,
)


ROOT = Path(__file__).resolve().parent
TEST_CSV = ROOT / "data" / "Frauenfeld_Test.csv"

NAMA_HARI = (
    "Senin",
    "Selasa",
    "Rabu",
    "Kamis",
    "Jumat",
    "Sabtu",
    "Minggu",
)

# Dataset memiliki interval 10 menit.
SAMPEL_PER_HARI_PENUH = 144


# ==========================================
# 1. MODEL DATA HISTORIS
# ==========================================

@dataclass(frozen=True)
class Sampel:
    waktu: datetime
    kapasitas: int
    terisi: float
    tersedia: float
    lokasi: str

    @property
    def selisih(self) -> float:
        return self.kapasitas - (
            self.terisi + self.tersedia
        )


# ==========================================
# 2. MEMBACA DATASET TESTING
# ==========================================

def baca_sampel() -> list[Sampel]:
    if not TEST_CSV.is_file():
        raise HTTPException(
            status_code=503,
            detail=(
                f"Dataset tidak ditemukan: {TEST_CSV}"
            ),
        )

    rows: list[Sampel] = []

    try:
        with TEST_CSV.open(
            "r",
            encoding="utf-8-sig",
            newline="",
        ) as file:
            reader = csv.DictReader(file)

            required = {
                "timestamp_local",
                "capacity_now",
                "occupied_now",
                "available_now",
            }

            if not required.issubset(
                reader.fieldnames or []
            ):
                raise HTTPException(
                    status_code=503,
                    detail=(
                        "Kolom dataset testing "
                        "tidak lengkap."
                    ),
                )

            for line, record in enumerate(
                reader,
                start=2,
            ):
                try:
                    waktu = datetime.fromisoformat(
                        record["timestamp_local"].strip()
                    )

                    kapasitas_raw = float(
                        record["capacity_now"]
                    )

                    terisi = float(
                        record["occupied_now"]
                    )

                    tersedia = float(
                        record["available_now"]
                    )

                    values = (
                        kapasitas_raw,
                        terisi,
                        tersedia,
                    )

                    valid = (
                        waktu.tzinfo is not None
                        and all(
                            math.isfinite(n)
                            for n in values
                        )
                        and kapasitas_raw > 0
                        and kapasitas_raw.is_integer()
                        and terisi >= 0
                        and tersedia >= 0
                    )

                    if not valid:
                        raise ValueError(
                            "Nilai data tidak valid."
                        )

                    rows.append(
                        Sampel(
                            waktu=waktu,
                            kapasitas=int(
                                kapasitas_raw
                            ),
                            terisi=terisi,
                            tersedia=tersedia,
                            lokasi=(
                                record.get("site_name")
                                or "1 | Oberes Mätteli"
                            ).strip(),
                        )
                    )

                except (
                    ValueError,
                    TypeError,
                    KeyError,
                ) as exc:
                    raise HTTPException(
                        status_code=503,
                        detail=(
                            f"CSV tidak valid pada "
                            f"baris {line}: {exc}"
                        ),
                    ) from exc

    except OSError as exc:
        raise HTTPException(
            status_code=503,
            detail=f"Gagal membaca CSV: {exc}",
        ) from exc

    if not rows:
        raise HTTPException(
            status_code=503,
            detail="Dataset testing kosong.",
        )

    return rows


# ==========================================
# 3. KAPASITAS DATASET
# ==========================================

def kapasitas_dataset(
    rows: list[Sampel] | None = None,
) -> int:
    rows = (
        rows
        if rows is not None
        else baca_sampel()
    )

    capacities = {
        row.kapasitas
        for row in rows
    }

    if len(capacities) != 1:
        raise HTTPException(
            status_code=409,
            detail=(
                "Kapasitas dataset "
                "tidak seragam."
            ),
        )

    return capacities.pop()


# ==========================================
# 4. PERSIAPAN DATABASE PENGATURAN
# ==========================================

def siapkan_pengaturan() -> None:
    with database() as con:
        con.execute(
            """
            CREATE TABLE IF NOT EXISTS
            pengaturan_parkir (
                id INTEGER PRIMARY KEY
                    CHECK(id = 1),

                ambang_hampir_penuh
                    INTEGER NOT NULL,

                ambang_penuh
                    INTEGER NOT NULL,

                diubah_pada TEXT NOT NULL,
                diubah_oleh INTEGER
            )
            """
        )

        con.execute(
            """
            INSERT OR IGNORE INTO
            pengaturan_parkir (
                id,
                ambang_hampir_penuh,
                ambang_penuh,
                diubah_pada,
                diubah_oleh
            )
            VALUES (1, 60, 90, ?, NULL)
            """,
            (now_utc().isoformat(),),
        )


# ==========================================
# 5. AMBIL PENGATURAN
# ==========================================

def ambil_pengaturan() -> dict[str, int]:
    with database() as con:
        row = con.execute(
            """
            SELECT
                ambang_hampir_penuh,
                ambang_penuh
            FROM pengaturan_parkir
            WHERE id = 1
            """
        ).fetchone()

    if row is None:
        raise HTTPException(
            status_code=503,
            detail="Pengaturan belum tersedia.",
        )

    return {
        "kapasitas": kapasitas_dataset(),
        "ambang_hampir_penuh": int(
            row["ambang_hampir_penuh"]
        ),
        "ambang_penuh": int(
            row["ambang_penuh"]
        ),
    }


class PengaturanBaru(BaseModel):
    kapasitas: int = Field(gt=0)

    ambang_hampir_penuh: int = Field(
        ge=1,
        le=99,
    )

    ambang_penuh: int = Field(
        ge=2,
        le=100,
    )


# ==========================================
# 6. GET PENGATURAN ADMIN
# ==========================================

@app.get(
    "/api/admin/konfigurasi",
    tags=["Pengaturan Parkir"],
)
def get_config_admin(
    _: sqlite3.Row = Depends(current_admin),
) -> dict[str, int]:
    return ambil_pengaturan()


# ==========================================
# 7. PUT PENGATURAN ADMIN
# ==========================================

@app.put(
    "/api/admin/konfigurasi",
    tags=["Pengaturan Parkir"],
)
def put_config_admin(
    body: PengaturanBaru,
    admin: sqlite3.Row = Depends(superadmin),
) -> dict[str, int]:

    if (
        body.kapasitas
        != kapasitas_dataset()
    ):
        raise HTTPException(
            status_code=422,
            detail=(
                "Kapasitas dikunci sesuai "
                "dataset historis."
            ),
        )

    if (
        body.ambang_hampir_penuh
        >= body.ambang_penuh
    ):
        raise HTTPException(
            status_code=422,
            detail=(
                "Ambang hampir penuh harus "
                "lebih kecil dari ambang penuh."
            ),
        )

    with database() as con:
        con.execute(
            """
            UPDATE pengaturan_parkir
            SET
                ambang_hampir_penuh = ?,
                ambang_penuh = ?,
                diubah_pada = ?,
                diubah_oleh = ?
            WHERE id = 1
            """,
            (
                body.ambang_hampir_penuh,
                body.ambang_penuh,
                now_utc().isoformat(),
                admin["id"],
            ),
        )

    return ambil_pengaturan()


# ==========================================
# 8. VALIDASI TANGGAL
# ==========================================

def parse_tanggal(
    value: str | None,
    field: str,
) -> date | None:

    if value is None or not value.strip():
        return None

    try:
        return date.fromisoformat(
            value.strip()
        )

    except ValueError as exc:
        raise HTTPException(
            status_code=422,
            detail=(
                f"{field} harus YYYY-MM-DD."
            ),
        ) from exc


def filter_periode(
    dari: str | None,
    sampai: str | None,
) -> tuple[list[Sampel], date, date]:

    all_rows = baca_sampel()

    start = (
        parse_tanggal(dari, "dari")
        or min(
            r.waktu.date()
            for r in all_rows
        )
    )

    end = (
        parse_tanggal(sampai, "sampai")
        or max(
            r.waktu.date()
            for r in all_rows
        )
    )

    if start > end:
        raise HTTPException(
            status_code=422,
            detail=(
                "Tanggal dari melebihi "
                "tanggal sampai."
            ),
        )

    result = [
        r
        for r in all_rows
        if start <= r.waktu.date() <= end
    ]

    if not result:
        raise HTTPException(
            status_code=404,
            detail=(
                "Tidak ada sampel pada "
                "periode tersebut."
            ),
        )

    return result, start, end


# ==========================================
# 9. PERHITUNGAN REKAP HISTORIS
# ==========================================

def ringkas(
    rows: list[Sampel],
    start: date,
    end: date,
) -> dict[str, Any]:

    per_jam = defaultdict(list)
    per_tanggal = defaultdict(list)
    per_hari = defaultdict(list)

    for row in rows:
        per_jam[row.waktu.hour].append(
            row.terisi
        )

        per_tanggal[
            row.waktu.date()
        ].append(row)

        per_hari[
            row.waktu.weekday()
        ].append(row.terisi)

    rata_jam = {
        jam: mean(values)
        for jam, values in per_jam.items()
    }

    jam_teramai = max(
        rata_jam,
        key=lambda jam: (
            rata_jam[jam],
            -jam,
        ),
    )

    jam_tersepi = min(
        rata_jam,
        key=lambda jam: (
            rata_jam[jam],
            jam,
        ),
    )

    # Hanya tanggal dengan 144 sampel
    # yang layak dipakai untuk ranking hari.
    hari_penuh = {
        tanggal: mean(
            row.terisi
            for row in daily_rows
        )
        for tanggal, daily_rows
        in per_tanggal.items()
        if len(daily_rows) == (
            SAMPEL_PER_HARI_PENUH
        )
    }

    if hari_penuh:
        tanggal_teramai = max(
            hari_penuh,
            key=lambda tanggal: (
                hari_penuh[tanggal],
                -tanggal.toordinal(),
            ),
        )

        tanggal_tersepi = min(
            hari_penuh,
            key=lambda tanggal: (
                hari_penuh[tanggal],
                tanggal.toordinal(),
            ),
        )

        nama_hari_teramai = NAMA_HARI[
            tanggal_teramai.weekday()
        ]

        nama_hari_tersepi = NAMA_HARI[
            tanggal_tersepi.weekday()
        ]

    else:
        nama_hari_teramai = None
        nama_hari_tersepi = None

    # Audit selisih:
    # kapasitas - (terisi + tersedia)
    tidak_konsisten = [
        row
        for row in rows
        if abs(row.selisih) > 0.001
    ]

    selisih_total = sum(
        row.selisih
        for row in tidak_konsisten
    )

    # Rekap utama
    return {
        "mode": "demo_historis",
        "sumber": TEST_CSV.name,
        "lokasi": rows[0].lokasi,

        "tanggal_dari": start.isoformat(),
        "tanggal_sampai": end.isoformat(),

        "zona_waktu": "Europe/Zurich",

        "jumlah_sampel": len(rows),

        "kapasitas": kapasitas_dataset(
            rows
        ),

        "rata_terisi": round(
            mean(
                row.terisi
                for row in rows
            ),
            3,
        ),

        "rata_tersedia": round(
            mean(
                row.tersedia
                for row in rows
            ),
            3,
        ),

        "rata_persen_terisi": round(
            mean(
                100 * row.terisi
                / row.kapasitas
                for row in rows
            ),
            3,
        ),

        "minimum_terisi": min(
            row.terisi
            for row in rows
        ),

        "maksimum_terisi": max(
            row.terisi
            for row in rows
        ),

        "jam_teramai": jam_teramai,
        "jam_tersepi": jam_tersepi,

        "hari_teramai": nama_hari_teramai,
        "hari_tersepi": nama_hari_tersepi,

        "rata_terisi_per_jam": [
            {
                "jam": jam,
                "rata_terisi": round(
                    rata_jam[jam],
                    3,
                ),
                "jumlah_sampel": len(
                    per_jam[jam]
                ),
            }
            for jam in sorted(per_jam)
        ],

        "rata_terisi_per_hari": [
            {
                "hari": NAMA_HARI[day],

                "rata_terisi": round(
                    mean(per_hari[day]),
                    3,
                ),

                "jumlah_sampel": len(
                    per_hari[day]
                ),

                "layak_dibandingkan": all(
                    len(per_tanggal[tanggal])
                    == SAMPEL_PER_HARI_PENUH
                    for tanggal in per_tanggal
                    if tanggal.weekday() == day
                ),
            }
            for day in sorted(per_hari)
        ],

        # Penanda hari yang lengkap/parsial
        "cakupan_harian": [
            {
                "tanggal": tanggal.isoformat(),
                "hari": NAMA_HARI[
                    tanggal.weekday()
                ],

                "jumlah_sampel": len(
                    daily_rows
                ),

                "hari_penuh": (
                    len(daily_rows)
                    == SAMPEL_PER_HARI_PENUH
                ),
            }
            for tanggal, daily_rows
            in sorted(per_tanggal.items())
        ],

        # Audit kualitas data
        "kualitas_data": {
            "baris_konsisten": (
                len(rows)
                - len(tidak_konsisten)
            ),

            "baris_tidak_konsisten": len(
                tidak_konsisten
            ),

            "persentase_tidak_konsisten": round(
                100
                * len(tidak_konsisten)
                / len(rows),
                3,
            ),

            "total_selisih_slot": round(
                selisih_total,
                3,
            ),

            "rata_selisih_slot": round(
                selisih_total / len(rows),
                3,
            ),

            "aturan": (
                "kapasitas = terisi + tersedia"
            ),

            "perlakuan": (
                "Data asli dipertahankan "
                "tanpa koreksi otomatis."
            ),
        },

        # Tidak tersedia dalam dataset
        "total_masuk": None,
        "per_jenis": None,
        "rata_lama_parkir_menit": None,

        "catatan": (
            "Statistik berasal dari snapshot "
            "keterisian, bukan transaksi kendaraan. "
            "Peringkat hari hanya berdasarkan hari "
            "dengan 144 sampel pada interval 10 menit."
        ),
    }


# ==========================================
# 10. PERIODE YANG TERSEDIA
# ==========================================

@app.get(
    "/api/admin/rekap/periode",
    tags=["Rekap Historis"],
)
def periode_tersedia(
    _: sqlite3.Row = Depends(current_admin),
) -> dict[str, Any]:

    rows = baca_sampel()

    return {
        "tanggal_awal": min(
            row.waktu.date()
            for row in rows
        ).isoformat(),

        "tanggal_akhir": max(
            row.waktu.date()
            for row in rows
        ).isoformat(),

        "jumlah_sampel": len(rows),

        "zona_waktu": "Europe/Zurich",
    }


# ==========================================
# 11. GET REKAP
# ==========================================

@app.get(
    "/api/admin/rekap",
    tags=["Rekap Historis"],
)
def get_rekap(
    dari: str | None = Query(None),
    sampai: str | None = Query(None),

    _: sqlite3.Row = Depends(current_admin),
) -> dict[str, Any]:

    rows, start, end = filter_periode(
        dari,
        sampai,
    )

    return ringkas(
        rows,
        start,
        end,
    )


# ==========================================
# 12. EXPORT CSV
# ==========================================

@app.get(
    "/api/admin/rekap/export.csv",
    tags=["Rekap Historis"],
)
def export_rekap(
    dari: str | None = Query(None),
    sampai: str | None = Query(None),

    _: sqlite3.Row = Depends(current_admin),
) -> Response:

    rows, start, end = filter_periode(
        dari,
        sampai,
    )

    output = io.StringIO()
    writer = csv.writer(output)

    writer.writerow([
        "timestamp_local",
        "lokasi",
        "capacity_now",
        "occupied_now",
        "available_now",
    ])

    for row in rows:
        writer.writerow([
            row.waktu.isoformat(),
            row.lokasi,
            row.kapasitas,
            row.terisi,
            row.tersedia,
        ])

    csv_data = (
        "\ufeff" + output.getvalue()
    ).encode("utf-8")

    return Response(
        content=csv_data,

        media_type=(
            "text/csv; charset=utf-8"
        ),

        headers={
            "Content-Disposition": (
                "attachment; filename="
                f'"rekap_parkir_{start}_{end}.csv"'
            )
        },
    )


# ==========================================
# 13. HITUNG STATUS KETERISIAN
# ==========================================

def tentukan_status(
    terisi: float,
    kapasitas: float,
    config: dict[str, int],
) -> str:

    persen = (
        100 * terisi / kapasitas
    )

    if persen >= config["ambang_penuh"]:
        return "penuh"

    if persen >= config["ambang_hampir_penuh"]:
        return "hampir_penuh"

    return "kosong"


def ganti_status(
    payload: Any,
    config: dict[str, int],
) -> Any:

    if isinstance(payload, list):
        return [
            ganti_status(item, config)
            for item in payload
        ]

    if isinstance(payload, dict):
        kapasitas = payload.get("kapasitas")

        terisi = payload.get(
            "perkiraan_kendaraan",
            payload.get("terisi"),
        )

        if (
            isinstance(
                kapasitas,
                (int, float),
            )
            and kapasitas > 0
            and isinstance(
                terisi,
                (int, float),
            )
        ):
            payload["status"] = tentukan_status(
                terisi,
                kapasitas,
                config,
            )

    return payload


# ==========================================
# 14. SINKRONISASI STATUS MOBILE
# ==========================================

@app.middleware("http")
async def pengaturan_mobile_terbaru(
    request: Request,
    call_next,
):
    path = request.url.path

    if (
        request.method == "GET"
        and path == "/api/mobile/konfigurasi"
    ):
        return JSONResponse(
            ambil_pengaturan()
        )

    response = await call_next(request)

    sesuaikan = (
        path == "/api/mobile/status"
        or path == "/api/mobile/prediksi"
        or path.startswith(
            "/api/mobile/riwayat"
        )
    )

    if (
        not sesuaikan
        or response.status_code != 200
    ):
        return response

    original = b"".join([
        chunk
        async for chunk in response.body_iterator
    ])

    try:
        payload = json.loads(original)

        return JSONResponse(
            ganti_status(
                payload,
                ambil_pengaturan(),
            )
        )

    except (
        json.JSONDecodeError,
        ValueError,
        TypeError,
    ):
        return Response(
            content=original,
            status_code=response.status_code,
            media_type="application/json",
        )


# ==========================================
# 15. SIAPKAN SQLITE
# ==========================================

siapkan_pengaturan()
