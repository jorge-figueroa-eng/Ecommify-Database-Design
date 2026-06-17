// 03_text_indexes.js
db = db.getSiblingDB("ecommify");

db.order_reviews.createIndex(
  { review_comment_title: "text", review_comment_message: "text" },
  { name: "idx_reviews_text_search", default_language: "portuguese" }
);

db.products_catalog.createIndex(
  { "category.name_en": "text", "category.name_pt": "text", "attributes.k": "text" },
  { name: "idx_products_text_search" }
);
