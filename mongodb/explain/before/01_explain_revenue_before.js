// Ejecutar antes de crear índices MongoDB.
const dbName = process.env.MONGODB_DATABASE || 'ecommify';
const database = db.getSiblingDB(dbName);

const explanation = database.orders_analytics.explain('executionStats').aggregate([
  {
    $match: {
      status: 'delivered',
      purchase_ts: {
        $gte: ISODate('2017-01-01T00:00:00Z'),
        $lt: ISODate('2018-01-01T00:00:00Z')
      }
    }
  },
  { $lookup: { from: 'order_reviews', localField: 'order_id', foreignField: 'order_id', as: 'reviews' } },
  { $unwind: { path: '$reviews', preserveNullAndEmptyArrays: true } },
  { $addFields: { purchase_month: { $dateTrunc: { date: '$purchase_ts', unit: 'month' } } } },
  { $group: { _id: { state: '$customer.state', month: '$purchase_month' }, total_orders: { $sum: 1 }, total_revenue: { $sum: '$payment_summary.total_value' } } },
  { $project: { _id: 0, state: '$_id.state', month: '$_id.month', total_orders: 1, total_revenue: 1 } },
  { $sort: { total_revenue: -1 } }
], { allowDiskUse: true });

printjson(explanation);
