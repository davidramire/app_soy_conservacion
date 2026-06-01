export function parseDateBound(value, boundary = 'start') {
  if (value == null || value === '') {
    return null;
  }

  const trimmed = String(value).trim();
  const normalized = trimmed.length === 10 ? `${trimmed}T00:00:00.000Z` : trimmed;
  const parsed = new Date(normalized);

  if (Number.isNaN(parsed.getTime())) {
    return null;
  }

  if (boundary === 'end' && trimmed.length === 10) {
    parsed.setUTCHours(23, 59, 59, 999);
  }

  return parsed;
}

export function buildDateFilter(dateFrom, dateTo) {
  const filter = {};
  const from = parseDateBound(dateFrom, 'start');
  const to = parseDateBound(dateTo, 'end');

  if (from) {
    filter.gte = from;
  }
  if (to) {
    filter.lte = to;
  }

  return Object.keys(filter).length > 0 ? filter : null;
}

export function parseSourceFilter(source) {
  const normalized = String(source ?? 'all').trim().toLowerCase();

  if (normalized === 'odk' || normalized === 'drive') {
    return 'odk';
  }
  if (normalized === 'inaturalist' || normalized === 'inat') {
    return 'inaturalist';
  }

  return 'all';
}
