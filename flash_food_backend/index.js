const express = require('express');
const cors = require('cors');
const session = require('express-session');
const bodyParser = require('body-parser');
const passport = require('passport');
const authRoutes = require('./routes/auth');
const foodsRoutes = require('./routes/foods');
const cartRoutes = require('./routes/cart');
const ordersRoutes = require('./routes/orders');
const notificationsRoutes = require('./routes/notifications');
const chatRoutes = require('./routes/chat');
const aiRoutes = require('./routes/ai');
require('dotenv').config({ path: './env' });
require('./middleware/passport')

const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const app = express();
app.use(cors());
app.use(express.json());

app.use(session({
  secret: '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',
  resave: false,
  saveUninitialized: false
}));

app.use(passport.initialize());
app.use(passport.session());
app.use('/api/auth', authRoutes);
app.use('/api/foods', foodsRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/orders', ordersRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/user', require('./routes/user'));
app.use('/api/ai', aiRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));