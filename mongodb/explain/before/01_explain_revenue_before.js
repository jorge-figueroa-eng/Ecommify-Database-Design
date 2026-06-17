// 01_explain_revenue_before.js
// Ejecutar antes de crear indices MongoDB.
db = db.getSiblingDB("ecommify");

printjson(
  db.orders_analytics.explain("executionStats").aggregate([
    { $match: { status: "delivered", purchase_ts: { $gte: ISODate("2017-01-01T00:00:00Z"), $lt: ISODate("2018-01-01T00:00:00Z") } } },
    { $lookup: { from: "order_reviews", localField: "order_id", foreignField: "order_id", as: "reviews" } },
    { $unwind: { path: "$reviews", preserveNullAndEmptyArrays: true } },
    { $addFields: { purchase_month: { $dateTrunc: { date: "$purchase_ts", unit: "month" } }, review_score_safe: { $ifNull: ["$reviews.review_score", 0] } } },
    { $group: { _id: { state: "$customer.state", month: "$purchase_month" }, total_orders: { $sum: 1 }, total_revenue: { $sum: "$payment_summary.total_value" }, avg_review_score: { $avg: "$review_score_safe" } } },
    { $project: { _id: 0, state: "$_id.state", month: "$_id.month", total_orders: 1, total_revenue: { $round: ["$total_revenue", 2] }, avg_review_score: { $round: ["$avg_review_score", 2] } } },
    { $sort: { total_revenue: -1 } },
    { $facet: { top_states: [{ $limit: 10 }], summary: [{ $group: { _id: null, total_revenue: { $sum: "$total_revenue" }, total_orders: { $sum: "$total_orders" } } }] } }
  ], { allowDiskUse: true })
);
