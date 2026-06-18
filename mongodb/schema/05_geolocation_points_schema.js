// 05_geolocation_points_schema.js
// Puntos geográficos en GeoJSON para consultas 2dsphere.

const dbName = process.env.MONGODB_DATABASE || 'ecommify';
const database = db.getSiblingDB(dbName);

database.createCollection('geolocation_points', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['zip_code_prefix', 'city', 'state', 'location'],
      properties: {
        zip_code_prefix: { bsonType: ['int', 'long', 'string'] },
        city: { bsonType: 'string' },
        state: { bsonType: 'string' },
        location: {
          bsonType: 'object',
          required: ['type', 'coordinates'],
          properties: {
            type: { enum: ['Point'] },
            coordinates: { bsonType: 'array', minItems: 2, maxItems: 2 }
          }
        }
      }
    }
  }
});
