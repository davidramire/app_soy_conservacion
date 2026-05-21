import { prisma } from '../lib/prisma.js';
import { getBearerToken, verifyAccessToken } from '../utils/tokens.js';

export async function requireAuth(request, response, next) {
  try {
    const token = getBearerToken(request);
    if (!token) {
      return response.status(401).json({ message: 'Missing bearer token' });
    }

    const decoded = verifyAccessToken(token);
    const userId = decoded.sub;
    const user = await prisma.user.findUnique({ where: { id: userId } });

    if (!user || !user.isActive) {
      return response.status(401).json({ message: 'Unauthorized' });
    }

    request.user = user;
    next();
  } catch (error) {
    return response.status(401).json({ message: 'Invalid or expired token' });
  }
}