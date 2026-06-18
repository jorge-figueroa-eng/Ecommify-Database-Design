"""Carga CSV Olist a MongoDB Atlas con modelos documentales de la Etapa 2.

Uso:
  python mongodb/load/load_to_mongodb.py
"""
import os
from pathlib import Path
import pandas as pd
from pymongo import MongoClient, UpdateOne
from dotenv import load_dotenv

load_dotenv()
DATA_DIR = Path(os.getenv('DATA_DIR', 'data/raw'))
MONGODB_URI = os.environ['MONGODB_URI']
DB_NAME = os.getenv('MONGODB_DATABASE', 'ecommify')

client = MongoClient(MONGODB_URI)
db = client[DB_NAME]

def read_csv(name):
    path = DATA_DIR / name
    if not path.exists():
        raise FileNotFoundError(f'No existe {path}')
    return pd.read_csv(path)

products = read_csv('olist_products_dataset.csv')
translations = read_csv('product_category_name_translation.csv')
translation_map = dict(zip(translations['product_category_name'], translations['product_category_name_english']))

ops = []
for _, row in products.iterrows():
    category_pt = row.get('product_category_name')
    weight = row.get('product_weight_g')
    length = row.get('product_length_cm')
    height = row.get('product_height_cm')
    width = row.get('product_width_cm')
    def safe(v):
        return None if pd.isna(v) else int(v) if float(v).is_integer() else float(v)
    volume = None
    if pd.notna(length) and pd.notna(height) and pd.notna(width):
        volume = float(length) * float(height) * float(width)
    doc = {
        'product_id': row['product_id'],
        'category': {'name_pt': category_pt if pd.notna(category_pt) else 'unknown', 'name_en': translation_map.get(category_pt)},
        'metrics': {
            'name_length': safe(row.get('product_name_lenght')),
            'description_length': safe(row.get('product_description_lenght')),
            'photos_qty': safe(row.get('product_photos_qty')),
        },
        'attributes': [
            {'k': 'weight_g', 'v': safe(weight)},
            {'k': 'length_cm', 'v': safe(length)},
            {'k': 'height_cm', 'v': safe(height)},
            {'k': 'width_cm', 'v': safe(width)},
            {'k': 'volume_cm3', 'v': volume},
        ],
        'dimensions': {
            'weight_g': safe(weight), 'length_cm': safe(length), 'height_cm': safe(height),
            'width_cm': safe(width), 'volume_cm3': volume
        }
    }
    ops.append(UpdateOne({'product_id': doc['product_id']}, {'$set': doc}, upsert=True))
if ops:
    db.products_catalog.bulk_write(ops, ordered=False)

reviews = read_csv('olist_order_reviews_dataset.csv')
ops = []
for _, row in reviews.iterrows():
    doc = {
        'review_id': row['review_id'],
        'order_id': row['order_id'],
        'review_score': int(row['review_score']),
        'review_comment_title': None if pd.isna(row.get('review_comment_title')) else row.get('review_comment_title'),
        'review_comment_message': None if pd.isna(row.get('review_comment_message')) else row.get('review_comment_message'),
        'review_creation_date': pd.to_datetime(row.get('review_creation_date'), errors='coerce').to_pydatetime() if pd.notna(row.get('review_creation_date')) else None,
        'review_answer_timestamp': pd.to_datetime(row.get('review_answer_timestamp'), errors='coerce').to_pydatetime() if pd.notna(row.get('review_answer_timestamp')) else None,
    }
    ops.append(UpdateOne({'review_id': doc['review_id']}, {'$set': doc}, upsert=True))
if ops:
    db.order_reviews.bulk_write(ops, ordered=False)

orders = read_csv('olist_orders_dataset.csv')
customers = read_csv('olist_customers_dataset.csv')
payments = read_csv('olist_order_payments_dataset.csv')
customer_map = customers.set_index('customer_id').to_dict('index')
payment_summary = payments.groupby('order_id').agg(
    total_value=('payment_value','sum'),
    max_installments=('payment_installments','max')
).reset_index().set_index('order_id').to_dict('index')
payment_types = payments.groupby('order_id')['payment_type'].apply(lambda s: sorted(set(s.dropna()))).to_dict()

ops = []
for _, row in orders.iterrows():
    c = customer_map.get(row['customer_id'], {})
    p = payment_summary.get(row['order_id'], {})
    purchase_ts = pd.to_datetime(row['order_purchase_timestamp'], errors='coerce')
    doc = {
        'order_id': row['order_id'],
        'status': row['order_status'],
        'purchase_ts': purchase_ts.to_pydatetime() if pd.notna(purchase_ts) else None,
        'purchase_year_month': purchase_ts.strftime('%Y-%m') if pd.notna(purchase_ts) else 'unknown',
        'customer': {
            'customer_id': row['customer_id'],
            'customer_unique_id': c.get('customer_unique_id'),
            'state': c.get('customer_state'),
            'city': c.get('customer_city'),
            'zip_code_prefix': int(c.get('customer_zip_code_prefix')) if pd.notna(c.get('customer_zip_code_prefix')) else None,
        },
        'payment_summary': {
            'total_value': float(p.get('total_value', 0)),
            'payment_types': payment_types.get(row['order_id'], []),
            'max_installments': int(p.get('max_installments')) if pd.notna(p.get('max_installments')) else None,
        }
    }
    ops.append(UpdateOne({'order_id': doc['order_id']}, {'$set': doc}, upsert=True))
if ops:
    db.orders_analytics.bulk_write(ops, ordered=False)

sellers = read_csv('olist_sellers_dataset.csv')
for state, group in sellers.groupby('seller_state'):
    sellers_list = [
        {
            'seller_id': r['seller_id'],
            'city': r['seller_city'],
            'zip_code_prefix': int(r['seller_zip_code_prefix']) if pd.notna(r['seller_zip_code_prefix']) else None,
        }
        for _, r in group.iterrows()
    ]
    db.seller_state_buckets.update_one(
        {'state': state},
        {'$set': {'state': state, 'seller_count': len(sellers_list), 'sellers': sellers_list}},
        upsert=True
    )

print('Carga MongoDB finalizada correctamente')
