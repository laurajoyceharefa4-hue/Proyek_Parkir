
"""API penghubung Flutter dan XGBoost Parkir Pintar.

Jalankan:
python -m uvicorn flutter_api:app --reload --host 0.0.0.0 --port 8000
"""

import json
import sqlite3
from contextlib import closing
from datetime import datetime, timedelta, timezone
from functools import lru_cache
from pathlib import Path
from typing import Literal

import numpy as np
import pandas as pd
from fastapi import HTTPException, Query
from pydantic import BaseModel, Field

# Menggunakan FastAPI dan model yang sudah berhasil.
from main import (
    BASE_DIR,
    app,
    get_row,
    load_resources,
    predict_row,
    resources_or_503,
)


# ==========================================
# KONFIGURASI PENYIMPANAN RIWAYAT
# ==========================================

DB_PATH = BASE_DIR / "data" / "riwayat_demo.sqlite3"


class PrediksiFlutterRequest(BaseModel):
    horizon_menit: Literal[10, 20, 30]
    device_id: str = Field(min_length=1, max_length=100)
    nomor_baris: int | None = Field(
        default=None,
        ge=0,
    )
    waktu_target: datetime | None = None


# ==========================================
# STATUS PARKIR SESUAI MODEL FLUTTER
# ==========================================

def kategori(terisi: int, kapasitas: int) -> str:
    if kapasitas <= 0:
        raise HTTPException(
            status_code=422,
            detail="Kapasitas parkir tidak valid",
        )

    persen = terisi * 100 / kapasitas

    if persen >= 90:
        return "penuh"

    if persen >= 60:
        return "hampir_penuh"

    return "kosong"


def waktu_dasar(index: int):
    df, inputs, utc, local, models = get_row(index)

    if local is None or utc is None:
        raise HTTPException(
            status_code=503,
            detail="Timestamp dataset tidak tersedia",
        )

    return utc.iloc[index], local.iloc[index]


# ==========================================
# MENENTUKAN SAMPEL DATA HISTORIS
# ==========================================

def temukan_baris(req: PrediksiFlutterRequest) -> int:
    df, inputs, utc, local, models = resources_or_503()

    if req.nomor_baris is not None:
        if req.nomor_baris >= len(df):
            raise HTTPException(
                status_code=422,
                detail="nomor_baris di luar dataset",
            )

        if req.waktu_target is not None:
            raise HTTPException(
                status_code=422,
                detail=(
                    "Pilih salah satu: nomor_baris "
                    "atau waktu_target"
                ),
            )

        return req.nomor_baris

    if req.waktu_target is None:
        # Default demo: sampel historis terakhir.
        # BUKAN waktu nyata saat ini.
        return len(df) - 1

    if (
        req.waktu_target.tzinfo is None
        or req.waktu_target.utcoffset() is None
    ):
        raise HTTPException(
            status_code=422,
            detail=(
                "waktu_target wajib memiliki zona waktu. "
                "Contoh: 2024-09-26T21:20:00+02:00"
            ),
        )

    if utc is None:
        raise HTTPException(
            status_code=503,
            detail="Timestamp dataset tidak tersedia",
        )

    # waktu_target merupakan waktu prediksi.
    # Input model berasal dari waktu sebelumnya.
    dasar = (
        req.waktu_target.astimezone(timezone.utc)
        - timedelta(minutes=req.horizon_menit)
    )

    cocok = np.flatnonzero(
        (utc == pd.Timestamp(dasar)).to_numpy()
    )

    if len(cocok) != 1:
        raise HTTPException(
            status_code=404,
            detail=(
                "Waktu target tidak ada pada data testing "
                "historis. Pilih tanggal dan jam tersedia."
            ),
        )

    return int(cocok[0])


# ==========================================
# METRIK MODEL ASLI DARI DATA TESTING
# ==========================================

@lru_cache(maxsize=1)
def metrik_testing():
    df, inputs, utc, local, models = load_resources()

    hasil = {}

    for horizon, model in models.items():
        target = f"target_{horizon}m"

        if target not in df.columns:
            raise ValueError(
                f"Kolom target tidak ditemukan: {target}"
            )

        y = pd.to_numeric(
            df[target],
            errors="raise",
        ).to_numpy(dtype=float)

        yhat = np.asarray(
            model.predict(inputs),
            dtype=float,
        )

        if (
            not np.isfinite(y).all()
            or not np.isfinite(yhat).all()
        ):
            raise ValueError(
                "Target atau prediksi mengandung "
                "nilai tidak valid"
            )

        err = yhat - y

        mae = float(np.abs(err).mean())

        rmse = float(
            np.sqrt(np.mean(err ** 2))
        )

        denominator = float(
            np.sum((y - y.mean()) ** 2)
        )

        r2 = (
            float(
                1 - np.sum(err ** 2) / denominator
            )
            if denominator
            else None
        )

        hasil[horizon] = {
            "horizon_menit": horizon,
            "tipe_hari": "semua",
            "jumlah_data": len(y),
            "mae": round(mae, 6),
            "rmse": round(rmse, 6),
            "r2": (
                round(r2, 6)
                if r2 is not None
                else None
            ),
        }

    return hasil


