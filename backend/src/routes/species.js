import { Router } from 'express';

import { prisma } from '../lib/prisma.js';
import { asyncHandler } from '../middleware/async-handler.js';
import { parsePagination, buildPagedResponse } from '../utils/http.js';

export const speciesRouter = Router();

speciesRouter.get(
  '/',
  asyncHandler(async (request, response) => {
    const { page, limit, skip } = parsePagination(request.query);
    const search = String(request.query.search ?? request.query.query ?? '').trim();
    const kingdom = String(request.query.kingdom ?? '').trim();
    const category = String(request.query.category ?? '').trim();

    const where = {
      ...(kingdom || category
        ? {
            grupoTaxonomico: {
              is: {
                nombre: {
                  contains: kingdom || category,
                  mode: 'insensitive',
                },
              },
            },
          }
        : {}),
      ...(search
        ? {
            OR: [
              { nombreCientifico: { contains: search, mode: 'insensitive' } },
              {
                grupoTaxonomico: {
                  is: {
                    nombre: { contains: search, mode: 'insensitive' },
                  },
                },
              },
            ],
          }
        : {}),
    };

    const [items, total] = await prisma.$transaction([
      prisma.especie.findMany({
        where,
        orderBy: { nombreCientifico: 'asc' },
        skip,
        take: limit,
        include: {
          grupoTaxonomico: true,
        },
      }),
      prisma.especie.count({ where }),
    ]);

    response.json(
      buildPagedResponse(
        items.map((item) => ({
          id: item.idEspecie.toString(),
          name: item.nombreCientifico,
          scientificName: item.nombreCientifico,
          kingdom: item.grupoTaxonomico?.nombre ?? null,
          category: item.grupoTaxonomico?.nombre ?? null,
          description: null,
          imageUrl: null,
          sourceUrl: null,
          groupName: item.grupoTaxonomico?.nombre ?? null,
        })),
        total,
        page,
        limit,
      ),
    );
  }),
);

speciesRouter.get(
  '/:id',
  asyncHandler(async (request, response) => {
    const id = Number(request.params.id);
    const species = await prisma.especie.findUnique({
      where: { idEspecie: Number.isNaN(id) ? -1 : id },
      include: {
        grupoTaxonomico: true,
        observaciones: {
          orderBy: { fecha: 'desc' },
          take: 10,
        },
        observacionesInat: {
          orderBy: { fecha: 'desc' },
          take: 10,
        },
      },
    });

    if (!species) {
      return response.status(404).json({ message: 'Species not found' });
    }

    response.json({
      id: species.idEspecie.toString(),
      name: species.nombreCientifico,
      scientificName: species.nombreCientifico,
      kingdom: species.grupoTaxonomico?.nombre ?? null,
      category: species.grupoTaxonomico?.nombre ?? null,
      description: null,
      imageUrl: null,
      sourceUrl: null,
      groupName: species.grupoTaxonomico?.nombre ?? null,
      observations: [...species.observaciones, ...species.observacionesInat].map((item) => ({
        id: item.idObservacion?.toString?.() ?? item.idInaturalistObservacion?.toString?.() ?? '',
        observedAt: item.fecha,
        latitude: item.latitud,
        longitude: item.longitud,
      })),
    });
  }),
);