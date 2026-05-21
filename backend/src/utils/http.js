export function parsePagination(query) {
  const page = Math.max(Number(query.page ?? 1), 1);
  const limit = Math.min(Math.max(Number(query.limit ?? 50), 1), 200);
  const skip = (page - 1) * limit;
  return { page, limit, skip };
}

export function buildPagedResponse(items, total, page, limit) {
  return {
    data: items,
    total,
    page,
    pageSize: limit,
    hasMore: page * limit < total,
  };
}

export function averageCoordinates(items) {
  const usableItems = items.filter((item) => Number.isFinite(item.latitude) && Number.isFinite(item.longitude));
  if (usableItems.length === 0) {
    return null;
  }

  const total = usableItems.reduce(
    (accumulator, item) => {
      accumulator.latitude += item.latitude;
      accumulator.longitude += item.longitude;
      return accumulator;
    },
    { latitude: 0, longitude: 0 },
  );

  return {
    latitude: total.latitude / usableItems.length,
    longitude: total.longitude / usableItems.length,
  };
}