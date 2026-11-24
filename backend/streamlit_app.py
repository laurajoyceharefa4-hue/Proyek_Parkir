
from datetime import datetime, timedelta
from html import escape

import altair as alt
import pandas as pd
import requests
import streamlit as st


# ============================================================
# PARKIR PINTAR - STREAMLIT PRESENTASI
# ============================================================

API_DEFAULT = "http://127.0.0.1:8001"

START = datetime(2024, 9, 26, 21, 10)
END = datetime(2024, 10, 1, 1, 30)

TOTAL_SAMPLE = 603
DEVICE_ID = "streamlit-presentasi"

st.set_page_config(
    page_title="ParkirPintar | Presentasi",
    page_icon="🅿️",
    layout="wide",
)

defaults = {
    "page": "Beranda",
    "api_url": API_DEFAULT,
    "sample": 602,
    "horizon": 10,
    "prediction": None,
    "token": None,
    "admin": None,
    "admin_page": "Rekap Parkir",
}

if st.session_state.get("admin_page") == "Rekap & Evaluasi":
    st.session_state.admin_page = "Rekap Parkir"

for key, value in defaults.items():
    if key not in st.session_state:
        st.session_state[key] = value


# ============================================================
# CSS - WARNA DAN DESAIN APK
# ============================================================

CSS = """
<style>
:root {
    --red: #C4161C;
    --maroon: #4A0A0F;
    --pink: #FDF3F4;
    --soft: #FCE4E6;
    --line: #F0DADD;
    --muted: #7A6A6D;
    --ink: #1E1416;
}

.stApp {
    background: var(--pink);
    color: var(--ink);
}

.block-container {
    max-width: 1460px;
    padding-top: 1.1rem;
    padding-bottom: 3rem;
}

header[data-testid="stHeader"] {
    background: transparent;
}

#MainMenu {
    visibility: hidden;
}

footer {
    visibility: hidden;
}

h1, h2, h3, h4, p, label {
    color: var(--ink);
}

[data-testid="stWidgetLabel"] p {
    color: var(--ink) !important;
}

[data-testid="stMarkdownContainer"] p {
    color: var(--ink);
}

[data-testid="stTextInput"] input,
[data-testid="stNumberInput"] input,
[data-testid="stDateInput"] input,
[data-testid="stTimeInput"] input,
[data-baseweb="select"] > div {
    background: white !important;
    color: #1E1416 !important;
    border-radius: 13px !important;
}

[data-baseweb="input"] {
    background: white !important;
    color: #1E1416 !important;
    border-radius: 13px !important;
}

[data-baseweb="input"] input {
    color: #1E1416 !important;
}

[data-testid="stForm"] {
    background: white;
    border: 1px solid var(--line);
    border-radius: 24px;
    padding: 20px;
}

[data-testid="stRadio"] label p {
    color: var(--ink) !important;
}

[data-testid="stButton"] button,
[data-testid="stFormSubmitButton"] button,
[data-testid="stDownloadButton"] button {
    border-radius: 99px;
    min-height: 43px;
    border: 1px solid var(--line);
    background: white;
    color: var(--maroon);
    font-weight: 700;
}

[data-testid="stButton"] button[kind="primary"],
[data-testid="stFormSubmitButton"] button {
    background: var(--red);
    border-color: var(--red);
    color: white;
}

[data-testid="stButton"] button:hover {
    border-color: var(--red);
    color: var(--red);
}

[data-testid="stButton"] button[kind="primary"]:hover {
    color: white;
}

[data-testid="stMetric"] {
    border-radius: 17px;
    padding: 16px;
    background: white;
    border: 1px solid var(--line);
}

[data-testid="stMetricValue"] {
    color: var(--red);
}

[data-testid="stAlert"] {
    border-radius: 15px;
}

.brand {
    display: flex;
    align-items: center;
    gap: 14px;
    margin-bottom: 14px;
}

.brand-icon {
    width: 54px;
    height: 54px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 16px;
    background: linear-gradient(125deg, #E0252B, #B71017);
    color: white;
    font-size: 29px;
    font-weight: 900;
    box-shadow: 0 7px 15px #c4161c33;
}

.brand-name {
    font-size: 28px;
    font-weight: 900;
    letter-spacing: -.8px;
}

.brand-name b,
.heading b {
    color: var(--red);
}

.brand-sub {
    color: var(--muted);
    font-size: 13px;
}

.heading {
    font-size: 29px;
    font-weight: 900;
    letter-spacing: -.7px;
    margin-top: 13px;
}

.subheading {
    font-size: 14px;
    color: var(--muted);
    margin: 3px 0 14px;
}

.white-card {
    background: white;
    border-radius: 22px;
    padding: 21px 22px;
    margin: 9px 0 14px;
    border: 1px solid #f7e8e9;
    box-shadow: 0 5px 20px #4a0a0f0a;
}

.card-title {
    font-size: 17px;
    font-weight: 800;
    margin-bottom: 7px;
}

.note {
    font-size: 13px;
    color: var(--muted);
}

.notice {
    background: #FBE0E3;
    border-radius: 19px;
    padding: 15px 19px;
    color: #6B1118;
    font-size: 13px;
    margin: 11px 0 17px;
}

.hero {
    background:
        radial-gradient(
            circle at 97% 11%,
            #ffffff35 0 17%,
            transparent 17%
        ),
        radial-gradient(
            circle at 70% 106%,
            #ffffff26 0 23%,
            transparent 23%
        ),
        linear-gradient(
            125deg,
            #E0252B,
            #C4161C 52%,
            #9E0F14
        );

    border-radius: 24px;
    padding: 28px 29px;
    color: white;
    margin: 12px 0 17px;
    min-height: 240px;
    box-shadow: 0 10px 23px #c4161c23;
}

.hero-title {
    color: white;
    font-size: 16px;
    font-weight: 700;
}

.hero-date {
    color: #ffe9e9;
    font-size: 13px;
    margin-top: 5px;
}

.hero-big {
    color: white;
    font-size: 54px;
    font-weight: 900;
    line-height: 1.18;
    margin-top: 17px;
    letter-spacing: -1.7px;
}

.hero-big span {
    font-size: 16px;
    font-weight: 500;
    letter-spacing: 0;
}

.hero-chip {
    display: inline-block;
    background: white;
    color: #2a1718;
    padding: 8px 14px;
    border-radius: 40px;
    font-size: 13px;
    font-weight: 800;
    margin: 13px 0 14px;
}

.hero-track,
.track {
    height: 10px;
    background: #f7dce0;
    border-radius: 40px;
    overflow: hidden;
}

.hero-track {
    background: #850710;
}

.hero-fill {
    height: 100%;
    border-radius: 40px;
    background: white;
}

.hero-foot {
    display: flex;
    justify-content: space-between;
    color: #ffe3e4;
    font-size: 12px;
    margin-top: 9px;
}

.feature {
    background: white;
    border: 1px solid var(--line);
    border-radius: 19px;
    text-align: center;
    padding: 17px 6px;
    margin-bottom: 7px;
}

.feature-icon {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    background: #FCE4E6;
    color: #C4161C;
    border-radius: 50%;
    height: 42px;
    width: 42px;
    font-size: 22px;
}

.feature-title {
    font-size: 13px;
    color: var(--muted);
    margin-top: 9px;
}

.feature-value {
    font-size: 19px;
    font-weight: 850;
}

.feature-foot {
    font-size: 12px;
    color: var(--red);
    font-weight: 750;
    margin-top: 8px;
}

.status-green {
    display: inline-block;
    background: #E7F6EC;
    color: #238A51;
    padding: 5px 10px;
    border-radius: 30px;
    font-weight: 750;
    font-size: 12px;
}

.row-card {
    background: white;
    border-radius: 18px;
    padding: 15px 18px;
    margin: 8px 0;
    box-shadow: 0 3px 14px #4a0a0f0b;
}

.row-top {
    display: flex;
    justify-content: space-between;
    gap: 10px;
    align-items: center;
}

.row-label {
    font-weight: 800;
    font-size: 14px;
}

.progress-fill {
    background: #2E9E5B;
    height: 100%;
    border-radius: 30px;
}

.profile-hero {
    background:
        radial-gradient(
            circle at 92% 20%,
            #ffffff35 0 20%,
            transparent 20%
        ),
        linear-gradient(120deg, #E0252B, #9E0F14);

    color: white;
    border-radius: 25px;
    padding: 27px;
    margin: 10px 0 20px;
}

.profile-hero h2 {
    color: white;
    font-size: 25px;
    margin: 0 0 8px;
}

.kv {
    display: flex;
    justify-content: space-between;
    gap: 12px;
    padding: 10px 0;
    border-bottom: 1px solid var(--line);
    font-size: 14px;
}

.kv strong {
    color: #271719;
}

.login-panel {
    background: linear-gradient(
        140deg,
        #4A0A0F,
        #1D0205
    );

    border-radius: 26px;
    padding: 34px;
    color: white;
}

.login-panel h2,
.login-panel p {
    color: white;
}

.st-key-main_nav [data-testid="stButton"] button {
    min-height: 46px;
}
</style>
"""

