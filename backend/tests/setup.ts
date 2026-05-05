jest.mock('../src/firebaseAdmin', () => {
  const firestoreMock = {
    collection: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    get: jest.fn().mockResolvedValue({ exists: true, data: () => ({ balance: 'R$ 1.000,00' }) }),
    set: jest.fn().mockResolvedValue(true),
    update: jest.fn().mockResolvedValue(true),
    add: jest.fn().mockResolvedValue({ id: 'mock-id' }),
    delete: jest.fn().mockResolvedValue(true),
    where: jest.fn().mockReturnThis(),
    runTransaction: jest.fn(async (callback) => {
      const transaction = {
        get: jest.fn().mockResolvedValue({ 
          exists: true, 
          data: () => ({ balance: 'R$ 1.000,00', status: 'active', sellerId: 'seller123', startupName: 'EcoToken', quotas: 10, price: 50 })
        }),
        set: jest.fn(),
        update: jest.fn(),
        delete: jest.fn()
      };
      return callback(transaction);
    })
  };

  return {
    db: firestoreMock,
    auth: {
      verifyIdToken: jest.fn().mockResolvedValue({ uid: 'testuser123', email: 'test@example.com' })
    }
  };
});
