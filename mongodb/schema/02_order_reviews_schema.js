// 02_order_reviews_schema.js
// Reviews referenciadas por order_id para evitar crecimiento no controlado en documentos de producto.

const dbName = process.env.MONGODB_DATABASE || 'ecommify';
const database = db.getSiblingDB(dbName);

database.createCollection('order_reviews', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['review_id', 'order_id', 'review_score'],
      properties: {
        review_id: { bsonType: 'string' },
        order_id: { bsonType: 'string' },
        review_score: { bsonType: ['int', 'long'], minimum: 1, maximum: 5 },
        review_comment_title: { bsonType: ['string', 'null'] },
        review_comment_message: { bsonType: ['string', 'null'] },
        review_creation_date: { bsonType: ['date', 'null'] },
        review_answer_timestamp: { bsonType: ['date', 'null'] },
        sentiment_hint: { bsonType: ['string', 'null'] }
      }
    }
  }
});
