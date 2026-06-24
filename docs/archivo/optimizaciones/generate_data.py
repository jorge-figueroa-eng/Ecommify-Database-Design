#!/usr/bin/env python3
"""
generate_data.py - Generador de datos sintéticos a escala para la Actividad 4.

Objetivo
--------
Las semillas reales (postgresql/seed_data/*.csv) tienen ~200 filas: insuficiente
para que EXPLAIN ANALYZE elija planes con índices o para justificar
particionamiento (criterio >100.000 filas). Este script infla los hechos
transaccionales a ~1.000.000 de órdenes, MUESTREANDO de los CSV reales para
conservar distribuciones realistas (categorías, ciudades/estados, mezcla de
medios de pago, rangos de precio, puntajes de reseña).

Estrategia de memoria
----------------------
Las dimensiones (geo, categorías, productos, vendedores) caben en memoria. Los
hechos se escriben en UNA sola pasada: por cada orden se emiten en el mismo
ciclo sus ítems, pagos y reseña, de modo que nunca se mantiene 1M de filas en
RAM. Salida en CSV con cabecera, lista para `COPY ... WITH (FORMAT csv, HEADER)`.

Las columnas de tipos compuestos (address_br) se dejan en NULL: ninguna consulta
crítica las usa y evitan el escapado frágil en COPY. Sí se generan JSONB y
arrays porque alimentan los índices GIN de la Fase 2.

Uso
---
    python3 generate_data.py --orders 1000000 --out data
"""
import argparse
import csv
import json
import os
import random
from datetime import datetime, timedelta, timezone

SEED_DIR_DEFAULT = os.path.join(os.path.dirname(__file__), "..", "postgresql", "seed_data")

# Ancla temporal fija (= "hoy" del enunciado) para que las promociones activas y
# los rangos sean reproducibles entre corridas.
NOW_ANCHOR = datetime(2026, 6, 9, tzinfo=timezone.utc)

# Ventana real del dataset Olist.
DATE_START = datetime(2016, 9, 4, tzinfo=timezone.utc)
DATE_END = datetime(2018, 10, 17, tzinfo=timezone.utc)
RANGE_SECONDS = int((DATE_END - DATE_START).total_seconds())

# Mezcla de estados de orden (≈ distribución Olist). 'created' queda muy
# selectivo (0.5%) para lucir el índice PARCIAL de la Fase 2 (consulta Q7).
STATUS_WEIGHTS = [
    ("delivered", 0.940),
    ("shipped", 0.022),
    ("canceled", 0.012),
    ("unavailable", 0.008),
    ("invoiced", 0.006),
    ("processing", 0.005),
    ("approved", 0.002),
    ("created", 0.005),
]

PAYMENT_WEIGHTS = [
    ("credit_card", 0.740),
    ("boleto", 0.190),
    ("voucher", 0.050),
    ("debit_card", 0.015),
    ("not_defined", 0.005),
]

# Puntajes de reseña (≈ Olist: muy sesgado a 5 y 4).
REVIEW_SCORE_WEIGHTS = [(5, 0.57), (4, 0.19), (1, 0.13), (3, 0.08), (2, 0.03)]

SEARCH_VOCAB = [
    "technology", "home", "fashion", "sports", "beauty", "toys", "garden",
    "automotive", "books", "music", "kitchen", "office", "pet", "baby", "tools",
]
CHANNELS = ["web", "app_ios", "app_android", "marketplace"]


def rand_hex32():
    """ID de 32 hex como los de Olist (128 bits -> colisión despreciable)."""
    return "%032x" % random.getrandbits(128)


def weighted_pick(weights):
    r = random.random()
    acc = 0.0
    for value, w in weights:
        acc += w
        if r <= acc:
            return value
    return weights[-1][0]


