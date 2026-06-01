import { Router } from 'express';

import { prisma } from '../lib/prisma.js';
import { asyncHandler } from '../middleware/async-handler.js';
import { averageCoordinates } from '../utils/http.js';
import { buildDateFilter } from '../utils/date-filters.js';

export const mapRouter = Router();

mapRouter.get(
  '/',
  asyncHandler(async (request, response) => {
    const limit = Math.min(Math.max(Number(request.query.limit ?? 5000), 1), 10000);
    const dateFilter = buildDateFilter(request.query.dateFrom, request.query.dateTo);
    const [observations, inaturalistObservations] = await Promise.all([
      prisma.observacion.findMany({
        where: {
          latitud: { not: null },
          longitud: { not: null },
          ...(dateFilter ? { fecha: dateFilter } : {}),
        },
        take: limit,
        orderBy: { fecha: 'desc' },
        include: {
          especie: {
            include: {
              grupoTaxonomico: true,
            },
          },
          usuario: true,
          fuente: true,
        },
      }),
      prisma.inaturalistObservacion.findMany({
        where: {
          latitud: { not: null },
          longitud: { not: null },
          ...(dateFilter ? { fecha: dateFilter } : {}),
        },
        take: limit,
        orderBy: { fecha: 'desc' },
        include: {
          especie: {
            include: {
              grupoTaxonomico: true,
            },
          },
          usuario: true,
          grupoTaxonomico: true,
          fuente: true,
        },
      }),
    ]);

    const markers = [
      ...observations.map((observation) => ({
        id: `odk-${observation.idObservacion}`,
        latitude: observation.latitud,
        longitude: observation.longitud,
        title: observation.especie?.nombreCientifico ?? 'Observación',
        subtitle: observation.usuario?.username ?? observation.fuente?.nombre ?? 'ODK',
        imageUrl: observation.foto ?? null,
        observedAt: observation.fecha,
        sourceUrl: null,
        sourceType: 'odk',
        speciesId: observation.especieId?.toString?.() ?? null,
        groupName: observation.especie?.grupoTaxonomico?.nombre ?? null,
        kingdom: observation.especie?.grupoTaxonomico?.nombre ?? null,
        category: observation.especie?.grupoTaxonomico?.nombre ?? null,
      })),
      ...inaturalistObservations.map((observation) => ({
        id: `inat-${observation.idInaturalistObservacion}`,
        latitude: observation.latitud,
        longitude: observation.longitud,
        title: observation.especie?.nombreCientifico ?? 'iNaturalist',
        subtitle: observation.usuario?.username ?? observation.fuente?.nombre ?? 'iNaturalist',
        imageUrl: observation.foto ?? null,
        observedAt: observation.fecha,
        sourceUrl: observation.urlInaturalist ?? null,
        sourceType: 'inaturalist',
        speciesId: observation.especieId?.toString?.() ?? null,
        groupName: observation.grupoTaxonomico?.nombre ?? observation.especie?.grupoTaxonomico?.nombre ?? null,
        kingdom: observation.grupoTaxonomico?.nombre ?? observation.especie?.grupoTaxonomico?.nombre ?? null,
        category: observation.grupoTaxonomico?.nombre ?? observation.especie?.grupoTaxonomico?.nombre ?? null,
      })),
    ].sort((left, right) => {
      const leftTime = left.observedAt ? new Date(left.observedAt).getTime() : 0;
      const rightTime = right.observedAt ? new Date(right.observedAt).getTime() : 0;
      return rightTime - leftTime;
    });

    response.json({
      center: averageCoordinates(markers) ?? { latitude: 4.5709, longitude: -74.2973 },
      zoom: markers.length > 0 ? 5 : 4,
      markers,
    });
  }),
);