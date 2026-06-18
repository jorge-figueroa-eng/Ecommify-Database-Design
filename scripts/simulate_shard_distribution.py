import hashlib
import pandas as pd
from pathlib import Path

orders_path = Path('data/raw/olist_orders_dataset.csv')
orders = pd.read_csv(orders_path)

def shard(order_id: str, n=3) -> int:
    return int(hashlib.sha256(order_id.encode('utf-8')).hexdigest(), 16) % n

orders['shard'] = orders['order_id'].apply(shard)
summary = orders.groupby('shard').size().reset_index(name='orders')
summary['percentage'] = (summary['orders'] / summary['orders'].sum() * 100).round(2)
summary.to_csv('evidences/mongodb/shard_distribution_simulation.csv', index=False)
print(summary)