st.html(CSS)


# ============================================================
# FUNGSI BANTU
# ============================================================

def h(value):
    return escape(str(value))


def fmt(value, decimals=0):
    if value is None:
        return "—"

    try:
        text = f"{float(value):,.{decimals}f}"

        return (
            text.replace(",", "_")
            .replace(".", ",")
            .replace("_", ".")
        )

    except (TypeError, ValueError):
        return h(value)


def get(data, *keys):
    if not isinstance(data, dict):
        return None

    for key in keys:
        if data.get(key) is not None:
            return data[key]

    return None


def val(data, *keys):
    try:
        item = get(data, *keys)

        if item is None or isinstance(item, bool):
            return None

        return float(item)

    except (TypeError, ValueError):
        return None


def groups(data, keys):
    if isinstance(data, list):
        return data

    if isinstance(data, dict):
        for key in keys:
            if isinstance(data.get(key), list):
                return data[key]

        for value in data.values():
            if isinstance(value, dict):
                result = groups(value, keys)

                if result:
                    return result

    return []


def when(value):
    if not value:
        return "—"

    try:
        dt = datetime.fromisoformat(
            str(value).replace("Z", "+00:00")
        )

        return (
            dt.strftime("%d/%m/%Y, %H.%M")
            + " Swiss"
        )

    except ValueError:
        return str(value)


def status_name(code):
    text = (
        str(code or "")
        .lower()
        .replace(" ", "_")
    )

    return {
        "kosong": "Masih Lega",
        "tersedia": "Masih Lega",
        "lega": "Masih Lega",
        "hampir_penuh": "Hampir Penuh",
        "penuh": "Penuh",
    }.get(text, "Status belum tersedia")


def snapshot(data, prediction=False):
    capacity = val(
        data,
        "kapasitas",
        "capacity_now",
        "capacity",
    )

    if prediction:
        available = val(
            data,
            "prediksi_slot",
            "prediksi_slot_bulat",
            "prediksi_slot_tersedia",
            "slot_tersedia",
            "prediksi_slot_mentah",
        )

        occupied = val(
            data,
            "perkiraan_kendaraan",
            "prediksi_terisi",
        )

    else:
        available = val(
            data,
            "slot_tersedia",
            "available_now",
            "tersedia",
        )

        occupied = val(
            data,
            "terisi",
            "occupied_now",
            "slot_terisi",
        )

    if (
        occupied is None
        and capacity is not None
        and available is not None
    ):
        occupied = capacity - available

    if (
        available is None
        and capacity is not None
        and occupied is not None
    ):
        available = capacity - occupied

    return capacity, available, occupied


def page_title(first, second="", subtitle=""):
    st.html(
        f"""
        <div class="heading">
            {h(first)} <b>{h(second)}</b>
        </div>

        <div class="subheading">
            {h(subtitle)}
        </div>
        """
    )


def card(title, body):
    st.html(
        f"""
        <div class="white-card">
            <div class="card-title">
                {h(title)}
            </div>

            {body}
        </div>
        """
    )


def kv(label, value):
    return (
        '<div class="kv">'
        f'<span>{h(label)}</span>'
        f'<strong>{h(value)}</strong>'
        '</div>'
    )


def track(occupied, capacity, red=False):
    percentage = 0

    if capacity and occupied is not None:
        percentage = max(
            0,
            min(100, 100 * occupied / capacity),
        )

    color = "#9E0F14" if red else "#2E9E5B"

    return f"""
    <div class="track">
        <div style="
            height:100%;
            width:{percentage:.2f}%;
            background:{color};
            border-radius:40px;
        "></div>
    </div>
    """


def hero(data, title="Status Pengamatan Historis", prediction=False):
    capacity, available, occupied = snapshot(
        data,
        prediction,
    )

    timestamp = get(
        data,
        "waktu_target",
        "waktu_pengamatan",
        "waktu",
        "timestamp",
    )

    if not timestamp and not prediction:
        timestamp = (
            START
            + timedelta(
                minutes=10 * st.session_state.sample
            )
        ).isoformat()

    status = status_name(
        get(data, "status")
    )

    percentage = 0

    if capacity and occupied is not None:
        percentage = max(
            0,
            min(100, 100 * occupied / capacity),
        )

    st.html(
        f"""
        <div class="hero">
            <div class="hero-title">
                {h(title)}
            </div>

            <div class="hero-date">
                {h(when(timestamp))}
            </div>

            <div class="hero-big">
                {fmt(available)}
                <span>
                    slot kosong dari {fmt(capacity)}
                </span>
            </div>

            <div class="hero-chip">
                ✓ {h(status)}
            </div>

            <div class="hero-track">
                <div
                    class="hero-fill"
                    style="width:{percentage:.2f}%"
                ></div>
            </div>

            <div class="hero-foot">
                <span>
                    {fmt(occupied)}
                    dari {fmt(capacity)} terisi
                </span>

                <span>
                    Kapasitas {fmt(capacity)}
                </span>
            </div>
        </div>
        """
    )


def switch(page):
    st.session_state.page = page
    st.rerun()


