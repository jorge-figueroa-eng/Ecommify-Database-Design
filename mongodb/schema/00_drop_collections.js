// 00_drop_collections.js
// Limpieza para ambiente academico/desarrollo.
db = db.getSiblingDB("ecommify");
[
  "products_catalog",
  "order_reviews",
  "orders_analytics",
  "seller_state_buckets",
  "geolocation_points",
  "payments"
].forEach(function(c) { db.getCollection(c).drop(); });
