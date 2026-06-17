// 04_seller_state_buckets_schema.js
// Bucket Pattern para agrupar vendedores por estado.
db = db.getSiblingDB("ecommify");

db.createCollection("seller_state_buckets", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["state", "seller_count", "sellers"],
      properties: {
        state: { bsonType: "string" },
        seller_count: { bsonType: "int" },
        sellers: {
          bsonType: "array",
          items: {
            bsonType: "object",
            required: ["seller_id", "city"],
            properties: {
              seller_id: { bsonType: "string" },
              city: { bsonType: "string" },
              zip_code_prefix: { bsonType: ["int", "long", "string", "null"] }
            }
          }
        }
      }
    }
  },
  validationLevel: "moderate",
  validationAction: "warn"
});
