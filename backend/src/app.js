import express from 'express';
import cors from 'cors';

import { env } from './config/env.js';
import { healthRouter } from './routes/health.js';
import { speciesRouter } from './routes/species.js';
import { observationsRouter } from './routes/observations.js';
import { mapRouter } from './routes/map.js';
import { analyticsRouter } from './routes/analytics.js';
import { usersRouter } from './routes/users.js';
import { authRouter } from './routes/auth.js';
import { notificationsRouter } from './routes/notifications.js';
import { errorHandler, notFound } from './middleware/error-handler.js';

export const app = express();

app.use(
  cors({
    origin(origin, callback) {
      if (!origin || env.corsOrigins.length === 0 || env.corsOrigins.includes(origin)) {
        callback(null, true);
        return;
      }

      callback(new Error(`Origin not allowed by CORS: ${origin}`));
    },
    credentials: true,
  }),
);

app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));

app.get('/', (request, response) => {
  response.json({
    service: 'Soy Conservación API',
    version: '1.0.0',
    environment: env.nodeEnv,
  });
});

app.use('/health', healthRouter);
app.use('/species', speciesRouter);
app.use('/observations', observationsRouter);
app.use('/map', mapRouter);
app.use('/analytics', analyticsRouter);
app.use('/users', usersRouter);
app.use('/auth', authRouter);
app.use('/notifications', notificationsRouter);

app.use(notFound);
app.use(errorHandler);