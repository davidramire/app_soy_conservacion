import crypto from 'crypto';
import jwt from 'jsonwebtoken';

import { env } from '../config/env.js';

export function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

export function generateRefreshToken() {
  return crypto.randomBytes(48).toString('hex');
}

export function generateAccessToken(user) {
  return jwt.sign(
    {
      sub: user.id,
      email: user.email,
      role: user.role,
    },
    env.jwtAccessSecret,
    { expiresIn: env.jwtAccessExpiresIn },
  );
}

export function verifyAccessToken(token) {
  return jwt.verify(token, env.jwtAccessSecret);
}

export function getBearerToken(request) {
  const authorization = request.headers.authorization ?? '';
  const [scheme, token] = authorization.split(' ');
  if (scheme?.toLowerCase() !== 'bearer' || !token) {
    return null;
  }
  return token;
}

export function refreshTokenExpiryDate() {
  const match = /^([0-9]+)([smhd])$/i.exec(env.jwtRefreshExpiresIn);
  const amount = Number(match?.[1] ?? 30);
  const unit = (match?.[2] ?? 'd').toLowerCase();
  const multiplier = {
    s: 1000,
    m: 60 * 1000,
    h: 60 * 60 * 1000,
    d: 24 * 60 * 60 * 1000,
  }[unit];
  return new Date(Date.now() + amount * multiplier);
}