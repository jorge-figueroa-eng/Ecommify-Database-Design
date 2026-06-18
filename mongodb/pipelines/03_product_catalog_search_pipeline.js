// 03_product_catalog_search_pipeline.js
// Búsqueda analítica de catálogo por categoría y atributos.

const dbName = process.env.MONGODB_DATABASE || 'ecommify';
const database = db.getSiblingDB(dbName);

const result = database.products_catalog.aggregate([
  { $match: { 'category.name_en': { $exists: true, $ne: null } } },
  { $unwind: '$attributes' },
  { $match: { 'attributes.k': { $in: ['weight_g', 'volume_cm3', 'photos_qty'] } } },
  {
    $group: {
      _id: '$category.name_en',
      product_count: { $sum: 1 },
      avg_weight: { $avg: '$dimensions.weight_g' },
      avg_volume: { $avg: '$dimensions.volume_cm3' }
    }
  },
  {
    $project: {
      _id: 0,
      category: '$_id',
      product_count: 1,
      avg_weight: { $round: ['$avg_weight', 2] },
      avg_volume: { $round: ['$avg_volume', 2] }
    }
  },
  { $sort: { product_count: -1 } },
  { $limit: 15 }
], { allowDiskUse: true }).toArray();

printjson(result);
