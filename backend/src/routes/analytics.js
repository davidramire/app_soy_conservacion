import { Router } from 'express';

import { prisma } from '../lib/prisma.js';
import { asyncHandler } from '../middleware/async-handler.js';
import { buildDateFilter, parseSourceFilter } from '../utils/date-filters.js';

export const analyticsRouter = Router();

function parseRankingLimit(value) {
  const parsed = Number(value ?? 12);
  return Math.min(Math.max(Number.isFinite(parsed) ? parsed : 12, 1), 100);
}

analyticsRouter.get(
  '/date-bounds',
  asyncHandler(async (_request, response) => {
    const [odkBounds, inatBounds] = await Promise.all([
      prisma.observacion.aggregate({
        _min: { fecha: true },
        _max: { fecha: true },
        where: { fecha: { not: null } },
      }),
      prisma.inaturalistObservacion.aggregate({
        _min: { fecha: true },
        _max: { fecha: true },
        where: { fecha: { not: null } },
      }),
    ]);

    const dates = [
      odkBounds._min.fecha,
      odkBounds._max.fecha,
      inatBounds._min.fecha,
      inatBounds._max.fecha,
    ].filter(Boolean);

    const minDate = dates.length > 0 ? new Date(Math.min(...dates.map((d) => d.getTime()))) : null;
    const maxDate = dates.length > 0 ? new Date(Math.max(...dates.map((d) => d.getTime()))) : null;

    response.json({
      minDate: minDate?.toISOString() ?? null,
      maxDate: maxDate?.toISOString() ?? null,
    });
  }),
);

analyticsRouter.get(
  '/taxonomic-groups',
  asyncHandler(async (request, response) => {
    const dateFilter = buildDateFilter(request.query.dateFrom, request.query.dateTo);
    const source = parseSourceFilter(request.query.source);
    const counts = new Map();

    const addGroup = (name, total = 1) => {
      const key = (name ?? 'Sin grupo').trim() || 'Sin grupo';
      counts.set(key, (counts.get(key) ?? 0) + total);
    };

    if (source === 'all' || source === 'odk') {
      const rows = await prisma.observacion.groupBy({
        by: ['especieId'],
        where: {
          latitud: { not: null },
          longitud: { not: null },
          ...(dateFilter ? { fecha: dateFilter } : {}),
        },
        _count: { _all: true },
      });

      const speciesIds = rows.map((row) => row.especieId).filter(Boolean);
      const species = speciesIds.length
        ? await prisma.especie.findMany({
            where: { idEspecie: { in: speciesIds } },
            include: { grupoTaxonomico: true },
          })
        : [];

      const speciesById = new Map(species.map((item) => [item.idEspecie, item]));

      for (const row of rows) {
        const speciesItem = speciesById.get(row.especieId);
        addGroup(speciesItem?.grupoTaxonomico?.nombre, row._count._all);
      }
    }

    if (source === 'all' || source === 'inaturalist') {
      const rows = await prisma.inaturalistObservacion.findMany({
        where: {
          latitud: { not: null },
          longitud: { not: null },
          ...(dateFilter ? { fecha: dateFilter } : {}),
        },
        select: {
          grupoTaxonomico: { select: { nombre: true } },
          especie: {
            select: {
              grupoTaxonomico: { select: { nombre: true } },
            },
          },
        },
      });

      for (const row of rows) {
        addGroup(row.grupoTaxonomico?.nombre ?? row.especie?.grupoTaxonomico?.nombre);
      }
    }

    const data = [...counts.entries()]
      .map(([nombre, total]) => ({ nombre, total }))
      .sort((left, right) => right.total - left.total);

    response.json({ data, total: data.length });
  }),
);

