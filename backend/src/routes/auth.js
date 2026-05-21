import { Router } from 'express';
import bcrypt from 'bcryptjs';

import { prisma } from '../lib/prisma.js';
import { asyncHandler } from '../middleware/async-handler.js';
import { requireAuth } from '../middleware/auth.js';
import {
  generateAccessToken,
  generateRefreshToken,
  hashToken,
  refreshTokenExpiryDate,
} from '../utils/tokens.js';

export const authRouter = Router();

authRouter.post(
  '/login',
  asyncHandler(async (request, response) => {
    const { email, password } = request.body ?? {};
    if (!email || !password) {
      return response.status(400).json({ message: 'Email and password are required' });
    }

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user || !user.isActive) {
      return response.status(401).json({ message: 'Invalid credentials' });
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      return response.status(401).json({ message: 'Invalid credentials' });
    }

    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken();

    await prisma.refreshToken.create({
      data: {
        tokenHash: hashToken(refreshToken),
        userId: user.id,
        expiresAt: refreshTokenExpiryDate(),
      },
    });

    response.json({
      accessToken,
      refreshToken,
      expiresAt: refreshTokenExpiryDate().toISOString(),
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        avatarUrl: user.avatarUrl,
      },
    });
  }),
);

authRouter.post(
  '/refresh',
  asyncHandler(async (request, response) => {
    const { refreshToken } = request.body ?? {};
    if (!refreshToken) {
      return response.status(400).json({ message: 'refreshToken is required' });
    }

    const tokenHash = hashToken(refreshToken);
    const storedToken = await prisma.refreshToken.findUnique({
      where: { tokenHash },
      include: { user: true },
    });

    if (!storedToken || storedToken.expiresAt < new Date() || !storedToken.user.isActive) {
      return response.status(401).json({ message: 'Invalid refresh token' });
    }

    const accessToken = generateAccessToken(storedToken.user);
    response.json({
      accessToken,
      refreshToken,
      expiresAt: storedToken.expiresAt.toISOString(),
      user: {
        id: storedToken.user.id,
        email: storedToken.user.email,
        name: storedToken.user.name,
        role: storedToken.user.role,
        avatarUrl: storedToken.user.avatarUrl,
      },
    });
  }),
);

authRouter.post(
  '/logout',
  requireAuth,
  asyncHandler(async (request, response) => {
    await prisma.refreshToken.deleteMany({ where: { userId: request.user.id } });
    response.json({ message: 'Logged out' });
  }),
);