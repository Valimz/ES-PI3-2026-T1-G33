import express from 'express';
import cors from 'cors';
import walletRoutes from './routes/walletRoutes';
import p2pRoutes from './routes/p2pRoutes';
import notificationRoutes from './routes/notificationRoutes';

const app = express();
app.use(cors());
app.use(express.json());

// Registrar rotas REST
app.use('/api/wallet', walletRoutes);
app.use('/api/p2p', p2pRoutes);
app.use('/api/notifications', notificationRoutes);

export default app;
