import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import * as users from '../controllers/users.controller.js';
import * as artisans from '../controllers/artisans.controller.js';
import * as requests from '../controllers/requests.controller.js';
import * as reviews from '../controllers/reviews.controller.js';
import * as messages from '../controllers/messages.controller.js';
import * as estimator from '../controllers/estimator.controller.js';

const r = Router();

r.get('/health', (_req, res) => res.json({ ok: true, service: 'al-asel-api', version: '1' }));

r.get('/estimate', estimator.getEstimate);

r.use(requireAuth);

r.post('/users/bootstrap', users.bootstrap);
r.get('/users/me', users.getMe);
r.patch('/users/me', users.patchMe);

r.get('/artisans', artisans.listArtisans);
r.get('/artisans/match', artisans.matchArtisans);
r.get('/artisans/:artisanId/reviews', reviews.listForArtisan);
r.get('/artisans/:id', artisans.getArtisan);
r.put('/artisans/profile', artisans.upsertProfile);
r.post('/artisans/portfolio', artisans.addPortfolioItem);

r.post('/requests', requests.createRequest);
r.get('/requests/mine', requests.listMyRequests);
r.get('/requests/inbox', requests.listForArtisan);
r.get('/requests/:id', requests.getRequest);
r.patch('/requests/:id/status', requests.patchRequestStatus);

r.post('/reviews', reviews.createReview);

r.get('/conversations', messages.listConversations);
r.post('/conversations', messages.openOrGetConversation);
r.get('/conversations/:id/messages', messages.listMessages);
r.post('/conversations/:id/messages', messages.postMessage);

export default r;