# ============================================================
# KONEKSI FASTAPI
# ============================================================

def request(
    method,
    path,
    *,
    params=None,
    payload=None,
    auth=False,
    want_bytes=False,
):
    headers = {
        "Accept": (
            "text/csv"
            if want_bytes
            else "application/json"
        )
    }

    if auth:
        token = st.session_state.token

        if not token:
            return (
                None,
                "Silakan login sebagai admin terlebih dahulu.",
            )

        headers["Authorization"] = (
            "Bearer " + token
        )

    try:
        response = requests.request(
            method,
            st.session_state.api_url.rstrip("/")
            + path,
            headers=headers,
            params=params,
            json=payload,
            timeout=25,
        )

        if not response.ok:
            try:
                detail = response.json()

                if isinstance(detail, dict):
                    detail = detail.get(
                        "detail",
                        response.text[:180],
                    )

            except ValueError:
                detail = response.text[:180]

            return (
                None,
                f"HTTP {response.status_code}: {detail}",
            )

        if want_bytes:
            return response.content, None

        if not response.content:
            return {}, None

        return response.json(), None

    except (
        requests.RequestException,
        ValueError,
    ) as error:
        return None, str(error)


# ============================================================
# MENDETEKSI ENDPOINT ADMIN DARI FASTAPI
# ============================================================

@st.cache_data(
    ttl=90,
    show_spinner=False,
)
def openapi_at(base_url):
    try:
        response = requests.get(
            base_url.rstrip("/")
            + "/openapi.json",
            timeout=6,
        )

        response.raise_for_status()

        return response.json().get(
            "paths",
            {},
        )

    except (
        requests.RequestException,
        ValueError,
    ):
        return {}


def endpoint(
    method,
    exact=(),
    keyword=(),
    exclude=(),
):
    paths = openapi_at(
        st.session_state.api_url
    )

    for path in exact:
        if method.lower() in paths.get(path, {}):
            return path

    matches = []

    for path, operations in paths.items():
        if method.lower() not in operations:
            continue

        name = path.lower()

        if (
            all(word in name for word in keyword)
            and not any(
                word in name
                for word in exclude
            )
        ):
            matches.append(path)

    if not matches:
        return None

    return sorted(
        matches,
        key=lambda path: (
            path.count("{"),
            len(path),
        ),
    )[0]


def admin_endpoint(kind, method="get"):
    definitions = {
        "login": (
            [
                "/api/admin/login",
                "/api/admin/auth/login",
                "/api/auth/login",
                "/auth/login",
            ],
            ["login"],
            [],
        ),
        "rekap": (
            ["/api/admin/rekap"],
            ["rekap"],
            ["export"],
        ),
        "setting": (
            [
                "/api/admin/konfigurasi",
                "/api/admin/pengaturan",
            ],
            ["konfigurasi"],
            ["mobile"],
        ),
        "admins": (
            [
                "/api/admin/admins",
                "/api/admin/kelola-admin",
                "/api/admin/users",
                "/api/admin/admin",
            ],
            ["admin"],
            [
                "login",
                "logout",
                "rekap",
                "konfigurasi",
                "export",
                "password",
                "auth",
                "{",
                "session",
            ],
        ),
        "export": (
            [
                "/api/admin/rekap/export.csv",
                "/api/admin/rekap/export",
            ],
            ["export"],
            [],
        ),
    }

    exact, keywords, excludes = definitions[kind]

    return endpoint(
        method,
        exact,
        keywords,
        excludes,
    )


# ============================================================
# DATA EVALUASI XGBOOST
# ============================================================

def forecast_metrics():
    return pd.DataFrame(
        [
            {
                "Horizon": "10 menit",
                "MAE": 2.522484,
                "RMSE": 3.500312,
                "R²": 0.996200,
            },
            {
                "Horizon": "20 menit",
                "MAE": 3.612115,
                "RMSE": 4.867533,
                "R²": 0.992671,
            },
            {
                "Horizon": "30 menit",
                "MAE": 4.323544,
                "RMSE": 5.774719,
                "R²": 0.989707,
            },
        ]
    )


# ============================================================
# TREN DAN GRAFIK
# ============================================================

def trend_rows(data, key):
    items = []

    if isinstance(data, dict):
        items = (
            groups(
                data.get(key),
                ["data", "items", "hasil"],
            )
            or groups(data, [key])
        )

    rows = []

    for index, item in enumerate(items):
        if not isinstance(item, dict):
            continue

        occupied = val(
            item,
            "rata_terisi",
            "rata_rata_terisi",
            "average_occupied",
            "nilai",
        )

        if occupied is None:
            continue

        label = get(
            item,
            "label",
            "jam",
            "hari",
            "tanggal",
            "waktu",
        )

        if (
            isinstance(label, (int, float))
            and key == "harian"
        ):
            label = f"{int(label):02d}.00"

        rows.append(
            {
                "urutan": index,
                "label": str(
                    label
                    if label is not None
                    else index
                ),
                "terisi": occupied,
            }
        )

    return pd.DataFrame(rows)


def trend_chart(dataframe, height=235):
    if dataframe.empty:
        st.info(
            "Grafik belum tersedia dari respons FastAPI."
        )
        return

    chart = alt.Chart(dataframe).encode(
        x=alt.X(
            "label:N",
            sort=list(dataframe["label"]),
            title=None,
            axis=alt.Axis(
                labelAngle=0,
                labelOverlap=True,
            ),
        ),
        y=alt.Y(
            "terisi:Q",
            title="Slot terisi",
            scale=alt.Scale(zero=True),
        ),
        tooltip=[
            "label:N",
            alt.Tooltip(
                "terisi:Q",
                format=".1f",
            ),
        ],
    )

    area = chart.mark_area(
        color="#FCE4E6",
        opacity=0.95,
    )

    line = chart.mark_line(
        color="#C4161C",
        strokeWidth=3,
        point=alt.OverlayMarkDef(
            color="#C4161C",
            filled=True,
            size=50,
        ),
    )

    st.altair_chart(
        (area + line).properties(
            height=height
        ),
        use_container_width=True,
    )


# ============================================================
# REKOMENDASI PARKIR
# ============================================================

def rec_rows(data, key):
    items = (
        groups(data, [key])
        if isinstance(data, dict)
        else []
    )

    rows = []

    for item in items:
        if not isinstance(item, dict):
            continue

        hour = val(
            item,
            "jam",
            "hour",
        )

        occupied = val(
            item,
            "rata_terisi",
            "rata_rata_terisi",
            "occupied",
        )

        if (
            hour is not None
            and occupied is not None
        ):
            rows.append(
                (
                    int(hour),
                    occupied,
                )
            )

    return rows


def rec_card(title, rows, busy=False):
    if not rows:
        st.info(
            f"{title}: data belum tersedia."
        )
        return

    content = ""

    for hour, occupied in rows[:3]:
        content += f"""
        <div class="row-card">
            <div class="row-top">
                <strong>
                    {hour:02d}.00
                </strong>

                <span>
                    {fmt(occupied)} / 185
                </span>
            </div>

            <div class="note">
                Rata-rata {fmt(occupied)}
                slot terisi
            </div>

            {track(occupied, 185, busy)}
        </div>
        """

    card(title, content)