def read_csv(path):
    with open(path, newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def load_pools(seed_dir):
    """Construye los conjuntos de muestreo desde los CSV reales."""
    pools = {}

    # --- geolocalización: zips únicos con lat/lng/ciudad/estado ---
    geo_rows = read_csv(os.path.join(seed_dir, "geolocation.csv"))
    geo = {}
    for r in geo_rows:
        zip_prefix = int(r["geolocation_zip_code_prefix"])
        if zip_prefix not in geo:
            geo[zip_prefix] = (
                r["geolocation_city"].strip(),
                r["geolocation_state"].strip(),
                float(r["geolocation_lat"]),
                float(r["geolocation_lng"]),
            )
    pools["geo"] = geo
    pools["zips"] = list(geo.keys())

    # --- categorías (orden estable -> category_id 1..N) ---
    cat_rows = read_csv(os.path.join(seed_dir, "categories.csv"))
    pools["categories"] = [
        (i + 1, r["product_category_name"], r.get("product_category_name_english") or None)
        for i, r in enumerate(cat_rows)
    ]

    # --- pool de precios/fletes reales ---
    item_rows = read_csv(os.path.join(seed_dir, "order_items.csv"))
    pools["prices"] = [(float(r["price"]), float(r["freight_value"])) for r in item_rows]

    # --- pool de dimensiones físicas de productos reales ---
    prod_rows = read_csv(os.path.join(seed_dir, "products.csv"))
    dims = []
    for r in prod_rows:
        def num(key):
            v = r.get(key)
            return float(v) if v not in (None, "", "NA") else None
        dims.append({
            "name_len": num("product_name_lenght"),
            "desc_len": num("product_description_lenght"),
            "photos": num("product_photos_qty"),
            "weight": num("product_weight_g"),
            "length": num("product_length_cm"),
            "height": num("product_height_cm"),
            "width": num("product_width_cm"),
            "category_name": r["product_category_name"],
        })
    pools["dims"] = dims

    return pools


def gen_dimensions(pools, n_customers, n_sellers, n_products, out, writers):
    """Genera geo, categorías, vendedores, productos y la lista de customer_ids."""
    geo = pools["geo"]
    zips = pools["zips"]
    cats = pools["categories"]
    dims = pools["dims"]

    # geo_locations
    w = writers["geo_locations"]
    w.writerow(["zip_code_prefix", "city", "state", "latitude", "longitude"])
    for zp, (city, state, lat, lng) in geo.items():
        w.writerow([zp, city, state, f"{lat:.7f}", f"{lng:.7f}"])

    # categories
    w = writers["categories"]
    w.writerow(["category_id", "name_pt", "name_en"])
    for cid, name_pt, name_en in cats:
        w.writerow([cid, name_pt, name_en if name_en else ""])

    # sellers
    w = writers["sellers"]
    w.writerow(["seller_id", "seller_zip_code_prefix", "seller_city", "seller_state", "capability_tags"])
    seller_ids = []
    for _ in range(n_sellers):
        sid = rand_hex32()
        seller_ids.append(sid)
        zp = random.choice(zips)
        city, state, _, _ = geo[zp]
        tags = random.sample(["fast_ship", "bulk", "fragile", "intl", "cold_chain"], k=random.randint(0, 2))
        w.writerow([sid, zp, city, state, "{" + ",".join(tags) + "}"])

    # products (con JSONB y arrays reales para los índices GIN de la Fase 2)
    w = writers["products"]
    w.writerow([
        "product_id", "category_id", "product_category_name", "product_name_length",
        "product_description_length", "product_photos_qty", "product_weight_g",
        "product_length_cm", "product_height_cm", "product_width_cm",
        "product_specifications", "search_tokens",
    ])
    product_ids = []
    for _ in range(n_products):
        pid = rand_hex32()
        product_ids.append(pid)
        cid, cat_pt, _ = random.choice(cats)
        d = random.choice(dims)
        weight = d["weight"]
        weight_class = "heavy" if (weight or 0) > 1000 else ("medium" if (weight or 0) > 300 else "light")
        specs = {
            "logistics": {"weight_class": weight_class, "fragile": random.random() < 0.1},
            "warranty_months": random.choice([0, 3, 6, 12, 24]),
        }
        tokens = random.sample(SEARCH_VOCAB, k=random.randint(1, 4))
        def i(v):
            return int(v) if v is not None else ""
        w.writerow([
            pid, cid, cat_pt, i(d["name_len"]), i(d["desc_len"]), i(d["photos"]),
            i(weight), i(d["length"]), i(d["height"]), i(d["width"]),
            json.dumps(specs, ensure_ascii=False), "{" + ",".join(tokens) + "}",
        ])

    # customers (1:1 con órdenes, faithful a Olist). customer_unique_id se
    # extrae de un pool MÁS PEQUEÑO -> personas con varias órdenes (consulta Q2).
    n_persons = max(1, int(n_customers * 0.62))
    person_pool = [rand_hex32() for _ in range(n_persons)]
    w = writers["customers"]
    w.writerow([
        "customer_id", "customer_unique_id", "customer_zip_code_prefix",
        "customer_city", "customer_state",
    ])
    customer_ids = []
    for _ in range(n_customers):
        cust_id = rand_hex32()
        customer_ids.append(cust_id)
        zp = random.choice(zips)
        city, state, _, _ = geo[zp]
        w.writerow([cust_id, random.choice(person_pool), zp, city, state])

    return seller_ids, product_ids, customer_ids


def gen_promotions(writers, product_ids, seller_ids, n_promos):
    """Una promoción por producto (la restricción EXCLUDE prohíbe solapes por
    producto). Un tercio queda ACTIVA en NOW_ANCHOR para la consulta Q6."""
    w = writers["product_promotions"]
    w.writerow(["product_id", "seller_id", "promotion_period", "discount_percentage"])
    chosen = random.sample(product_ids, min(n_promos, len(product_ids)))
    for idx, pid in enumerate(chosen):
        if idx % 3 == 0:
            # activa hoy
            lo = NOW_ANCHOR - timedelta(days=random.randint(1, 30))
            hi = NOW_ANCHOR + timedelta(days=random.randint(1, 60))
        else:
            # histórica
            lo = DATE_START + timedelta(seconds=random.randint(0, RANGE_SECONDS))
            hi = lo + timedelta(days=random.randint(5, 45))
        period = f'["{lo.isoformat()}","{hi.isoformat()}")'
        w.writerow([pid, random.choice(seller_ids), period, round(random.uniform(5, 50), 2)])


def gen_outbox(writers, n_events):
    """~2% sin procesar (processed_at NULL) para el índice PARCIAL / consulta Q8."""
    w = writers["outbox_events"]
    w.writerow(["aggregate_type", "aggregate_id", "event_type", "payload", "created_at", "processed_at"])
    for _ in range(n_events):
        created = DATE_START + timedelta(seconds=random.randint(0, RANGE_SECONDS))
        unprocessed = random.random() < 0.02
        processed = "" if unprocessed else (created + timedelta(minutes=random.randint(1, 120))).isoformat()
        payload = json.dumps({"v": 1, "kind": random.choice(["order", "payment", "shipment"])})
        w.writerow(["order", rand_hex32(), "OrderStatusChanged", payload, created.isoformat(), processed])


def gen_facts(args, pools, writers, seller_ids, product_ids, customer_ids):
    """Pasada única: órdenes + ítems + pagos + reseñas."""
    prices = pools["prices"]

    writers["orders"].writerow([
        "order_id", "customer_id", "order_status", "order_purchase_timestamp",
        "order_approved_at", "order_delivered_carrier_date",
        "order_delivered_customer_date", "order_estimated_delivery_date", "metadata",
    ])
    writers["order_items"].writerow([
        "order_id", "order_purchase_timestamp", "order_item_id", "product_id",
        "seller_id", "shipping_limit_date", "price", "freight_value",
    ])
    writers["order_payments"].writerow([
        "order_id", "order_purchase_timestamp", "payment_sequential",
        "payment_type", "payment_installments", "payment_value",
    ])
    writers["order_reviews"].writerow([
        "review_id", "order_id", "order_purchase_timestamp", "review_score",
        "review_comment_title", "review_comment_message",
        "review_creation_date", "review_answer_timestamp",
    ])

    wo = writers["orders"].writerow
    wi = writers["order_items"].writerow
    wp = writers["order_payments"].writerow
    wr = writers["order_reviews"].writerow

    n_orders = args.orders
    n_anomaly = max(1, int(n_orders * 0.001))  # filas fuera de rango -> partición DEFAULT (Fase 3)

    for k in range(n_orders):
        order_id = rand_hex32()
        customer_id = customer_ids[k]

        if k < n_anomaly:
            # timestamps fuera de la ventana 2016-09..2018-10 (llegan a DEFAULT)
            purchase = datetime(2019, random.randint(1, 6), random.randint(1, 28),
                                tzinfo=timezone.utc) + timedelta(seconds=random.randint(0, 86400))
        else:
            purchase = DATE_START + timedelta(seconds=random.randint(0, RANGE_SECONDS))

        status = weighted_pick(STATUS_WEIGHTS)
        estimated = purchase + timedelta(days=random.randint(8, 25))

        approved = carrier = delivered = None
        if status not in ("created",):
            approved = purchase + timedelta(minutes=random.randint(5, 600))
        if status in ("shipped", "delivered"):
            carrier = approved + timedelta(days=random.randint(1, 5))
        if status == "delivered":
            delivered = carrier + timedelta(days=random.randint(1, 12))

        metadata = json.dumps({
            "channel": random.choice(CHANNELS),
            "gift": random.random() < 0.05,
        })

        p_iso = purchase.isoformat()
        wo([
            order_id, customer_id, status, p_iso,
            approved.isoformat() if approved else "",
            carrier.isoformat() if carrier else "",
            delivered.isoformat() if delivered else "",
            estimated.isoformat(), metadata,
        ])

        # ítems (1-5, sesgado a 1)
        n_items = random.choices([1, 2, 3, 4, 5], weights=[70, 18, 7, 3, 2])[0]
        order_total = 0.0
        for item_no in range(1, n_items + 1):
            price, freight = random.choice(prices)
            price = round(price * random.uniform(0.85, 1.15), 2)
            order_total += price + freight
            ship_limit = purchase + timedelta(days=random.randint(2, 8))
            wi([order_id, p_iso, item_no, random.choice(product_ids),
                random.choice(seller_ids), ship_limit.isoformat(),
                f"{price:.2f}", f"{freight:.2f}"])

        # pagos (1-2)
        n_pay = random.choices([1, 2], weights=[88, 12])[0]
        remaining = max(order_total, 1.0)
        for seq in range(1, n_pay + 1):
            ptype = weighted_pick(PAYMENT_WEIGHTS)
            installments = random.choice([1, 1, 1, 2, 3, 4, 6, 8, 10]) if ptype == "credit_card" else 1
            value = round(remaining if seq == n_pay else remaining / 2, 2)
            remaining -= value
            wp([order_id, p_iso, seq, ptype, installments, f"{value:.2f}"])

        # reseña (~65% de las entregadas)
        if status == "delivered" and random.random() < 0.65:
            created = (delivered or purchase) + timedelta(days=random.randint(1, 10))
            answered = created + timedelta(days=random.randint(0, 5))
            score = weighted_pick(REVIEW_SCORE_WEIGHTS)
            wr([rand_hex32(), order_id, p_iso, score, "", "",
                created.isoformat(), answered.isoformat()])

        if (k + 1) % 100000 == 0:
            print(f"  ... {k + 1:,} órdenes generadas")


def main():
    ap = argparse.ArgumentParser(description="Generador de datos sintéticos Ecommify (Actividad 4)")
    ap.add_argument("--orders", type=int, default=1_000_000)
    ap.add_argument("--products", type=int, default=32_000)
    ap.add_argument("--sellers", type=int, default=3_000)
    ap.add_argument("--promos", type=int, default=6_000)
    ap.add_argument("--outbox", type=int, default=50_000)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--seed-dir", default=SEED_DIR_DEFAULT)
    ap.add_argument("--out", default=os.path.join(os.path.dirname(__file__), "data"))
    args = ap.parse_args()

    random.seed(args.seed)
    os.makedirs(args.out, exist_ok=True)

    print(f"Cargando pools desde {args.seed_dir} ...")
    pools = load_pools(args.seed_dir)

    tables = [
        "geo_locations", "categories", "sellers", "products", "customers",
        "orders", "order_items", "order_payments", "order_reviews",
        "product_promotions", "outbox_events",
    ]
    files = {t: open(os.path.join(args.out, f"{t}.csv"), "w", newline="", encoding="utf-8") for t in tables}
    writers = {t: csv.writer(files[t]) for t in tables}

    try:
        print("Generando dimensiones ...")
        seller_ids, product_ids, customer_ids = gen_dimensions(
            pools, args.orders, args.sellers, args.products, args.out, writers
        )
        print(f"Generando {args.orders:,} órdenes (+ ítems, pagos, reseñas) ...")
        gen_facts(args, pools, writers, seller_ids, product_ids, customer_ids)
        print("Generando promociones y outbox ...")
        gen_promotions(writers, product_ids, seller_ids, args.promos)
        gen_outbox(writers, args.outbox)
    finally:
        for fh in files.values():
            fh.close()

    print(f"Listo. CSV escritos en {args.out}/")


if __name__ == "__main__":
    main()
