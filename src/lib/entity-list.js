/**
 * Base44 entity list/filter APIs sometimes return a plain array and sometimes a paginated envelope.
 */
export function normalizeEntityList(result) {
  if (result == null) return [];
  if (Array.isArray(result)) return result;
  if (Array.isArray(result.items)) return result.items;
  if (Array.isArray(result.data)) return result.data;
  if (Array.isArray(result.results)) return result.results;
  if (Array.isArray(result.records)) return result.records;
  if (Array.isArray(result.entities)) return result.entities;
  return [];
}

/** Dedupe by id and put the newest receipt first (matches typical “-purchase_date” list). */
export function mergeReceiptIntoList(prev, receipt) {
  const list = normalizeEntityList(prev);
  const idStr = String(receipt.id);
  const without = list.filter((r) => String(r.id) !== idStr);
  return [receipt, ...without];
}
