// 01_products_catalog_schema.js
// Modelo de catalogo con Attribute Pattern.
db = db.getSiblingDB("ecommify");

db.createCollection("products_catalog", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["product_id", "category", "attributes", "dimensions"],
      properties: {
        product_id: { bsonType: "string" },
        category: {
          bsonType: "object",
          required: ["name_pt"],
          properties: {
            name_pt: { bsonType: ["string", "null"] },
            name_en: { bsonType: ["string", "null"] }
          }
        },
        metrics: {
          bsonType: "object",
          properties: {
            name_length: { bsonType: ["int", "long", "double", "null"] },
            description_length: { bsonType: ["int", "long", "double", "null"] },
            photos_qty: { bsonType: ["int", "long", "double", "null"] }
          }
        },
        attributes: {
          bsonType: "array",
          items: {
            bsonType: "object",
            required: ["k", "v"],
            properties: {
              k: { bsonType: "string" },
              v: {}
            }
          }
        },
        dimensions: {
          bsonType: "object",
          properties: {
            weight_g: { bsonType: ["int", "long", "double", "null"] },
            length_cm: { bsonType: ["int", "long", "double", "null"] },
            height_cm: { bsonType: ["int", "long", "double", "null"] },
            width_cm: { bsonType: ["int", "long", "double", "null"] },
            volume_cm3: { bsonType: ["int", "long", "double", "null"] }
          }
        }
      }
    }
  },
  validationLevel: "moderate",
  validationAction: "warn"
});
