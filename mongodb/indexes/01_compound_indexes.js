// 01_compound_indexes.js
// Índices compuestos aplicando regla ESR: Equality, Sort, Range.

const dbName = process.env.MONGODB_DATABASE || 'ecommify';
const database = db.getSiblingDB(dbName);

database.orders_analytics.createIndex(
  { 'customer.state': 1, status: 1, purchase_ts: -1 },
  { name: 'idx_orders_state_status_purchase_esr' }
);

database.orders_analytics.createIndex(
  { purchase_year_month: 1, 'customer.state': 1, 'payment_summary.total_value': -1 },
  { name: 'idx_orders_month_state_value' }
);

database.products_catalog.createIndex(
  { 'category.name_en': 1, 'dimensions.weight_g': 1, 'metrics.photos_qty': -1 },
  { name: 'idx_products_category_weight_photos' }
);

database.seller_state_buckets.createIndex(
  { state: 1, seller_count: -1 },
  { name: 'idx_seller_bucket_state_count' }
);
