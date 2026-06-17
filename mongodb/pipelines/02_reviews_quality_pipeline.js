// 02_reviews_quality_pipeline.js
db = db.getSiblingDB("ecommify");

db.order_reviews.aggregate([
  { $match: { review_comment_message: { $exists: true, $type: "string" } } },
  { $addFields: { comment_length: { $strLenCP: "$review_comment_message" } } },
  { $bucket: {
      groupBy: "$review_score",
      boundaries: [1, 2, 3, 4, 5, 6],
      default: "unknown",
      output: {
        total_reviews: { $sum: 1 },
        avg_comment_length: { $avg: "$comment_length" }
      }
  }},
  { $sort: { _id: 1 } }
], { allowDiskUse: true });
