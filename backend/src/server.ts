import { createServer } from 'http';
import { Server, Socket } from 'socket.io';
import { db, auth } from './firebaseAdmin';
import * as dotenv from 'dotenv';
import app from './app';

dotenv.config();

const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: { origin: '*' }
});

// Middleware de Autenticação Socket.io
io.use(async (socket, next) => {
  try {
    const token = socket.handshake.auth.token;
    if (!token) return next(new Error('Authentication error: Token missing'));

    const decodedToken = await auth.verifyIdToken(token);
    socket.data.user = decodedToken;
    next();
  } catch (error) {
    next(new Error('Authentication error: Invalid Token'));
  }
});

io.on('connection', (socket: Socket) => {
  const user = socket.data.user;
  console.log(`🔌 Usuário conectado: ${user.uid} (Socket: ${socket.id})`);

  // Ouvir Carteira do Usuário (Wallet)
  const walletRef = db.collection('users').doc(user.uid).collection('wallet').doc('main');

  const unsubscribeWallet = walletRef.onSnapshot((doc) => {
    if (doc.exists) {
      socket.emit('wallet_update', doc.data());
    } else {
      socket.emit('wallet_update', null);
    }
  }, (err) => {
    console.error(`Erro ao escutar a carteira do usuário ${user.uid}:`, err);
  });

  // Ouvir Ativos (Assets)
  const assetsRef = db.collection('users').doc(user.uid).collection('assets');
  const unsubscribeAssets = assetsRef.onSnapshot((snapshot) => {
    const assets = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    socket.emit('assets_update', assets);
  });

  // Desconectar: limpa as subscrições do Firebase
  socket.on('disconnect', () => {
    console.log(`❌ Usuário desconectado: ${user.uid} (Socket: ${socket.id})`);
    unsubscribeWallet();
    unsubscribeAssets();
  });
});

const PORT = process.env.PORT || 3000;
httpServer.listen(PORT, () => {
  console.log(`🚀 Servidor rodando na porta ${PORT}`);
});
