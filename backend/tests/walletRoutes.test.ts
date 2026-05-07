import request from 'supertest';
import app from '../src/app';

describe('Wallet Routes', () => {
  it('should return 401 if missing token', async () => {
    const res = await request(app).post('/api/wallet/addFunds').send({ amount: 100 });
    expect(res.statusCode).toEqual(401);
  });

  it('should add funds successfully', async () => {
    const res = await request(app)
      .post('/api/wallet/addFunds')
      .set('Authorization', 'Bearer MOCK_TOKEN')
      .send({ amount: 100 });
    
    expect(res.statusCode).toEqual(200);
    expect(res.body.message).toBe('Funds added successfully');
  });

  it('should fail to add funds with invalid amount', async () => {
    const res = await request(app)
      .post('/api/wallet/addFunds')
      .set('Authorization', 'Bearer MOCK_TOKEN')
      .send({ amount: -50 });
    
    expect(res.statusCode).toEqual(400);
  });

  it('should buy asset successfully', async () => {
    const res = await request(app)
      .post('/api/wallet/buy')
      .set('Authorization', 'Bearer MOCK_TOKEN')
      .send({ 
        startup: { name: 'EcoToken', val: 'R$ 10,00' }, 
        amountToBuy: 100 
      });
    
    expect(res.statusCode).toEqual(200);
    expect(res.body.message).toBe('Asset purchased successfully');
  });

  it('should sell asset successfully', async () => {
    const res = await request(app)
      .post('/api/wallet/sell')
      .set('Authorization', 'Bearer MOCK_TOKEN')
      .send({ asset: { id: 'asset123' } });
    
    expect(res.statusCode).toEqual(200);
    expect(res.body.message).toBe('Asset sold successfully');
  });
});
