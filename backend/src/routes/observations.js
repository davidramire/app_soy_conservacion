import { Router } from 'express';

import { prisma } from '../lib/prisma.js';
import { asyncHandler } from '../middleware/async-handler.js';
import { parsePagination, buildPagedResponse } from '../utils/http.js';

export const observationsRouter = Router();

observationsRouter.get(
  '/',
  asyncHandler(async (request, response) => {
    const { page, limit, skip } = parsePagination(request.query);
    const speciesId = String(request.query.speciesId ?? '').trim();
    const userId = String(request.query.userId ?? '').trim();
    const search = String(request.query.search ?? request.query.query ?? '').trim();

    const include = {
      especie: {
        include: {
          grupoTaxonomico: true,
        },
      },
      usuario: true,
      fuente: true,
    };

    const [observaciones, observacionesInat] = await Promise.all([
      prisma.observacion.findMany({
        where: {
          ...(speciesId ? { especieId: Number(speciesId) } : {}),
          ...(userId ? { usuarioId: Number(userId) } : {}),
          ...(search
            ? {
                OR: [
                  { instanceId: { contains: search, mode: 'insensitive' } },
                  { foto: { contains: search, mode: 'insensitive' } },
                  { audio: { contains: search, mode: 'insensitive' } },
                  {
                    especie: {
                      is: {
                        nombreCientifico: { contains: search, mode: 'insensitive' },
                      },
                    },
                  },
                  {
                    fuente: {
                      is: {
                        nombre: { contains: search, mode: 'insensitive' },
                      },
                    },
                  },
                ],
              }
            : {}),
        },
        orderBy: { fecha: 'desc' },
        skip,
        take: limit,
        include,
      }),
      prisma.inaturalistObservacion.findMany({
        where: {
          ...(speciesId ? { especieId: Number(speciesId) } : {}),
          ...(userId ? { usuarioId: Number(userId) } : {}),
          ...(search
            ? {
                OR: [
                  { inaturalistId: { contains: search, mode: 'insensitive' } },
                  { urlInaturalist: { contains: search, mode: 'insensitive' } },
                  {
                    especie: {
                      is: {
                        nombreCientifico: { contains: search, mode: 'insensitive' },
                      },
                    },
                  },
                ],
              }
            : {}),
        },
        orderBy: { fecha: 'desc' },
        skip,
        take: limit,
        include,
      }),
    ]);

    const items = [
      ...observaciones.map((item) => ({
        id: `odk-${item.idObservacion}`,
        speciesId: item.especieId.toString(),
        speciesName: item.especie?.nombreCientifico ?? null,
        observerName: item.usuario?.username ?? null,
        notes: item.audio ?? item.foto ?? null,
        imageUrl: item.foto ?? null,
        latitude: item.latitud,
        longitude: item.longitud,
        observedAt: item.fecha,
        sourceUrl: null,
        sourceType: 'odk',
      })),
      ...observacionesInat.map((item) => ({
        id: `inat-${item.idInaturalistObservacion}`,
        speciesId: item.especieId.toString(),
        speciesName: item.especie?.nombreCientifico ?? null,
        observerName: item.usuario?.username ?? null,
        notes: item.audio ?? item.foto ?? item.qualityGrade ?? null,
        imageUrl: item.foto ?? null,
        latitude: item.latitud,
        longitude: item.longitud,
        observedAt: item.fecha,
        sourceUrl: item.urlInaturalist ?? null,
        sourceType: 'inaturalist',
      })),
    ].sort((left, right) => {
      const leftTime = left.observedAt ? new Date(left.observedAt).getTime() : 0;
      const rightTime = right.observedAt ? new Date(right.observedAt).getTime() : 0;
      return rightTime - leftTime;
    });

    response.json(buildPagedResponse(items, items.length, page, limit));
  }),
);

observationsRouter.get(
  '/:id',
  asyncHandler(async (request, response) => {
    const observationId = String(request.params.id);
    const [odkObservation, inaturalistObservation] = await Promise.all([
      prisma.observacion.findFirst({
        where: {
          OR: [
            { idObservacion: Number(observationId.replace(/^odk-/, '')) || -1 },
            { instanceId: observationId },
          ],
        },
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
      prisma.inaturalistObservacion.findFirst({
        where: {
          OR: [
            { idInaturalistObservacion: Number(observationId.replace(/^inat-/, '')) || -1 },
            { inaturalistId: observationId },
          ],
        },
        include: {
          especie: {
            include: {
              grupoTaxonomico: true,
            },
          },
          usuario: true,
          fuente: true,
          grupoTaxonomico: true,
        },
      }),
    ]);

    const observation = odkObservation ?? inaturalistObservation;

    if (!observation) {
      return response.status(404).json({ message: 'Observation not found' });
    }

    if (odkObservation) {
      response.json({
        id: `odk-${odkObservation.idObservacion}`,
        speciesId: odkObservation.especieId.toString(),
        speciesName: odkObservation.especie?.nombreCientifico ?? null,
        observerName: odkObservation.usuario?.username ?? null,
        notes: odkObservation.audio ?? odkObservation.foto ?? null,
        imageUrl: odkObservation.foto ?? null,
        latitude: odkObservation.latitud,
        longitude: odkObservation.longitud,
        observedAt: odkObservation.fecha,
        sourceUrl: null,
        sourceType: 'odk',
      });
      return;
    }

    response.json({
      id: `inat-${inaturalistObservation.idInaturalistObservacion}`,
      speciesId: inaturalistObservation.especieId.toString(),
      speciesName: inaturalistObservation.especie?.nombreCientifico ?? null,
      observerName: inaturalistObservation.usuario?.username ?? null,
      notes: inaturalistObservation.audio ?? inaturalistObservation.foto ?? inaturalistObservation.qualityGrade ?? null,
      imageUrl: inaturalistObservation.foto ?? null,
      latitude: inaturalistObservation.latitud,
      longitude: inaturalistObservation.longitud,
      observedAt: inaturalistObservation.fecha,
      sourceUrl: inaturalistObservation.urlInaturalist ?? null,
      sourceType: 'inaturalist',
    });
  }),
);