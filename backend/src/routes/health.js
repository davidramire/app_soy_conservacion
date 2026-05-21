import { Router } from 'express';

import { prisma } from '../lib/prisma.js';
import { asyncHandler } from '../middleware/async-handler.js';

export const healthRouter = Router();

healthRouter.get(
  '/',
  asyncHandler(async (request, response) => {
    await prisma.$queryRaw`SELECT 1`;
    response.json({
      status: 'ok',
      database: 'connected',
      timestamp: new Date().toISOString(),
    });
  }),
);