# ============================================================
# HEADER DAN NAVIGASI
# ============================================================

st.html(
    """
    <div class="brand">
        <div class="brand-icon">P</div>

        <div>
            <div class="brand-name">
                Parkir<b>Pintar</b>
            </div>

            <div class="brand-sub">
                Prediksi & analisis ketersediaan parkir
                · Oberes Mätteli, Frauenfeld, Swiss
            </div>
        </div>
    </div>
    """
)

menu = [
    ("⌂ Beranda", "Beranda"),
    ("⌁ Tren", "Tren"),
    ("◷ Prediksi", "Prediksi"),
    ("↺ Riwayat", "Riwayat"),
    ("♙ Profil", "Profil"),
]

with st.container(key="main_nav"):
    columns = st.columns(
        5,
        gap="small",
    )

    for column, (label, page_name) in zip(
        columns,
        menu,
    ):
        with column:
            active = (
                st.session_state.page == page_name
                or (
                    page_name == "Prediksi"
                    and st.session_state.page == "Hasil"
                )
            )

            if st.button(
                label,
                use_container_width=True,
                type=(
                    "primary"
                    if active
                    else "secondary"
                ),
                key="nav_" + page_name,
            ):
                switch(page_name)


# ============================================================
# CEK FASTAPI
# ============================================================

health, health_error = request(
    "GET",
    "/health",
)

if health_error:
    st.error(
        "FastAPI belum terhubung: "
        + health_error
    )

    st.info(
        "Jalankan backend di port 8001. "
        "Jika IP berubah, gunakan Pengaturan Server."
    )

    if st.button("Pengaturan Server"):
        switch("Server")

    if st.session_state.page != "Server":
        st.stop()


page = st.session_state.page


# ============================================================
# HALAMAN BERANDA
# ============================================================

if page == "Beranda":
    st.html(
        """
        <div class="subheading">
            ● Selamat datang,
            <b>Pengguna Parkir</b>
        </div>
        """
    )

    page_title(
        "Status",
        "Parkir",
        "Lokasi: Oberes Mätteli, Frauenfeld, Swiss",
    )

    st.html(
        """
        <div class="notice">
            <b>◴ DEMO HISTORIS · Data 2024</b>
            <div>
                Bukan informasi ketersediaan
                slot parkir saat ini.
            </div>
        </div>
        """
    )

    left, middle, right = st.columns(
        [1.12, 1.12, 1],
        gap="medium",
    )

    # ------------------------------------
    # BERANDA - STATUS
    # ------------------------------------

    with left:
        status, error = request(
            "GET",
            "/api/mobile/status",
            params={
                "nomor_baris": 602,
            },
        )

        if error:
            st.error(
                "Status: " + error
            )

        else:
            hero(status)

        st.html(
            """
            <div class="card-title">
                Prediksi Parkir
            </div>

            <div class="note">
                Model XGBoost:
                10, 20, atau 30 menit.
            </div>
            """
        )

        cols = st.columns(
            3,
            gap="small",
        )

        for col, horizon in zip(
            cols,
            [10, 20, 30],
        ):
            with col:
                st.html(
                    f"""
                    <div class="feature">
                        <div class="feature-icon">
                            ◷
                        </div>

                        <div class="feature-title">
                            Prediksi
                        </div>

                        <div class="feature-value">
                            {horizon} menit
                        </div>

                        <div class="feature-foot">
                            XGBoost
                        </div>
                    </div>
                    """
                )

                if st.button(
                    "Pilih",
                    key=f"quick_{horizon}",
                    use_container_width=True,
                ):
                    st.session_state.horizon = horizon
                    switch("Prediksi")

    # ------------------------------------
    # BERANDA - TREN
    # ------------------------------------

    tren, tren_error = request(
        "GET",
        "/api/mobile/tren",
    )

    with middle:
        card(
            "Tren Parkir",
            '<div class="note">'
            'Pola keterisian dari data historis.'
            '</div>',
        )

        if tren_error:
            st.warning(
                "Tren: " + tren_error
            )

        else:
            dataframe = trend_rows(
                tren,
                "harian",
            )

            st.html(
                """
                <div class="card-title">
                    Rata-rata Terisi per Jam
                </div>
                """
            )

            trend_chart(
                dataframe,
                245,
            )

            if not dataframe.empty:
                highest = dataframe.loc[
                    dataframe.terisi.idxmax()
                ]

                lowest = dataframe.loc[
                    dataframe.terisi.idxmin()
                ]

                a, b, c = st.columns(3)

                a.metric(
                    "Puncak",
                    (
                        f"{highest['label']} · "
                        f"{fmt(highest['terisi'])}"
                    ),
                )

                b.metric(
                    "Tersepi",
                    (
                        f"{lowest['label']} · "
                        f"{fmt(lowest['terisi'])}"
                    ),
                )

                c.metric(
                    "Rata-rata",
                    fmt(
                        dataframe.terisi.mean(),
                        1,
                    ),
                )

        if st.button(
            "Lihat Tren Lengkap",
            use_container_width=True,
        ):
            switch("Tren")

    # ------------------------------------
    # BERANDA - REKOMENDASI
    # ------------------------------------

    with right:
        card(
            "Waktu Terbaik Parkir",
            '<div class="note">'
            'Pilih jam datang yang paling lega.'
            '</div>',
        )

        rekomendasi, error = request(
            "GET",
            "/api/mobile/rekomendasi",
        )

        if error:
            st.warning(
                "Rekomendasi: " + error
            )

        else:
            rec_card(
                "✅ Jam tersepi",
                rec_rows(
                    rekomendasi,
                    "tersepi",
                ),
            )

            rec_card(
                "⚠️ Jam teramai",
                rec_rows(
                    rekomendasi,
                    "teramai",
                ),
                busy=True,
            )

        if st.button(
            "Lihat Rekomendasi",
            use_container_width=True,
        ):
            switch("Rekomendasi")


# ============================================================
# HALAMAN TREN
# ============================================================

elif page == "Tren":
    page_title(
        "Tren",
        "Parkir",
        "Pola keterisian parkir dari data historis.",
    )

    tren, error = request(
        "GET",
        "/api/mobile/tren",
    )

    if error:
        st.error(error)

    else:
        mode = st.radio(
            "Periode",
            [
                "Harian",
                "Mingguan",
            ],
            horizontal=True,
        )

        key = (
            "harian"
            if mode == "Harian"
            else "mingguan"
        )

        dataframe = trend_rows(
            tren,
            key,
        )

        card(
            "Rata-rata Terisi per "
            + (
                "Jam"
                if mode == "Harian"
                else "Hari"
            ),
            '<div class="note">'
            'Berdasarkan data historis, '
            'bukan keadaan real-time.'
            '</div>',
        )

        trend_chart(
            dataframe,
            350,
        )

        if not dataframe.empty:
            highest = dataframe.loc[
                dataframe.terisi.idxmax()
            ]

            lowest = dataframe.loc[
                dataframe.terisi.idxmin()
            ]

            a, b, c = st.columns(3)

            a.metric(
                "Puncak",
                (
                    f"{highest['label']} · "
                    f"{fmt(highest['terisi'])}"
                ),
            )

            b.metric(
                "Tersepi",
                (
                    f"{lowest['label']} · "
                    f"{fmt(lowest['terisi'])}"
                ),
            )

            c.metric(
                "Rata-rata",
                fmt(
                    dataframe.terisi.mean(),
                    1,
                ),
            )

        if st.button(
            "Mau tahu waktu terbaik?",
            type="primary",
        ):
            switch("Rekomendasi")


