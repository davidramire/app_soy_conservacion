import { Router } from 'express';

import { prisma } from '../lib/prisma.js';
import { asyncHandler } from '../middleware/async-handler.js';
import { requireAuth } from '../middleware/auth.js';
import { parsePagination, buildPagedResponse } from '../utils/http.js';

export const usersRouter = Router();

usersRouter.get('/me', requireAuth, asyncHandler(async (request, response) => {
  response.json(request.user);
}));

usersRouter.get(
  '/',
  requireAuth,
  asyncHandler(async (request, response) => {
    const { page, limit, skip } = parsePagination(request.query);
    const search = String(request.query.search ?? request.query.query ?? '').trim();

    const where = search
      ? {
          OR: [
            { name: { contains: search, mode: 'insensitive' } },
            { email: { contains: search, mode: 'insensitive' } },
            { role: { contains: search, mode: 'insensitive' } },
          ],
        }
      : {};

    const [items, total] = await prisma.$transaction([
      prisma.user.findMany({
        where,
        orderBy: { updatedAt: 'desc' },
        skip,
        take: limit,
        select: {
          id: true,
          email: true,
          name: true,
          role: true,
          avatarUrl: true,
          isActive: true,
          createdAt: true,
          updatedAt: true,
        },
      }),
      prisma.user.count({ where }),
    ]);

    response.json(buildPagedResponse(items, total, page, limit));
  }),
);