// 01_revenue_by_state_payment.js
// Pipeline complejo con $match, $lookup, $unwind, $addFields, $group, $project, $sort, $facet y allowDiskUse.

const dbName = process.env.MONGODB_DATABASE || 'ecommify';
const database = db.getSiblingDB(dbName);

const result = database.orders_analytics.aggregate([
  {
    $match: {
      status: 'delivered',
      purchase_ts: {
        $gte: ISODate('2017-01-01T00:00:00Z'),
        $lt: ISODate('2018-01-01T00:00:00Z')
      }
    }
  },
  {
    $lookup: {
      from: 'order_reviews',
      localField: 'order_id',
      foreignField: 'order_id',
      as: 'reviews'
    }
  },
  {
    $unwind: {
      path: '$reviews',
      preserveNullAndEmptyArrays: true
    }
  },
  {
    $addFields: {
      purchase_month: { $dateTrunc: { date: '$purchase_ts', unit: 'month' } },
      review_score_safe: { $ifNull: ['$reviews.review_score', null] },
      payment_total_safe: { $ifNull: ['$payment_summary.total_value', 0] }
    }
  },
  {
    $group: {
      _id: { state: '$customer.state', month: '$purchase_month' },
      total_orders: { $sum: 1 },
      total_revenue: { $sum: '$payment_total_safe' },
      avg_review_score: { $avg: '$review_score_safe' }
    }
  },
  {
    $project: {
      _id: 0,
      state: '$_id.state',
      month: '$_id.month',
      total_orders: 1,
      total_revenue: { $round: ['$total_revenue', 2] },
      avg_review_score: { $round: ['$avg_review_score', 2] }
    }
  },
  { $sort: { total_revenue: -1 } },
  {
    $facet: {
      top_states: [{ $limit: 10 }],
      summary: [
        {
          $group: {
            _id: null,
            total_revenue: { $sum: '$total_revenue' },
            total_orders: { $sum: '$total_orders' },
            avg_score_global: { $avg: '$avg_review_score' }
          }
        }
      ]
    }
  }
], { allowDiskUse: true }).toArray();

printjson(result);
