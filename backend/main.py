
"""Backend Parkir Pintar - XGBoost Historical Prediction."""

from datetime import date
from functools import lru_cache
from pathlib import Path
from typing import Literal

import numpy as np
import pandas as pd
import xgboost as xgb

from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel, Field


# ======================================
# LOKASI FILE
# ======================================

BASE_DIR = Path(__file__).resolve().parent
DATA_PATH = BASE_DIR / "data" / "Frauenfeld_Test.csv"
MODEL_DIR = BASE_DIR / "models"

MODEL_PATHS = {
    10: MODEL_DIR / "XGBoost_target_10m.json",
    20: MODEL_DIR / "XGBoost_target_20m.json",
    30: MODEL_DIR / "XGBoost_target_30m.json",
}


# ======================================
# FITUR ASLI MODEL XGBOOST
# ======================================

FEATURES = [
    "available_now",
    "occupied_now",
    "capacity_now",
    "lag_10m",
    "lag_20m",
    "lag_30m",
    "lag_60m",
    "lag_120m",
    "rolling_mean_30m",
    "rolling_mean_60m",
    "change_10m",
    "hour_sin",
    "hour_cos",
    "dow_sin",
    "dow_cos",
    "is_weekend",
]


# ======================================
# FASTAPI
# ======================================

app = FastAPI(
    title="Parkir Pintar API",
    description=(
        "Prediksi XGBoost berdasarkan data historis "
        "Frauenfeld, bukan data real-time."
    ),
    version="0.3.0",
)


class PrediksiSampelRequest(BaseModel):
    nomor_baris: int = Field(ge=0)
    horizon_menit: Literal[10, 20, 30]
    device_id: str = Field(
        default="demo",
        min_length=1,
        max_length=100,
    )


# ======================================
# MEMUAT DATASET DAN MODEL
# ======================================

@lru_cache(maxsize=1)
def load_resources():

    if not DATA_PATH.is_file():
        raise FileNotFoundError(
            f"Dataset tidak ditemukan: {DATA_PATH}"
        )

    df = pd.read_csv(DATA_PATH)

    if df.empty:
        raise ValueError("Dataset testing kosong")

    missing = [
        name
        for name in FEATURES
        if name not in df.columns
    ]

    if missing:
        raise ValueError(
            f"Kolom fitur tidak tersedia: {missing}"
        )

    inputs = df.loc[:, FEATURES].apply(
        pd.to_numeric,
        errors="coerce",
    )

    valid = np.isfinite(
        inputs.to_numpy(dtype=float)
    ).all(axis=1)

    if not valid.all():
        raise ValueError(
            f"Ada {int((~valid).sum())} baris "
            "dengan fitur tidak valid"
        )

    # Membaca timestamp asli dari Colab
    if "timestamp_utc" in df.columns:

        waktu_utc = pd.to_datetime(
            df["timestamp_utc"],
            utc=True,
            errors="coerce",
        )

    elif "timestamp_local" in df.columns:

        waktu_utc = pd.to_datetime(
            df["timestamp_local"],
            utc=True,
            errors="coerce",
        )

    else:
        waktu_utc = None

    if waktu_utc is not None:

        if waktu_utc.isna().any():
            raise ValueError(
                "Ada timestamp yang tidak dapat dibaca"
            )

        # Zona waktu asli lokasi parkir
        waktu_local = waktu_utc.dt.tz_convert(
            "Europe/Zurich"
        )

    else:
        waktu_local = None

    models = {}

    for horizon, path in MODEL_PATHS.items():

        if not path.is_file():
            raise FileNotFoundError(
                f"Model tidak ditemukan: {path.name}"
            )

        model = xgb.XGBRegressor()
        model.load_model(str(path))

        model_features = (
            model.get_booster().feature_names
        )

        if (
            model_features is not None
            and model_features != FEATURES
        ):
            raise ValueError(
                f"Urutan fitur model {horizon} "
                "menit tidak sesuai"
            )

        if int(model.n_features_in_) != len(FEATURES):
            raise ValueError(
                f"Model {horizon} menit "
                "tidak menerima 16 fitur"
            )

        models[horizon] = model

    return (
        df,
        inputs,
        waktu_utc,
        waktu_local,
        models,
    )


def resources_or_503():

    try:
        return load_resources()

    except (
        FileNotFoundError,
        ValueError,
        OSError,
        xgb.core.XGBoostError,
    ) as exc:

        raise HTTPException(
            status_code=503,
            detail=str(exc),
        ) from exc


def get_row(index: int):

    df, inputs, utc, local, models = resources_or_503()

    if not 0 <= index < len(df):
        raise HTTPException(
            status_code=422,
            detail=(
                f"nomor_baris harus 0 "
                f"sampai {len(df) - 1}"
            ),
        )

    return df, inputs, utc, local, models


def local_iso(waktu_local, index):

    if waktu_local is None:
        return None

    return waktu_local.iloc[index].isoformat()


