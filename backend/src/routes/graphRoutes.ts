import { Router, Request, Response, NextFunction } from 'express';
import { db, auth } from '../firebaseAdmin';

const router = Router();

type GraphPoint = {
	date: string;
	value: number;
	invested: number;
	quantity: number;
};

const requireAuth = async (req: Request, res: Response, next: NextFunction) => {
	const authHeader = req.headers.authorization;
	if (!authHeader || !authHeader.startsWith('Bearer ')) {
		res.status(401).json({ error: 'Unauthorized: Missing token' });
		return;
	}

	const token = authHeader.split('Bearer ')[1]!;
	try {
		const decoded = await auth.verifyIdToken(token);
		(req as any).user = decoded;
		next();
	} catch (error) {
		res.status(401).json({ error: 'Unauthorized: Invalid token' });
	}
};

const parseCurrency = (value: string) => {
	const cleanValue = value.replace(/[^0-9,.-]/g, '').replace(',', '.');
	const parsed = Number.parseFloat(cleanValue);
	return Number.isNaN(parsed) ? 0 : parsed;
};

const formatCurrency = (value: number) => `R$ ${value.toFixed(2).replace('.', ',')}`;

const parseQuantity = (value: unknown) => {
	const raw = value?.toString().split(' ')[0] ?? '0';
	return Number.parseFloat(raw.replace(',', '.')) || 0;
};

const toIsoDate = (value: unknown) => {
	if (!value) return new Date(0).toISOString();
	if (typeof value === 'string') return value;
	if (value instanceof Date) return value.toISOString();

	if (typeof value === 'object' && value !== null && 'toDate' in value) {
		return (value as { toDate: () => Date }).toDate().toISOString();
	}

	return new Date(0).toISOString();
};

const buildSeriesFromHistory = (history: Array<Record<string, any>>, currentPrice: number): GraphPoint[] => {
	const ordered = [...history].sort(
		(left, right) => new Date(toIsoDate(left.date)).getTime() - new Date(toIsoDate(right.date)).getTime()
	);

	let quantity = 0;
	let invested = 0;

	return ordered.map((entry) => {
		const amount = parseCurrency(entry.amount?.toString() ?? 'R$ 0,00');
		const quotas = parseQuantity(entry.quotas);
		const type = entry.type?.toString();

		if (type === 'buy' || type === 'deposit') {
			invested += amount;
			quantity += quotas;
		} else if (type === 'sell') {
			invested = Math.max(0, invested - amount);
			quantity = Math.max(0, quantity - quotas);
		}

		return {
			date: toIsoDate(entry.date),
			value: quantity > 0 ? quantity * currentPrice : invested,
			invested,
			quantity,
		};
	});
};

router.get('/summary', requireAuth, async (req: Request, res: Response) => {
	try {
		const user = (req as any).user;

		const [walletDoc, assetsSnapshot, acquisitionsSnapshot, startupsSnapshot] = await Promise.all([
			db.collection('users').doc(user.uid).collection('wallet').doc('main').get(),
			db.collection('users').doc(user.uid).collection('assets').get(),
			db.collection('users').doc(user.uid).collection('acquisitions').get(),
			db.collection('startups').get(),
		]);

		const startupsByName = new Map<string, Record<string, any>>();
		startupsSnapshot.docs.forEach((doc) => {
			startupsByName.set(doc.data().name, { id: doc.id, ...doc.data() });
		});

		const assets: Array<Record<string, any>> = assetsSnapshot.docs.map((doc) => ({
			id: doc.id,
			...doc.data(),
		}));
		const currentValue = assets.reduce((sum, asset) => {
			const startup = startupsByName.get(String(asset.name ?? ''));
			const currentPrice = parseCurrency(
				startup?.val?.toString() ?? asset.value?.toString() ?? 'R$ 0,00'
			);
			const quantity = parseQuantity(asset.amount);
			return sum + quantity * currentPrice;
		}, 0);

		const totalInvested = assets.reduce(
			(sum, asset) => sum + parseCurrency(asset.value?.toString() ?? 'R$ 0,00'),
			0
		);
		const variationReais = currentValue - totalInvested;
		const variationPercentual = totalInvested > 0 ? (variationReais / totalInvested) * 100 : 0;
		const walletBalance = walletDoc.exists ? walletDoc.data()?.balance?.toString() ?? 'R$ 0,00' : 'R$ 0,00';

		res.status(200).json({
			walletBalance,
			totalInvested: formatCurrency(totalInvested),
			currentValue: formatCurrency(currentValue),
			variationReais: formatCurrency(variationReais),
			variationPercentual: `${variationPercentual.toFixed(2)}%`,
			assetsCount: assets.length,
			transactionsCount: acquisitionsSnapshot.size,
		});
	} catch (error: any) {
		console.error(error);
		res.status(500).json({ error: error.message });
	}
});

