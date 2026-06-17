// 05_geolocation_points_schema.js
// GeoJSON para consultas espaciales en MongoDB.
db = db.getSiblingDB("ecommify");

db.createCollection("geolocation_points", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["zip_code_prefix", "city", "state", "location"],
      properties: {
        zip_code_prefix: { bsonType: ["int", "long"] },
        city: { bsonType: "string" },
        state: { bsonType: "string" },
        location: {
          bsonType: "object",
          required: ["type", "coordinates"],
          properties: {
            type: { enum: ["Point"] },
            coordinates: { bsonType: "array" }
          }
        }
      }
    }
  },
  validationLevel: "moderate",
  validationAction: "warn"
});
