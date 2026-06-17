// 03_orders_analytics_schema.js
// Modelo analitico con Extended Reference Pattern.
db = db.getSiblingDB("ecommify");

db.createCollection("orders_analytics", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["order_id", "status", "purchase_ts", "purchase_year_month", "customer"],
      properties: {
        order_id: { bsonType: "string" },
        status: { bsonType: "string" },
        purchase_ts: { bsonType: "date" },
        purchase_year_month: { bsonType: "string" },
        customer: {
          bsonType: "object",
          required: ["customer_id", "state", "city"],
          properties: {
            customer_id: { bsonType: "string" },
            customer_unique_id: { bsonType: ["string", "null"] },
            state: { bsonType: "string" },
            city: { bsonType: "string" },
            zip_code_prefix: { bsonType: ["int", "long", "string", "null"] }
          }
        },
        payment_summary: {
          bsonType: "object",
          properties: {
            total_value: { bsonType: ["double", "int", "long", "decimal", "null"] },
            payment_types: { bsonType: "array" },
            installments_max: { bsonType: ["int", "long", "null"] }
          }
        }
      }
    }
  },
  validationLevel: "moderate",
  validationAction: "warn"
});
