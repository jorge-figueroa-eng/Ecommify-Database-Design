// 03_product_catalog_search_pipeline.js
db = db.getSiblingDB("ecommify");

db.products_catalog.aggregate([
  { $match: { $text: { $search: "health beauty" } } },
  { $addFields: { score: { $meta: "textScore" } } },
  { $project: { product_id: 1, category: 1, dimensions: 1, score: 1 } },
  { $sort: { score: { $meta: "textScore" }, "dimensions.weight_g": 1 } },
  { $limit: 20 }
]);