# ============================================================
# HALAMAN REKOMENDASI
# ============================================================

elif page == "Rekomendasi":
    if st.button("← Kembali ke Tren"):
        switch("Tren")

    page_title(
        "Waktu",
        "Terbaik Parkir",
        "Pilih jam datang yang paling lega.",
    )

    rekomendasi, error = request(
        "GET",
        "/api/mobile/rekomendasi",
    )

    if error:
        st.error(error)

    else:
        a, b = st.columns(2)

        with a:
            rec_card(
                "✅ Jam tersepi",
                rec_rows(
                    rekomendasi,
                    "tersepi",
                ),
            )

        with b:
            rec_card(
                "⚠️ Jam teramai",
                rec_rows(
                    rekomendasi,
                    "teramai",
                ),
                busy=True,
            )

    st.caption(
        "Rekomendasi berdasarkan rata-rata "
        "data historis, bukan kondisi sekarang."
    )


# ============================================================
# HALAMAN PREDIKSI
# ============================================================

elif page == "Prediksi":
    page_title(
        "Prediksi",
        "Parkir",
        "Pilih waktu pengamatan dan horizon prediksi.",
    )

    st.html(
        """
        <div class="notice">
            <b>ⓘ MODE DEMO HISTORIS</b>

            <div>
                Prediksi menggunakan dataset Frauenfeld
                tahun 2024, bukan kondisi parkir sekarang.
                Waktu menggunakan zona Swiss.
            </div>
        </div>
        """
    )

    left, right = st.columns(
        [1.05, 1],
        gap="large",
    )

    with left:
        initial = START + timedelta(
            minutes=(
                st.session_state.sample * 10
            )
        )

        with st.form("prediction_form"):
            selected_date = st.date_input(
                "Tanggal pengamatan",
                value=initial.date(),
                min_value=START.date(),
                max_value=END.date(),
            )

            selected_time = st.time_input(
                "Jam pengamatan (Swiss)",
                value=initial.time(),
                step=600,
            )

            horizon = st.radio(
                "Horizon prediksi",
                [
                    10,
                    20,
                    30,
                ],
                horizontal=True,
                index=[10, 20, 30].index(
                    st.session_state.horizon
                ),
                format_func=lambda x: f"{x} menit",
            )

            st.caption(
                "XGBoost memperkirakan slot kosong "
                f"{horizon} menit setelah pengamatan."
            )

            submitted = st.form_submit_button(
                "✦ Lihat Prediksi",
                use_container_width=True,
            )

        selected = datetime.combine(
            selected_date,
            selected_time,
        )

        delta = (
            selected - START
        ).total_seconds()

        valid = (
            START <= selected <= END
            and delta % 600 == 0
        )

        if not valid:
            st.warning(
                "Pilih waktu testing antara "
                "26 September 2024 pukul 21.10 "
                "sampai 1 Oktober 2024 pukul 01.30, "
                "dengan interval 10 menit."
            )

        else:
            index = int(
                delta // 600
            )

            status, error = request(
                "GET",
                "/api/mobile/status",
                params={
                    "nomor_baris": index,
                },
            )

            if error:
                st.error(
                    "Kondisi pengamatan: "
                    + error
                )

            else:
                capacity, available, occupied = snapshot(
                    status
                )

                body = f"""
                <span class="status-green">
                    ✓ {h(status_name(get(status, "status")))}
                </span>

                <p>
                    <b>
                        {fmt(available)}
                        slot kosong dari
                        {fmt(capacity)} slot
                    </b>
                </p>

                <div class="note">
                    {fmt(occupied)}
                    slot terisi
                </div>

                {track(occupied, capacity)}
                """

                card(
                    "Kondisi pada pengamatan",
                    body,
                )

        if submitted:
            if not valid:
                st.error(
                    "Tanggal atau jam tidak valid."
                )

            else:
                payload = {
                    "horizon_menit": int(horizon),
                    "device_id": DEVICE_ID,
                    "nomor_baris": index,
                }

                with st.spinner(
                    "Menjalankan model XGBoost "
                    "melalui FastAPI..."
                ):
                    prediction, error = request(
                        "POST",
                        "/api/mobile/prediksi",
                        payload=payload,
                    )

                if error:
                    st.error(
                        "Prediksi gagal: " + error
                    )

                else:
                    st.session_state.prediction = (
                        prediction
                    )

                    st.session_state.sample = index
                    st.session_state.horizon = horizon

                    switch("Hasil")

    with right:
        card(
            "Apa yang Diuji?",
            """
            <div class="note">
                Kita memilih sebuah pengamatan pada
                tahun 2024, kemudian meminta model
                memprediksi jumlah slot tersedia
                10, 20, atau 30 menit setelahnya.

                <br><br>

                Nilai aktual pada data testing
                digunakan untuk evaluasi, bukan
                sebagai masukan masa depan.
            </div>
            """,
        )




# ============================================================
# HALAMAN HASIL PREDIKSI
# ============================================================

elif page == "Hasil":
    if st.button("← Kembali ke Prediksi"):
        switch("Prediksi")

    page_title(
        "Hasil",
        "Prediksi",
        "Perkiraan slot tersedia dari model XGBoost.",
    )

    prediction = st.session_state.prediction

    if not isinstance(prediction, dict):
        st.info(
            "Belum ada hasil. "
            "Buka halaman Prediksi terlebih dahulu."
        )

    else:
        a, b = st.columns(
            [1.05, 1],
        )

        with a:
            hero(
                prediction,
                (
                    "Perkiraan "
                    f"{st.session_state.horizon} "
                    "menit ke depan"
                ),
                prediction=True,
            )

            capacity, available, occupied = snapshot(
                prediction,
                prediction=True,
            )

            card(
                "Posisi Keterisian",
                (
                    track(
                        occupied,
                        capacity,
                    )
                    + '<div class="note" '
                    'style="margin-top:9px">'
                    f'{fmt(occupied)} dari '
                    f'{fmt(capacity)} slot terisi'
                    '</div>'
                ),
            )

        with b:
            horizon = st.session_state.horizon

            metrics = forecast_metrics().iloc[
                [10, 20, 30].index(horizon)
            ]

            mae = val(
                prediction,
                "mae_historis",
                "mae",
            )

            if mae is None:
                mae = metrics["MAE"]

            card(
                "Tentang Perkiraan Ini",
                f"""
                <div class="note">
                    Model XGBoost memiliki
                    MAE testing sekitar
                    <b>{fmt(mae, 2)} slot</b>.

                    <br><br>

                    Artinya rata-rata besar kesalahan
                    prediksi untuk horizon ini
                    pada data testing.

                    <br><br>

                    <b>
                        Ini estimasi, bukan jaminan.
                    </b>
                </div>
                """,
            )

            with st.expander(
                "Lihat respons FastAPI asli"
            ):
                st.json(prediction)

            if st.button(
                "Lihat Riwayat",
                use_container_width=True,
            ):
                switch("Riwayat")