analyticsRouter.get(
  '/ranking-users',
  asyncHandler(async (request, response) => {
    const dateFilter = buildDateFilter(request.query.dateFrom, request.query.dateTo);
    const source = parseSourceFilter(request.query.source);
    const limit = parseRankingLimit(request.query.limit);
    const counts = new Map();

    const addUser = (username, total = 1) => {
      const key = (username ?? 'Anónimo').trim() || 'Anónimo';
      counts.set(key, (counts.get(key) ?? 0) + total);
    };

    if (source === 'all' || source === 'odk') {
      const rows = await prisma.observacion.groupBy({
        by: ['usuarioId'],
        where: {
          latitud: { not: null },
          longitud: { not: null },
          ...(dateFilter ? { fecha: dateFilter } : {}),
        },
        _count: { _all: true },
      });

      const userIds = rows.map((row) => row.usuarioId).filter(Boolean);
      const users = userIds.length
        ? await prisma.usuario.findMany({ where: { idUsuario: { in: userIds } } })
        : [];
      const usersById = new Map(users.map((item) => [item.idUsuario, item]));

      for (const row of rows) {
        addUser(usersById.get(row.usuarioId)?.username, row._count._all);
      }
    }

    if (source === 'all' || source === 'inaturalist') {
      const rows = await prisma.inaturalistObservacion.groupBy({
        by: ['usuarioId'],
        where: {
          latitud: { not: null },
          longitud: { not: null },
          ...(dateFilter ? { fecha: dateFilter } : {}),
        },
        _count: { _all: true },
      });

      const userIds = rows.map((row) => row.usuarioId).filter(Boolean);
      const users = userIds.length
        ? await prisma.usuario.findMany({ where: { idUsuario: { in: userIds } } })
        : [];
      const usersById = new Map(users.map((item) => [item.idUsuario, item]));

      for (const row of rows) {
        addUser(usersById.get(row.usuarioId)?.username, row._count._all);
      }
    }

    const data = [...counts.entries()]
      .map(([username, total]) => ({ username, total }))
      .sort((left, right) => right.total - left.total)
      .slice(0, limit);

    response.json({ data, total: data.length });
  }),
);

analyticsRouter.get(
  '/ranking-species',
  asyncHandler(async (request, response) => {
    const dateFilter = buildDateFilter(request.query.dateFrom, request.query.dateTo);
    const source = parseSourceFilter(request.query.source);
    const limit = parseRankingLimit(request.query.limit);
    const counts = new Map();

    const addSpecies = (id, scientificName, taxonomicGroup, total = 1) => {
      if (!id) {
        return;
      }
      const key = String(id);
      const current = counts.get(key) ?? {
        idEspecie: id,
        scientificName: scientificName ?? 'Especie desconocida',
        taxonomicGroup: taxonomicGroup ?? 'Sin grupo',
        views: 0,
      };
      current.views += total;
      counts.set(key, current);
    };

    if (source === 'all' || source === 'odk') {
      const rows = await prisma.observacion.groupBy({
        by: ['especieId'],
        where: {
          latitud: { not: null },
          longitud: { not: null },
          ...(dateFilter ? { fecha: dateFilter } : {}),
        },
        _count: { _all: true },
      });

      const speciesIds = rows.map((row) => row.especieId).filter(Boolean);
      const species = speciesIds.length
        ? await prisma.especie.findMany({
            where: { idEspecie: { in: speciesIds } },
            include: { grupoTaxonomico: true },
          })
        : [];
      const speciesById = new Map(species.map((item) => [item.idEspecie, item]));

      for (const row of rows) {
        const speciesItem = speciesById.get(row.especieId);
        addSpecies(
          row.especieId,
          speciesItem?.nombreCientifico,
          speciesItem?.grupoTaxonomico?.nombre,
          row._count._all,
        );
      }
    }

    if (source === 'all' || source === 'inaturalist') {
      const rows = await prisma.inaturalistObservacion.groupBy({
        by: ['especieId'],
        where: {
          latitud: { not: null },
          longitud: { not: null },
          ...(dateFilter ? { fecha: dateFilter } : {}),
        },
        _count: { _all: true },
      });

      const speciesIds = rows.map((row) => row.especieId).filter(Boolean);
      const species = speciesIds.length
        ? await prisma.especie.findMany({
            where: { idEspecie: { in: speciesIds } },
            include: { grupoTaxonomico: true },
          })
        : [];
      const speciesById = new Map(species.map((item) => [item.idEspecie, item]));

      for (const row of rows) {
        const speciesItem = speciesById.get(row.especieId);
        addSpecies(
          row.especieId,
          speciesItem?.nombreCientifico,
          speciesItem?.grupoTaxonomico?.nombre,
          row._count._all,
        );
      }
    }

    const data = [...counts.values()]
      .sort((left, right) => right.views - left.views)
      .slice(0, limit);

    response.json({ data, total: data.length });
  }),
);
