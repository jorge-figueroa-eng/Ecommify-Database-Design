// 02_reviews_quality_pipeline.js
// Análisis de calidad de reviews usando índice parcial y texto.

const dbName = process.env.MONGODB_DATABASE || 'ecommify';
const database = db.getSiblingDB(dbName);

const result = database.order_reviews.aggregate([
  { $match: { review_score: { $lte: 3 }, review_comment_message: { $exists: true, $type: 'string' } } },
  { $addFields: { comment_length: { $strLenCP: '$review_comment_message' } } },
  {
    $bucket: {
      groupBy: '$review_score',
      boundaries: [1, 2, 3, 4],
      default: 'other',
      output: {
        total_reviews: { $sum: 1 },
        avg_comment_length: { $avg: '$comment_length' }
      }
    }
  },
  { $sort: { _id: 1 } }
], { allowDiskUse: true }).toArray();

printjson(result);