# ============================================================
# HALAMAN RIWAYAT
# ============================================================

elif page == "Riwayat":
    page_title(
        "Riwayat",
        "Prediksi",
        "Riwayat prediksi dari dashboard presentasi.",
    )

    st.caption(
        "Riwayat HP memakai device_id berbeda, "
        "jadi isinya tidak harus sama."
    )

    selected = st.radio(
        "Filter horizon",
        [
            0,
            10,
            20,
            30,
        ],
        horizontal=True,
        format_func=lambda number: (
            "Semua"
            if number == 0
            else f"{number} menit"
        ),
    )

    data, error = request(
        "GET",
        "/api/mobile/riwayat",
        params={
            "device_id": DEVICE_ID,
        },
    )

    if error:
        st.error(error)

    else:
        items = groups(
            data,
            [
                "items",
                "riwayat",
                "data",
                "hasil",
            ],
        )

        filtered = [
            item
            for item in items
            if (
                isinstance(item, dict)
                and (
                    selected == 0
                    or val(
                        item,
                        "horizon_menit",
                    ) == selected
                )
            )
        ]

        st.caption(
            f"{len(filtered)} prediksi"
        )

        if not filtered:
            st.info(
                "Belum ada prediksi. "
                "Coba halaman Prediksi dahulu."
            )

        for item in filtered[:30]:
            horizon = val(
                item,
                "horizon_menit",
            )

            capacity, available, _ = snapshot(
                item,
                prediction=True,
            )

            timestamp = when(
                get(
                    item,
                    "waktu_target",
                    "waktu",
                    "timestamp",
                )
            )

            st.html(
                f"""
                <div class="row-card">
                    <div class="row-top">
                        <div>
                            <div class="row-label">
                                ◷ {h(timestamp)}
                            </div>

                            <div class="note">
                                Horizon {fmt(horizon)} menit
                                · {fmt(available)} slot tersedia
                                dari {fmt(capacity)}
                            </div>
                        </div>

                        <span class="status-green">
                            ✓ {h(status_name(get(item, "status")))}
                        </span>
                    </div>
                </div>
                """
            )


# ============================================================
# HALAMAN PROFIL
# ============================================================

elif page == "Profil":
    page_title(
        "",
        "Profil",
        "Info aplikasi dan akses pengelola.",
    )

    a, b = st.columns(
        [1.05, 1],
    )

    with a:
        st.html(
            """
            <div class="profile-hero">
                <h2>Ⓟ ParkirPintar</h2>

                <div style="color:white">
                    Versi 1.0.0
                </div>

                <p style="color:white">
                    Prediksi ketersediaan slot parkir
                    10, 20, dan 30 menit menggunakan
                    data historis.
                </p>

                <b>
                    Demo historis, bukan pemantauan
                    parkir real-time.
                </b>
            </div>
            """
        )

        card(
            "Tentang Aplikasi",
            (
                kv(
                    "Model prediksi",
                    "XGBoost",
                )
                + kv(
                    "Sumber data",
                    "Frauenfeld 2024",
                )
                + kv(
                    "Mode aplikasi",
                    "Historis",
                )
                + kv(
                    "Backend",
                    "FastAPI + SQLite",
                )
            ),
        )

    with b:
        card(
            "Akses Pengelola Parkir",
            """
            <div class="note">
                Login untuk membuka rekap,
                pengaturan parkir, dan pengelolaan admin.
            </div>
            """,
        )

        if st.session_state.token:
            if st.button(
                "Masuk Panel Admin",
                type="primary",
                use_container_width=True,
            ):
                switch("Admin")

        else:
            if st.button(
                "Masuk sebagai Admin",
                type="primary",
                use_container_width=True,
            ):
                switch("Login")

        if st.button(
            "Pengaturan Server",
            use_container_width=True,
        ):
            switch("Server")

        card(
            "Keterangan",
            """
            <div class="note">
                Prediksi menggunakan pengamatan
                historis tahun 2024,
                bukan kondisi saat ini.

                <br><br>

                Hasil AI adalah estimasi.
            </div>
            """,
        )


# ============================================================
# LOGIN ADMIN
# ============================================================

elif page == "Login":
    if st.button("← Kembali ke Profil"):
        switch("Profil")

    a, b, c = st.columns(
        [0.5, 1.05, 0.5]
    )

    with b:
        st.html(
            """
            <div class="login-panel">
                <h2>
                    Ⓟ Masuk sebagai Admin
                </h2>

                <p>
                    Khusus pengelola Parkir Pintar.
                </p>
            </div>
            """
        )

        with st.form("login_form"):
            username = st.text_input(
                "Username",
                value="admin",
            )

            password = st.text_input(
                "Password",
                type="password",
            )

            login = st.form_submit_button(
                "Masuk",
                use_container_width=True,
            )

        if login:
            path = admin_endpoint(
                "login",
                "post",
            )

            if not path:
                st.error(
                    "Endpoint login admin tidak ditemukan "
                    "di /openapi.json. Periksa /docs FastAPI."
                )

            else:
                spec = openapi_at(
                    st.session_state.api_url
                ).get(path, {}).get(
                    "post",
                    {},
                )

                content = (
                    spec.get(
                        "requestBody",
                        {},
                    ).get(
                        "content",
                        {},
                    )
                )

                if (
                    "application/x-www-form-urlencoded"
                    in content
                ):
                    try:
                        response = requests.post(
                            st.session_state.api_url.rstrip("/")
                            + path,
                            data={
                                "username": username,
                                "password": password,
                            },
                            timeout=20,
                        )

                        result = response.json()

                        error = (
                            None
                            if response.ok
                            else (
                                f"HTTP {response.status_code}: "
                                f"{result}"
                            )
                        )

                    except (
                        requests.RequestException,
                        ValueError,
                    ) as exc:
                        result = None
                        error = str(exc)

                else:
                    result, error = request(
                        "POST",
                        path,
                        payload={
                            "username": username,
                            "password": password,
                        },
                    )

                if error:
                    st.error(
                        "Login gagal: " + error
                    )

                elif (
                    isinstance(result, dict)
                    and get(
                        result,
                        "access_token",
                        "token",
                    )
                ):
                    st.session_state.token = str(
                        get(
                            result,
                            "access_token",
                            "token",
                        )
                    )

                    st.session_state.admin = (
                        get(
                            result,
                            "admin",
                            "user",
                        )
                        or {
                            "username": username,
                        }
                    )

                    switch("Admin")

                else:
                    st.error(
                        "Respons login tidak memuat token. "
                        "Periksa kontrak respons backend."
                    )

        if st.button(
            "Pengaturan Server",
            use_container_width=True,
        ):
            switch("Server")


