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
      ...(kingdom ? { kingdom } : {}),
      ...(category ? { category } : {}),
      ...(search
        ? {
            OR: [
              { commonName: { contains: search, mode: 'insensitive' } },
              { scientificName: { contains: search, mode: 'insensitive' } },
              { description: { contains: search, mode: 'insensitive' } },
            ],
          }
        : {}),
    };

    const [items, total] = await prisma.$transaction([
      prisma.species.findMany({
        where,
        orderBy: { updatedAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.species.count({ where }),
    ]);

    response.json(buildPagedResponse(items, total, page, limit));
  }),
);

speciesRouter.get(
  '/:id',
  asyncHandler(async (request, response) => {
    const species = await prisma.species.findUnique({
      where: { id: request.params.id },
      include: {
        observations: {
          orderBy: { observedAt: 'desc' },
          take: 10,
        },
      },
    });

    if (!species) {
      return response.status(404).json({ message: 'Species not found' });
    }

    response.json(species);
  }),
);