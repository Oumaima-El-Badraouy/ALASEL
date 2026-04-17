import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import * as auth from '../controllers/auth.controller.js';
import * as users from '../controllers/users.controller.js';
import * as artisans from '../controllers/artisans.controller.js';
import * as requests from '../controllers/requests.controller.js';
import * as reviews from '../controllers/reviews.controller.js';
import * as messages from '../controllers/messages.controller.js';
import * as estimator from '../controllers/estimator.controller.js';
import * as posts from '../controllers/posts.controller.js';
import * as follows from '../controllers/follows.controller.js';
import * as favorites from '../controllers/favorites.controller.js';
import * as postEngagement from '../controllers/postEngagement.controller.js';

const r = Router();

r.get('/health', (_req, res) => res.json({ ok: true, service: 'al-asel-api', version: '3' }));

r.get('/estimate', estimator.getEstimate);
r.post('/auth/register', auth.register);
r.post('/auth/login', auth.login);

r.use(requireAuth);

r.post('/users/bootstrap', users.bootstrap);
r.get('/users/me', users.getMe);
r.get('/users/me/following', follows.listFollowing);
/** Liste des posts favoris (client) — alias stable pour éviter tout conflit de route */
r.get('/users/me/favorite-posts', posts.listFavorites);
r.patch('/users/me', users.patchMe);
r.get('/users/peer/:peerId/contact', users.getPeerContact);

r.get('/posts/feed', posts.listFeed);
r.get('/posts/mine', posts.listMine);
r.get('/posts/favorites', posts.listFavorites);
r.get('/posts/:postId/comments', postEngagement.listComments);
r.post('/posts/:postId/comments', postEngagement.addComment);
r.get('/posts/:postId/likes', postEngagement.listPostLikes);
r.post('/posts/:postId/like', postEngagement.toggleLike);
r.post('/posts/:postId/favorite', favorites.addPostFavorite);
r.delete('/posts/:postId/favorite', favorites.removePostFavorite);
r.post('/posts', posts.createPost);
r.patch('/posts/:id', posts.updatePost);
r.delete('/posts/:id', posts.deletePost);

r.post('/follow/:followingId', follows.follow);
r.delete('/follow/:followingId', follows.unfollow);
r.get('/follow/:followingId/status', follows.isFollowing);
r.get('/artisans/:artisanId/followers-count', follows.followersCount);

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
r.post('/conversations/:id/read', messages.markConversationRead);
r.get('/conversations/:id/messages', messages.listMessages);
r.post('/conversations/:id/messages', messages.postMessage);

export default r;
