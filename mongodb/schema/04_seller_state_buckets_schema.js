// 04_seller_state_buckets_schema.js
// Bucket Pattern: vendedores agrupados por estado para analítica regional.

const dbName = process.env.MONGODB_DATABASE || 'ecommify';
const database = db.getSiblingDB(dbName);

database.createCollection('seller_state_buckets', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['state', 'seller_count', 'sellers'],
      properties: {
        state: { bsonType: 'string' },
        seller_count: { bsonType: ['int', 'long'] },
        sellers: {
          bsonType: 'array',
          items: {
            bsonType: 'object',
            required: ['seller_id', 'city'],
            properties: {
              seller_id: { bsonType: 'string' },
              city: { bsonType: 'string' },
              zip_code_prefix: { bsonType: ['int', 'long', 'string', 'null'] }
            }
          }
        }
      }
    }
  }
});
