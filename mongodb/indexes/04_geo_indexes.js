// 04_geo_indexes.js
// Índice geoespacial 2dsphere para geolocation_points.

const dbName = process.env.MONGODB_DATABASE || 'ecommify';
const database = db.getSiblingDB(dbName);

database.geolocation_points.createIndex(
  { location: '2dsphere' },
  { name: 'idx_geolocation_points_2dsphere' }
);