# ==========================================
# DATABASE RIWAYAT SQLITE
# ==========================================

def db_connection():
    DB_PATH.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    conn = sqlite3.connect(
        DB_PATH,
        timeout=10,
    )

    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS riwayat (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            device_id TEXT NOT NULL,
            data_json TEXT NOT NULL
        )
        """
    )

    conn.commit()

    return conn


# ==========================================
# API 1: STATUS PARKIR UNTUK FLUTTER
# ==========================================

@app.get("/api/mobile/status")
def mobile_status(
    nomor_baris: int | None = Query(
        default=None,
        ge=0,
    )
):
    df, inputs, utc, local, models = (
        resources_or_503()
    )

    index = (
        len(df) - 1
        if nomor_baris is None
        else nomor_baris
    )

    get_row(index)

    row = inputs.iloc[index]

    tersedia = int(
        round(float(row["available_now"]))
    )

    terisi = int(
        round(float(row["occupied_now"]))
    )

    kapasitas = int(
        round(float(row["capacity_now"]))
    )

    _, waktu_lokal = waktu_dasar(index)

    return {
        "waktu": waktu_lokal.isoformat(),
        "kapasitas": kapasitas,
        "terisi": terisi,
        "slot_tersedia": tersedia,
        "status": kategori(terisi, kapasitas),
        "mode": "demo_historis",
        "nomor_baris": index,
        "catatan": (
            "Data historis, bukan status parkir "
            "pada waktu sekarang"
        ),
    }


# ==========================================
# API 2: PREDIKSI XGBOOST UNTUK FLUTTER
# ==========================================

@app.post("/api/mobile/prediksi")
def mobile_prediksi(
    req: PrediksiFlutterRequest
):
    index = temukan_baris(req)

    sumber = predict_row(
        index,
        req.horizon_menit,
    )

    _, lokal = waktu_dasar(index)

    target = lokal + timedelta(
        minutes=req.horizon_menit
    )

    kapasitas = int(sumber["kapasitas"])

    tersedia = int(
        sumber["prediksi_slot_tampil"]
    )

    terisi = kapasitas - tersedia

    try:
        mae = metrik_testing()[
            req.horizon_menit
        ]["mae"]

    except (FileNotFoundError, ValueError) as exc:
        raise HTTPException(
            status_code=503,
            detail=str(exc),
        ) from exc

    # Nama kolom disesuaikan dengan
    # Prediksi.fromJson() milik Flutter.
    payload = {
        "model": "xgboost",
        "horizon_menit": req.horizon_menit,
        "waktu_target": target.isoformat(),
        "perkiraan_kendaraan": terisi,
        "kapasitas": kapasitas,
        "slot_tersedia": tersedia,
        "status": kategori(terisi, kapasitas),
        "mae_historis": mae,
        "keterangan": (
            "DEMO HISTORIS (bukan real-time). "
            "Waktu pengamatan: "
            + lokal.isoformat()
        ),
        "waktu": (
            datetime.now(
                timezone.utc
            ).isoformat()
        ),
        "device_id": req.device_id,
        "nomor_baris": index,
        "prediksi_slot_mentah": (
            sumber["prediksi_slot_mentah"]
        ),
        "aktual_slot_masa_depan": (
            sumber["aktual_slot_masa_depan"]
        ),
    }

    with closing(db_connection()) as con:
        with con:
            cursor = con.execute(
                """
                INSERT INTO riwayat (
                    device_id,
                    data_json
                )
                VALUES (?, ?)
                """,
                (
                    req.device_id,
                    json.dumps(payload),
                ),
            )

            payload["riwayat_id"] = (
                cursor.lastrowid
            )

    return payload


# ==========================================
# API 3: RIWAYAT PREDIKSI
# ==========================================

@app.get("/api/mobile/riwayat")
def mobile_riwayat(
    device_id: str = Query(min_length=1),
    semua_hp: bool = False,
    batas: int = Query(
        default=50,
        ge=1,
        le=200,
    ),
):
    if semua_hp:
        raise HTTPException(
            status_code=403,
            detail=(
                "Riwayat seluruh HP memerlukan "
                "autentikasi admin"
            ),
        )

    with closing(db_connection()) as con:
        rows = con.execute(
            """
            SELECT id, data_json
            FROM riwayat
            WHERE device_id = ?
            ORDER BY id DESC
            LIMIT ?
            """,
            (device_id, batas),
        ).fetchall()

    return [
        {
            "riwayat_id": rid,
            **json.loads(raw),
        }
        for rid, raw in rows
    ]


# ==========================================
# API 4: DETAIL RIWAYAT
# ==========================================

@app.get("/api/mobile/riwayat/{riwayat_id}")
def mobile_riwayat_detail(
    riwayat_id: int,
    device_id: str = Query(min_length=1),
):
    with closing(db_connection()) as con:
        row = con.execute(
            """
            SELECT data_json
            FROM riwayat
            WHERE id = ?
            AND device_id = ?
            """,
            (riwayat_id, device_id),
        ).fetchone()

    if row is None:
        raise HTTPException(
            status_code=404,
            detail="Riwayat tidak ditemukan",
        )

    return {
        "riwayat_id": riwayat_id,
        **json.loads(row[0]),
    }


# ==========================================
# API 5: EVALUASI MODEL
# ==========================================

@app.get("/api/mobile/evaluasi")
def mobile_evaluasi():
    try:
        hasil = metrik_testing()

    except (FileNotFoundError, ValueError) as exc:
        raise HTTPException(
            status_code=503,
            detail=str(exc),
        ) from exc

    return {
        "hasil": [
            hasil[h]
            for h in (10, 20, 30)
        ],
        "catatan": (
            "Evaluasi dataset testing historis, "
            "bukan hasil prediksi real-time"
        ),
    }


# ==========================================
# API 6: KONFIGURASI BACA SAJA
# ==========================================

@app.get("/api/mobile/konfigurasi")
def mobile_konfigurasi():
    df, inputs, utc, local, models = (
        resources_or_503()
    )

    kapasitas_tercatat = (
        inputs["capacity_now"].unique()
    )

    if len(kapasitas_tercatat) != 1:
        raise HTTPException(
            status_code=409,
            detail=(
                "Kapasitas berubah dalam dataset. "
                "Tidak ada satu nilai global."
            ),
        )

    return {
        "kapasitas": int(
            round(
                float(kapasitas_tercatat[0])
            )
        ),
        "ambang_hampir_penuh": 60,
        "ambang_penuh": 90,
        "mode": "konfigurasi_demo_readonly",
    }


# ==========================================
# API 7: GRAFIK TREN HISTORIS
# ==========================================

@app.get("/api/mobile/tren")
def mobile_tren():
    df, inputs, utc, local, models = (
        resources_or_503()
    )

    if local is None:
        raise HTTPException(
            status_code=503,
            detail="Waktu lokal tidak tersedia",
        )

    source = pd.DataFrame({
        "jam": local.dt.hour,
        "weekday": local.dt.dayofweek,
        "occupied": inputs["occupied_now"],
    })

    daily = source.groupby(
        "jam"
    )["occupied"].mean()

    weekly = source.groupby(
        "weekday"
    )["occupied"].mean()

    week_labels = [
        "Sen",
        "Sel",
        "Rab",
        "Kam",
        "Jum",
        "Sab",
        "Min",
    ]

    return {
        "harian": [
            {
                "label": f"{i:02d}",
                "rata_terisi": round(
                    float(daily[i]), 2
                ),
            }
            for i in range(24)
            if i in daily.index
        ],
        "mingguan": [
            {
                "label": week_labels[i],
                "rata_terisi": round(
                    float(weekly[i]), 2
                ),
            }
            for i in range(7)
            if i in weekly.index
        ],
        "catatan": (
            "Ringkasan deskriptif hanya dari "
            "data testing historis"
        ),
    }


# ==========================================
# API 8: REKOMENDASI JAM HISTORIS
# ==========================================

@app.get("/api/mobile/rekomendasi")
def mobile_rekomendasi():
    df, inputs, utc, local, models = (
        resources_or_503()
    )

    if local is None:
        raise HTTPException(
            status_code=503,
            detail="Waktu lokal tidak tersedia",
        )

    source = pd.DataFrame({
        "jam": local.dt.hour,
        "occupied": inputs["occupied_now"],
    })

    grouped = source.groupby(
        "jam"
    )["occupied"].agg([
        "mean",
        "count",
    ])

    terkecil = grouped.sort_values(
        "mean",
        ascending=True,
    ).head(3)

    terbesar = grouped.sort_values(
        "mean",
        ascending=False,
    ).head(3)

    def points(frame):
        return [
            {
                "jam": int(i),
                "rata_terisi": round(
                    float(row["mean"]), 2
                ),
            }
            for i, row in frame.iterrows()
        ]

    return {
        "tersepi": points(terkecil),
        "teramai": points(terbesar),
        "catatan": (
            "Berdasarkan rata-rata data testing "
            "historis yang terbatas. "
            "Bukan prediksi AI atau jaminan slot."
        ),
    }