router.get('/history', requireAuth, async (req: Request, res: Response) => {
	try {
		const user = (req as any).user;
		const startupNameValue = req.query.startupName;
		const startupName = typeof startupNameValue === 'string'
			? startupNameValue.trim()
			: Array.isArray(startupNameValue)
				? String(startupNameValue[0] ?? '').trim()
				: '';
		const type = req.query.type?.toString().trim();
		const startupNameNormalized = startupName.toLowerCase();

		let query: any = db.collection('users').doc(user.uid).collection('acquisitions').orderBy('date', 'asc');

		if (type) {
			query = query.where('type', '==', type);
		}

		const snapshot = await query.get();
		const items = snapshot.docs
			.map((doc: any) => ({ id: doc.id, ...doc.data() }))
			.filter((entry: any) => {
				if (!startupName) return true;
				const title = String(Array.isArray(entry.title) ? entry.title.join(' ') : entry.title ?? '');
				return title.toLowerCase().includes(startupNameNormalized);
			})
			.map((entry: any) => ({
				...entry,
				date: toIsoDate(entry.date),
			}));

		res.status(200).json({ items, count: items.length });
	} catch (error: any) {
		console.error(error);
		res.status(500).json({ error: error.message });
	}
});

router.get('/asset/:startupName', requireAuth, async (req: Request, res: Response) => {
	try {
		const user = (req as any).user;
		const startupName = req.params.startupName;

		const [assetSnapshot, acquisitionsSnapshot, startupSnapshot] = await Promise.all([
			db.collection('users').doc(user.uid).collection('assets').where('name', '==', startupName).get(),
			db.collection('users').doc(user.uid).collection('acquisitions').orderBy('date', 'asc').get(),
			db.collection('startups').where('name', '==', startupName).limit(1).get(),
		]);

		const startupDoc = startupSnapshot.docs[0];
		const currentPrice = parseCurrency(startupDoc?.data()?.val?.toString() ?? 'R$ 0,00');
		const assetDoc = assetSnapshot.docs[0];
		const asset = assetDoc ? { id: assetDoc.id, ...assetDoc.data() } : null;
		const startupNameNormalized = String(startupName).toLowerCase();
		const history = acquisitionsSnapshot.docs
			.map((doc: any) => ({ id: doc.id, ...doc.data() }))
			.filter((entry: any) => String(entry.title ?? '').toLowerCase().includes(startupNameNormalized));

		const series = buildSeriesFromHistory(history, currentPrice);
		const lastPoint = series[series.length - 1] ?? { value: 0, invested: 0, quantity: 0 };
		const variationReais = lastPoint.value - lastPoint.invested;
		const variationPercentual = lastPoint.invested > 0 ? (variationReais / lastPoint.invested) * 100 : 0;

		res.status(200).json({
			startupName,
			startup: startupDoc ? { id: startupDoc.id, ...startupDoc.data() } : null,
			asset,
			currentPrice: formatCurrency(currentPrice),
			summary: {
				totalInvested: formatCurrency(lastPoint.invested),
				currentValue: formatCurrency(lastPoint.value),
				variationReais: formatCurrency(variationReais),
				variationPercentual: `${variationPercentual.toFixed(2)}%`,
				quantity: lastPoint.quantity,
			},
			series,
			historyCount: history.length,
		});
	} catch (error: any) {
		console.error(error);
		res.status(500).json({ error: error.message });
	}
});

export default router;