// 02_partial_indexes.js
// Índices parciales para subconjuntos de datos relevantes.

const dbName = process.env.MONGODB_DATABASE || 'ecommify';
const database = db.getSiblingDB(dbName);

database.order_reviews.createIndex(
  { review_score: 1, review_creation_date: -1 },
  {
    name: 'idx_low_score_reviews_with_comment',
    partialFilterExpression: {
      review_score: { $lte: 3 },
      review_comment_message: { $exists: true, $type: 'string' }
    }
  }
);

database.orders_analytics.createIndex(
  { purchase_ts: -1, 'customer.state': 1 },
  {
    name: 'idx_delivered_orders_recent_by_state',
    partialFilterExpression: { status: 'delivered' }
  }
);