def utc_iso(waktu_utc, index):

    if waktu_utc is None:
        return None

    return waktu_utc.iloc[index].isoformat()


def status_category(available, capacity):

    if capacity <= 0:
        return "tidak_diketahui"

    if available <= 0:
        return "penuh"

    if available / capacity <= 0.10:
        return "hampir_penuh"

    return "tersedia"


# ======================================
# PREDIKSI XGBOOST
# ======================================

def predict_row(index: int, horizon: int):

    df, inputs, utc, local, models = get_row(index)

    row = inputs.iloc[[index]]

    capacity = int(
        round(float(row["capacity_now"].iloc[0]))
    )

    available_now = int(
        round(float(row["available_now"].iloc[0]))
    )

    if capacity <= 0:
        raise HTTPException(
            status_code=422,
            detail="Kapasitas parkir tidak valid",
        )

    # Prediksi menggunakan model hasil Colab
    raw = float(
        models[horizon].predict(row)[0]
    )

    if not np.isfinite(raw):
        raise HTTPException(
            status_code=500,
            detail="Hasil prediksi tidak valid",
        )

    predicted = int(
        np.clip(np.rint(raw), 0, capacity)
    )

    col_target = f"target_{horizon}m"

    actual = None
    error = None

    if (
        col_target in df.columns
        and pd.notna(df.iloc[index][col_target])
    ):

        actual = float(
            df.iloc[index][col_target]
        )

        error = abs(raw - actual)

    return {
        "mode": "demo_historis",
        "nomor_baris": index,
        "horizon_menit": horizon,
        "waktu_pengamatan": local_iso(local, index),
        "waktu_utc": utc_iso(utc, index),
        "zona_waktu": "Europe/Zurich",
        "slot_sekarang": available_now,
        "kapasitas": capacity,
        "prediksi_slot_mentah": round(raw, 6),
        "prediksi_slot_tampil": predicted,
        "prediksi_terisi": capacity - predicted,
        "status": status_category(
            predicted,
            capacity,
        ),
        "aktual_slot_masa_depan": actual,
        "kesalahan_absolut": (
            None
            if error is None
            else round(error, 6)
        ),
        "keterangan": (
            "Prediksi XGBoost dari data historis, "
            "bukan kondisi real-time"
        ),
    }


# ======================================
# HEALTH CHECK
# ======================================

@app.get("/health")
def health():

    return {
        "status": "ok",
        "pesan": "FastAPI berjalan",
        "mode": "demo_historis",
    }


# ======================================
# KESIAPAN DATASET DAN MODEL
# ======================================

@app.get("/api/kesiapan")
def kesiapan():

    files = {
        DATA_PATH.name: DATA_PATH.is_file()
    }

    files.update({
        path.name: path.is_file()
        for path in MODEL_PATHS.values()
    })

    result = {
        "berkas": files,
        "semua_berkas_ada": all(files.values()),
    }

    if not result["semua_berkas_ada"]:
        result["model_terbaca"] = False
        return result

    try:

        df, inputs, utc, local, models = (
            load_resources()
        )

        result.update({
            "model_terbaca": True,
            "jumlah_sampel": len(df),
            "jumlah_fitur": len(inputs.columns),
            "memiliki_timestamp": local is not None,
            "zona_waktu": (
                "Europe/Zurich"
                if local is not None
                else None
            ),
            "waktu_awal": (
                local.iloc[0].isoformat()
                if local is not None
                else None
            ),
            "waktu_akhir": (
                local.iloc[-1].isoformat()
                if local is not None
                else None
            ),
        })

    except Exception as exc:

        result.update({
            "model_terbaca": False,
            "galat": str(exc),
        })

    return result


# ======================================
# CONTOH DATASET
# ======================================

@app.get("/api/contoh")
def contoh(
    jumlah: int = Query(5, ge=1, le=20)
):

    df, inputs, utc, local, models = (
        resources_or_503()
    )

    return {
        "jumlah_sampel": len(df),
        "baris_contoh": [
            {
                "nomor_baris": i,
                "waktu_pengamatan": local_iso(
                    local, i
                ),
                "slot_sekarang": int(
                    round(
                        float(
                            inputs.iloc[i]["available_now"]
                        )
                    )
                ),
                "kapasitas": int(
                    round(
                        float(
                            inputs.iloc[i]["capacity_now"]
                        )
                    )
                ),
            }
            for i in range(min(jumlah, len(df)))
        ],
    }


# ======================================
# STATUS PARKIR
# ======================================

@app.get("/api/status")
def status(
    nomor_baris: int = Query(0, ge=0)
):

    df, inputs, utc, local, models = (
        get_row(nomor_baris)
    )

    row = inputs.iloc[nomor_baris]

    capacity = int(
        round(float(row["capacity_now"]))
    )

    available = int(
        round(float(row["available_now"]))
    )

    occupied = int(
        round(float(row["occupied_now"]))
    )

    return {
        "mode": "demo_historis",
        "nomor_baris": nomor_baris,
        "waktu_pengamatan": local_iso(
            local,
            nomor_baris,
        ),
        "zona_waktu": "Europe/Zurich",
        "kapasitas": capacity,
        "terisi": occupied,
        "slot_tersedia": available,
        "status": status_category(
            available,
            capacity,
        ),
    }


