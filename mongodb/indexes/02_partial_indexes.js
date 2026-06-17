// 02_partial_indexes.js
db = db.getSiblingDB("ecommify");

db.order_reviews.createIndex(
  { review_score: 1, review_creation_date: -1 },
  {
    name: "idx_low_score_reviews_with_comment",
    partialFilterExpression: {
      review_score: { $lte: 3 },
      review_comment_message: { $exists: true, $type: "string" }
    }
  }
);

db.orders_analytics.createIndex(
  { purchase_ts: -1, "payment_summary.total_value": -1 },
  {
    name: "idx_delivered_orders_revenue_partial",
    partialFilterExpression: { status: "delivered" }
  }
);
