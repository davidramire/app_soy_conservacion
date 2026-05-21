import { Router } from 'express';

import { prisma } from '../lib/prisma.js';
import { asyncHandler } from '../middleware/async-handler.js';
import { averageCoordinates } from '../utils/http.js';

export const mapRouter = Router();

mapRouter.get(
  '/',
  asyncHandler(async (request, response) => {
    const limit = Math.min(Math.max(Number(request.query.limit ?? 500), 1), 2000);
    const observations = await prisma.observation.findMany({
      where: {
        latitude: { not: null },
        longitude: { not: null },
      },
      take: limit,
      orderBy: { observedAt: 'desc' },
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

    const markers = observations.map((observation) => ({
      id: observation.id,
      latitude: observation.latitude,
      longitude: observation.longitude,
      title: observation.species?.commonName ?? observation.species?.scientificName ?? 'Observación',
      subtitle: observation.user?.name ?? observation.user?.email ?? null,
      imageUrl: observation.imageUrl ?? observation.species?.imageUrl ?? null,
      observedAt: observation.observedAt,
      sourceUrl: observation.sourceUrl,
    }));

    response.json({
      center: averageCoordinates(markers) ?? { latitude: 4.5709, longitude: -74.2973 },
      zoom: markers.length > 0 ? 5 : 4,
      markers,
    });
  }),
);