# ============================================================
# PANEL ADMIN
# ============================================================

elif page == "Admin":
    if not st.session_state.token:
        st.warning(
            "Silakan login sebagai admin."
        )

        if st.button("Buka Login"):
            switch("Login")

    else:
        top, logout = st.columns(
            [4, 1],
        )

        with top:
            page_title(
                "Panel",
                "Admin Parkir Pintar",
                "Rekap historis, konfigurasi, dan akun.",
            )

        with logout:
            if st.button(
                "Keluar / Logout",
                use_container_width=True,
            ):
                st.session_state.token = None
                st.session_state.admin = None
                switch("Profil")

        admin_tab = st.radio(
            "Menu admin",
            [
                "Rekap Parkir",
                "Pengaturan Parkir",
                "Kelola Admin",
                "Pengaturan Server",
            ],
            horizontal=True,
            key="admin_page",
        )

        # ------------------------------------
        # ADMIN - REKAP DAN EVALUASI
        # ------------------------------------

        if admin_tab == "Rekap Parkir":
            a, b = st.columns(
                [1.28, 1],
                gap="large",
            )

            with a:
                period = st.date_input(
                    "Periode rekap (waktu Swiss)",
                    value=(
                        START.date(),
                        END.date(),
                    ),
                    min_value=START.date(),
                    max_value=END.date(),
                )

                if (
                    isinstance(period, tuple)
                    and len(period) == 2
                ):
                    first, last = period

                    params = {
                        "dari": first.isoformat(),
                        "sampai": last.isoformat(),
                    }

                    path = admin_endpoint(
                        "rekap",
                        "get",
                    )

                    if path:
                        result, error = request(
                            "GET",
                            path,
                            params=params,
                            auth=True,
                        )

                        if error:
                            st.error(
                                "Rekap: " + error
                            )

                        else:
                            total = val(
                                result,
                                "jumlah_sampel",
                                "total_pengamatan",
                            )

                            average = val(
                                result,
                                "rata_terisi",
                            )

                            capacity = val(
                                result,
                                "kapasitas",
                            )

                            st.html(
                                f"""
                                <div class="hero">
                                    <div class="hero-title">
                                        Rata-rata slot terisi
                                        per periode
                                    </div>

                                    <div class="hero-big">
                                        {fmt(average, 2)}
                                        <span>slot</span>
                                    </div>

                                    <div class="hero-foot">
                                        <span>
                                            {fmt(total)}
                                            pengamatan historis
                                        </span>

                                        <span>
                                            Kapasitas
                                            {fmt(capacity)} slot
                                        </span>
                                    </div>
                                </div>
                                """
                            )

                            statistics = (
                                kv(
                                    "Rata-rata slot tersedia",
                                    (
                                        fmt(
                                            val(
                                                result,
                                                "rata_tersedia",
                                            ),
                                            2,
                                        )
                                        + " slot"
                                    ),
                                )
                                + kv(
                                    "Rata-rata keterisian",
                                    (
                                        fmt(
                                            val(
                                                result,
                                                "rata_persen_terisi",
                                            ),
                                            2,
                                        )
                                        + "%"
                                    ),
                                )
                                + kv(
                                    "Jumlah pengamatan",
                                    fmt(total),
                                )
                            )

                            card(
                                "Statistik Keterisian",
                                statistics,
                            )

                            quality = get(
                                result,
                                "kualitas_data",
                            )

                            if isinstance(quality, dict):
                                card(
                                    "Audit Kualitas Data",
                                    (
                                        kv(
                                            "Baris konsisten",
                                            fmt(
                                                val(
                                                    quality,
                                                    "baris_konsisten",
                                                )
                                            ),
                                        )
                                        + kv(
                                            "Baris tidak konsisten",
                                            fmt(
                                                val(
                                                    quality,
                                                    "baris_tidak_konsisten",
                                                )
                                            ),
                                        )
                                        + kv(
                                            "Total selisih slot",
                                            fmt(
                                                val(
                                                    quality,
                                                    "total_selisih_slot",
                                                )
                                            ),
                                        )
                                    ),
                                )

                            hours = groups(
                                result,
                                [
                                    "rata_terisi_per_jam",
                                    "per_jam",
                                ],
                            )

                            if hours:
                                df_hours = trend_rows(
                                    {
                                        "harian": hours,
                                    },
                                    "harian",
                                )

                                st.html(
                                    """
                                    <div class="card-title">
                                        Rata-rata Terisi per Jam
                                    </div>
                                    """
                                )

                                trend_chart(df_hours)

                    else:
                        st.warning(
                            "Endpoint rekap admin tidak "
                            "ditemukan di /openapi.json."
                        )

                else:
                    st.info(
                        "Pilih tanggal awal dan akhir."
                    )

            with b:
                card(
                    "Ekspor Data Historis",
                    '<div class="note">'
                    'Pilih periode rekap di sebelah kiri, '
                    'lalu siapkan dan unduh file CSV.'
                    '</div>',
                )

                # ----------------------------
                # EKSPOR CSV
                # ----------------------------

                export_path = admin_endpoint(
                    "export",
                    "get",
                )

                if (
                    export_path
                    and isinstance(period, tuple)
                    and len(period) == 2
                ):
                    if st.button(
                        "Siapkan Unduhan CSV",
                        use_container_width=True,
                    ):
                        content, error = request(
                            "GET",
                            export_path,
                            params=params,
                            auth=True,
                            want_bytes=True,
                        )

                        if error:
                            st.error(
                                "Ekspor: " + error
                            )

                        else:
                            st.session_state["csv_ready"] = (
                                content,
                                first.isoformat(),
                                last.isoformat(),
                            )

                    prepared = st.session_state.get(
                        "csv_ready"
                    )

                    if prepared:
                        content, d1, d2 = prepared

                        st.download_button(
                            "Unduh CSV Historis",
                            content,
                            file_name=(
                                f"rekap_parkir_"
                                f"{d1}_{d2}.csv"
                            ),
                            mime="text/csv",
                            use_container_width=True,
                        )

                else:
                    st.info(
                        "Ekspor CSV tersedia jika "
                        "endpoint ekspor terdaftar "
                        "di FastAPI."
                    )

        # ------------------------------------
        # ADMIN - PENGATURAN PARKIR
        # ------------------------------------

        elif admin_tab == "Pengaturan Parkir":
            config, error = request(
                "GET",
                "/api/mobile/konfigurasi",
            )

            if error:
                st.error(error)

            else:
                capacity = int(
                    val(
                        config,
                        "kapasitas",
                    )
                    or 185
                )

                a, b = st.columns(
                    [1.1, 1],
                )

                with a:
                    card(
                        "Kapasitas Parkir",
                        kv(
                            "Kapasitas berdasarkan dataset",
                            f"{capacity} slot",
                        ),
                    )

                    near = int(
                        val(
                            config,
                            "ambang_hampir_penuh",
                        )
                        or 50
                    )

                    full = int(
                        val(
                            config,
                            "ambang_penuh",
                        )
                        or 85
                    )

                    with st.form("update_config"):
                        p_near = st.number_input(
                            "Ambang Hampir Penuh (%)",
                            min_value=1,
                            max_value=99,
                            value=near,
                        )

                        p_full = st.number_input(
                            "Ambang Penuh (%)",
                            min_value=1,
                            max_value=100,
                            value=full,
                        )

                        update = st.form_submit_button(
                            "Simpan Pengaturan",
                            use_container_width=True,
                        )

                    if update:
                        path = (
                            admin_endpoint(
                                "setting",
                                "put",
                            )
                            or admin_endpoint(
                                "setting",
                                "patch",
                            )
                        )

                        if p_near >= p_full:
                            st.error(
                                "Ambang hampir penuh harus "
                                "lebih kecil dari ambang penuh."
                            )

                        elif not path:
                            st.error(
                                "Endpoint perubahan konfigurasi "
                                "belum ditemukan. Periksa /docs."
                            )

                        else:
                            method = (
                                "PUT"
                                if endpoint(
                                    "put",
                                    exact=[path],
                                )
                                else "PATCH"
                            )

                            payload = {
                                "kapasitas": capacity,
                                "ambang_hampir_penuh": int(
                                    p_near
                                ),
                                "ambang_penuh": int(
                                    p_full
                                ),
                            }

                            _, error = request(
                                method,
                                path,
                                payload=payload,
                                auth=True,
                            )

                            if error:
                                st.error(
                                    "Tidak tersimpan: "
                                    + error
                                )

                            else:
                                st.success(
                                    "Konfigurasi berhasil "
                                    "disimpan di backend."
                                )

                with b:
                    card(
                        "Arti Ambang Parkir",
                        """
                        <div class="note">
                            Ambang dipakai sistem
                            untuk menentukan label
                            kondisi parkir.

                            <br><br>

                            Model XGBoost tetap
                            memprediksi jumlah slot.
                            Status ditentukan dari
                            hasil prediksi dan
                            konfigurasi parkir.
                        </div>
                        """,
                    )

        # ------------------------------------
        # ADMIN - KELOLA ADMIN
        # ------------------------------------

        elif admin_tab == "Kelola Admin":
            card(
                "Kelola Admin",
                """
                <div class="note">
                    Atur siapa yang bisa mengelola parkir.
                </div>
                """,
            )

            path = admin_endpoint(
                "admins",
                "get",
            )

            if path:
                admins, error = request(
                    "GET",
                    path,
                    auth=True,
                )

                if error:
                    st.error(error)

                else:
                    entries = groups(
                        admins,
                        [
                            "admins",
                            "items",
                            "data",
                            "hasil",
                            "users",
                        ],
                    )

                    active = sum(
                        1
                        for admin in entries
                        if (
                            isinstance(admin, dict)
                            and admin.get("aktif") is True
                        )
                    )

                    st.html(
                        f"""
                        <div class="hero">
                            <div class="hero-title">
                                Total admin
                            </div>

                            <div class="hero-big">
                                {len(entries)}
                                <span>admin</span>
                            </div>

                            <div class="hero-foot">
                                <span>
                                    {active} aktif
                                </span>
                            </div>
                        </div>
                        """
                    )

                    for admin in entries:
                        if not isinstance(admin, dict):
                            continue

                        name = (
                            get(
                                admin,
                                "nama",
                                "name",
                            )
                            or "Pengelola Parkir"
                        )

                        username = (
                            get(
                                admin,
                                "username",
                            )
                            or "—"
                        )

                        flag = (
                            "Aktif"
                            if admin.get("aktif")
                            else "Nonaktif"
                        )

                        card(
                            str(name),
                            (
                                '<div class="note">'
                                f'@{h(username)} · {h(flag)}'
                                '</div>'
                            ),
                        )

                    # ------------------------
                    # TAMBAH ADMIN
                    # ------------------------

                    with st.expander(
                        "Tambah Akun Admin"
                    ):
                        post_path = admin_endpoint(
                            "admins",
                            "post",
                        )

                        if not post_path:
                            st.info(
                                "Endpoint tambah admin belum "
                                "terdaftar di FastAPI. "
                                "Gunakan pengelolaan akun "
                                "melalui APK."
                            )

                        else:
                            with st.form(
                                "add_admin"
                            ):
                                new_name = st.text_input(
                                    "Nama pengelola"
                                )

                                new_user = st.text_input(
                                    "Username baru"
                                )

                                new_password = st.text_input(
                                    "Password baru",
                                    type="password",
                                )

                                submit = st.form_submit_button(
                                    "Buat Akun Admin"
                                )

                            if submit:
                                if not (
                                    new_name.strip()
                                    and new_user.strip()
                                    and new_password
                                ):
                                    st.error(
                                        "Lengkapi seluruh data."
                                    )

                                else:
                                    _, error = request(
                                        "POST",
                                        post_path,
                                        payload={
                                            "nama": new_name,
                                            "username": new_user,
                                            "password": new_password,
                                            "aktif": True,
                                        },
                                        auth=True,
                                    )

                                    if error:
                                        st.error(error)

                                    else:
                                        st.success(
                                            "Akun admin berhasil "
                                            "dibuat di backend."
                                        )

                                        st.rerun()

                    st.caption(
                        "Perubahan password dan status "
                        "admin memerlukan kecocokan "
                        "endpoint serta skema request "
                        "FastAPI. Fungsi tersebut tetap "
                        "bisa digunakan melalui APK."
                    )

            else:
                st.warning(
                    "Endpoint daftar admin belum ditemukan "
                    "di /openapi.json. "
                    "Periksa endpoint Kelola Admin "
                    "melalui /docs FastAPI."
                )

        # ------------------------------------
        # ADMIN - PENGATURAN SERVER
        # ------------------------------------

        elif admin_tab == "Pengaturan Server":
            st.text_input(
                "Alamat FastAPI",
                key="api_url",
            )

            if st.button(
                "Tes Koneksi",
                type="primary",
            ):
                _, error = request(
                    "GET",
                    "/health",
                )

                if error:
                    st.error(error)

                else:
                    st.success(
                        "FastAPI berhasil terhubung."
                    )

            st.caption(
                "Ubah alamat ini hanya jika "
                "backend berpindah IP atau port."
            )


# ============================================================
# PENGATURAN SERVER TANPA LOGIN
# ============================================================

elif page == "Server":
    page_title(
        "Pengaturan",
        "Server",
        "Sesuaikan alamat backend jika diperlukan.",
    )

    st.text_input(
        "Alamat FastAPI",
        key="api_url",
    )

    if st.button(
        "Tes Koneksi",
        type="primary",
    ):
        _, error = request(
            "GET",
            "/health",
        )

        if error:
            st.error(error)

        else:
            st.success(
                "FastAPI berhasil dihubungi."
            )

    if st.button(
        "← Kembali ke Profil"
    ):
        switch("Profil")


# ============================================================
# FOOTER
# ============================================================

st.html(
    """
    <div
        class="note"
        style="
            text-align:center;
            margin-top:25px;
        "
    >
        ParkirPintar · Demo historis tahun 2024
        <br>
        Flutter + FastAPI + XGBoost + Streamlit
    </div>
    """
)
