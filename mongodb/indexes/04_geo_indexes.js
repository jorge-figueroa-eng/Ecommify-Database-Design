// 04_geo_indexes.js
db = db.getSiblingDB("ecommify");

db.geolocation_points.createIndex(
  { location: "2dsphere" },
  { name: "idx_geolocation_2dsphere" }
);