# ======================================
# DAFTAR TANGGAL TERSEDIA
# ======================================

@app.get("/api/tanggal-tersedia")
def tanggal_tersedia():

    df, inputs, utc, local, models = (
        resources_or_503()
    )

    if local is None:
        raise HTTPException(
            status_code=503,
            detail="Timestamp tidak tersedia",
        )

    dates = sorted(
        set(
            local.dt.strftime(
                "%Y-%m-%d"
            ).tolist()
        )
    )

    return {
        "mode": "demo_historis",
        "zona_waktu": "Europe/Zurich",
        "tanggal": dates,
    }


# ======================================
# DAFTAR JAM PADA TANGGAL TERTENTU
# ======================================

@app.get("/api/waktu-tersedia")
def waktu_tersedia(
    tanggal: date
):

    df, inputs, utc, local, models = (
        resources_or_503()
    )

    if local is None:
        raise HTTPException(
            status_code=503,
            detail="Timestamp tidak tersedia",
        )

    mask = local.dt.date == tanggal

    indices = np.flatnonzero(
        mask.to_numpy()
    ).tolist()

    return {
        "tanggal": tanggal.isoformat(),
        "zona_waktu": "Europe/Zurich",
        "jumlah": len(indices),
        "pilihan": [
            {
                "nomor_baris": i,
                "jam": local.iloc[i].strftime(
                    "%H:%M"
                ),
                "waktu_pengamatan": (
                    local.iloc[i].isoformat()
                ),
            }
            for i in indices
        ],
    }


# ======================================
# PREDIKSI SATU HORIZON
# ======================================

@app.post("/api/prediksi/sampel")
def prediksi_sampel(
    request: PrediksiSampelRequest
):

    return predict_row(
        request.nomor_baris,
        request.horizon_menit,
    )


# ======================================
# PREDIKSI TIGA HORIZON
# ======================================

@app.get("/api/prediksi/semua")
def prediksi_semua(
    nomor_baris: int = Query(0, ge=0)
):

    return {
        "mode": "demo_historis",
        "nomor_baris": nomor_baris,
        "hasil": [
            predict_row(
                nomor_baris,
                horizon,
            )
            for horizon in (10, 20, 30)
        ],
    }


# ======================================
# PREDIKSI BERDASARKAN TANGGAL DAN JAM
# ======================================

@app.get("/api/prediksi/pada-waktu")
def prediksi_pada_waktu(
    tanggal: date,
    jam: str = Query(
        pattern=r"^([01][0-9]|2[0-3]):[0-5][0-9]$"
    ),
):

    df, inputs, utc, local, models = (
        resources_or_503()
    )

    if local is None:
        raise HTTPException(
            status_code=503,
            detail="Timestamp tidak tersedia",
        )

    selected = (
        (local.dt.date == tanggal)
        &
        (local.dt.strftime("%H:%M") == jam)
    )

    indices = np.flatnonzero(
        selected.to_numpy()
    )

    if len(indices) == 0:
        raise HTTPException(
            status_code=404,
            detail=(
                "Tidak ada sampel pada tanggal "
                "dan jam tersebut"
            ),
        )

    if len(indices) > 1:
        raise HTTPException(
            status_code=409,
            detail=(
                "Waktu ambigu, gunakan nomor_baris "
                "dari /api/waktu-tersedia"
            ),
        )

    index = int(indices[0])

    return {
        "mode": "demo_historis",
        "nomor_baris": index,
        "hasil": [
            predict_row(index, horizon)
            for horizon in (10, 20, 30)
        ],
    }


# ======================================
# VALIDASI MODEL XGBOOST
# ======================================

@app.get("/api/validasi-model")
def validasi_model():

    df, inputs, utc, local, models = (
        resources_or_503()
    )

    hasil = []

    for horizon, model in models.items():

        col = f"target_{horizon}m"

        if col not in df.columns:
            hasil.append({
                "horizon_menit": horizon,
                "galat": (
                    f"Kolom {col} tidak ada"
                ),
            })
            continue

        actual = pd.to_numeric(
            df[col],
            errors="coerce",
        )

        if actual.isna().any():
            hasil.append({
                "horizon_menit": horizon,
                "galat": "Target kosong",
            })
            continue

        predicted = model.predict(
            inputs
        ).astype(float)

        mae = float(
            np.mean(
                np.abs(
                    actual.to_numpy(dtype=float)
                    - predicted
                )
            )
        )

        hasil.append({
            "horizon_menit": horizon,
            "jumlah_data": len(df),
            "mae": round(mae, 6),
        })

    return {
        "mode": "evaluasi_data_testing",
        "hasil": hasil,
    }
