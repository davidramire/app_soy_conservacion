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

    const where = {
      ...(speciesId ? { speciesId } : {}),
      ...(userId ? { userId } : {}),
      ...(search
        ? {
            OR: [
              { notes: { contains: search, mode: 'insensitive' } },
              { sourceUrl: { contains: search, mode: 'insensitive' } },
              {
                species: {
                  is: {
                    OR: [
                      { commonName: { contains: search, mode: 'insensitive' } },
                      { scientificName: { contains: search, mode: 'insensitive' } },
                    ],
                  },
                },
              },
            ],
          }
        : {}),
    };

    const [items, total] = await prisma.$transaction([
      prisma.observation.findMany({
        where,
        orderBy: { observedAt: 'desc' },
        skip,
        take: limit,
        include: {
          species: true,
          user: {
            select: {
              id: true,
              name: true,
              email: true,
              role: true,
              avatarUrl: true,
            },
          },
        },
      }),
      prisma.observation.count({ where }),
    ]);

    response.json(buildPagedResponse(items, total, page, limit));
  }),
);

observationsRouter.get(
  '/:id',
  asyncHandler(async (request, response) => {
    const observation = await prisma.observation.findUnique({
      where: { id: request.params.id },
      include: {
        species: true,
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            role: true,
            avatarUrl: true,
          },
        },
      },
    });

    if (!observation) {
      return response.status(404).json({ message: 'Observation not found' });
    }

    response.json(observation);
  }),
);