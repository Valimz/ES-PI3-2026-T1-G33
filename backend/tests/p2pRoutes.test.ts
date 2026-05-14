import request from 'supertest';
import app from '../src/app';

describe('P2P Routes', () => {
  it('should return 401 if missing token', async () => {
    const res = await request(app).post('/api/p2p/createOffer').send({});
    expect(res.statusCode).toEqual(401);
  });

  it('should create an offer successfully', async () => {
    const res = await request(app)
      .post('/api/p2p/createOffer')
      .set('Authorization', 'Bearer MOCK_TOKEN')
      .send({ 
        asset: { name: 'EcoToken', amount: '10 ET' }, 
        price: 50 
      });
    
    expect(res.statusCode).toEqual(200);
    expect(res.body.message).toBe('Offer created successfully');
  });

  it('should make a counter offer successfully', async () => {
    const res = await request(app)
      .post('/api/p2p/makeCounterOffer')
      .set('Authorization', 'Bearer MOCK_TOKEN')
      .send({ 
        offerId: 'offer123', 
        proposedPrice: 40 
      });
    
    expect(res.statusCode).toEqual(200);
    expect(res.body.message).toBe('Counter offer made successfully');
  });

  it('should accept an offer successfully', async () => {
    const res = await request(app)
      .post('/api/p2p/acceptOffer')
      .set('Authorization', 'Bearer MOCK_TOKEN')
      .send({ 
        offerId: 'offer123'
      });
    
    expect(res.statusCode).toEqual(200);
    expect(res.body.message).toBe('Offer accepted successfully');
  });
});
