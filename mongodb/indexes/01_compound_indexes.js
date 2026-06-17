// 01_compound_indexes.js
// Indices compuestos siguiendo ESR: Equality, Sort, Range.
db = db.getSiblingDB("ecommify");

db.orders_analytics.createIndex(
  { "customer.state": 1, "status": 1, "purchase_ts": -1 },
  { name: "idx_orders_state_status_purchase_esr" }
);

db.products_catalog.createIndex(
  { "category.name_en": 1, "dimensions.weight_g": 1, "metrics.photos_qty": -1 },
  { name: "idx_products_category_weight_photos" }
);

db.order_reviews.createIndex(
  { order_id: 1, review_creation_date: -1 },
  { name: "idx_reviews_order_creation" }
);
