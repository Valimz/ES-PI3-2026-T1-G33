import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream para listar todas as startups
  Stream<List<Map<String, dynamic>>> getStartups() {
    return _db.collection('startups').snapshots().map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList()).asBroadcastStream();
  }

  // Stream para obter os dados da carteira do usuário logado
  Stream<Map<String, dynamic>?> getWalletData() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db.collection('users').doc(user.uid).collection('wallet').doc('main').snapshots().map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    }).asBroadcastStream();
  }

  // Stream para listar os ativos comprados pelo usuário
  Stream<List<Map<String, dynamic>>> getUserAssets() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db.collection('users').doc(user.uid).collection('assets').snapshots().map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList()).asBroadcastStream();
  }

  // Stream para listar histórico de aquisições/transações
  Stream<List<Map<String, dynamic>>> getUserAcquisitions() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db.collection('users').doc(user.uid).collection('acquisitions')
        .orderBy('date', descending: true)
        .snapshots().map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList()).asBroadcastStream();
  }

  // --- MÉTODOS DE NEGOCIAÇÃO E CARTEIRA ---
  
  // Utilitário para formatar/desformatar moeda (BRL)
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  double parseCurrency(String currencyStr) {
    try {
      // Remove tudo que não for número ou vírgula, e converte vírgula pra ponto
      String cleanString = currencyStr.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.');
      return double.tryParse(cleanString) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Adicionar fundos à carteira
  Future<void> addFunds(double amountToAdd) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    final walletRef = _db.collection('users').doc(user.uid).collection('wallet').doc('main');
    
    return _db.runTransaction((transaction) async {
      final walletDoc = await transaction.get(walletRef);
      
      if (!walletDoc.exists) {
        // Criar carteira caso ela não exista
        transaction.set(walletRef, {
          'balance': _currencyFormat.format(amountToAdd),
          'appreciation': '+ 0,0%',
        });
      } else {
        final data = walletDoc.data()!;
        final balanceStr = data['balance'] ?? 'R\$ 0,00';
        final currentBalance = parseCurrency(balanceStr);
        
        final newBalance = currentBalance + amountToAdd;
        
        transaction.update(walletRef, {
          'balance': _currencyFormat.format(newBalance),
        });
      }

      // Salva o histórico de depósito
      final acquisitionRef = _db.collection('users').doc(user.uid).collection('acquisitions').doc();
      transaction.set(acquisitionRef, {
        'type': 'deposit',
        'title': 'Depósito',
        'amount': _currencyFormat.format(amountToAdd),
        'date': FieldValue.serverTimestamp(),
      });
    });
  }

  // Comprar ou aportar mais numa startup
  Future<void> negotiateAsset(Map<String, dynamic> startup, double amountToBuy) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    final walletRef = _db.collection('users').doc(user.uid).collection('wallet').doc('main');
    final assetsCollection = _db.collection('users').doc(user.uid).collection('assets');
    
    return _db.runTransaction((transaction) async {
      final walletDoc = await transaction.get(walletRef);
      if (!walletDoc.exists) throw Exception("Carteira não encontrada");

      final walletData = walletDoc.data()!;
      final currentBalance = parseCurrency(walletData['balance'] ?? 'R\$ 0,00');
      
      if (currentBalance < amountToBuy) {
        throw Exception("Saldo insuficiente");
      }

      // Deduza o valor
      final newBalance = currentBalance - amountToBuy;
      transaction.update(walletRef, {
        'balance': _currencyFormat.format(newBalance),
      });

      // Checar se o ativo já existe
      final querySnapshot = await assetsCollection.where('name', isEqualTo: startup['name']).get();
      
      if (querySnapshot.docs.isNotEmpty) {
        // Atualiza ativo existente
        final assetDoc = querySnapshot.docs.first;
        final assetRef = assetDoc.reference;
        final assetData = assetDoc.data();
        
        final currentAssetValue = parseCurrency(assetData['value'] ?? 'R\$ 0,00');
        // Quotas é string, ex: "100 AD"
        final quotasStr = assetData['amount']?.toString().split(' ').first ?? '0';
        final currentQuotas = double.tryParse(quotasStr.replaceAll(',', '.')) ?? 0.0;
        
        // Simular preço por quota baseado no valor aportado da startup? 
        // A startup tem um campo `val` (ex: "R$ 12,00").
        final startupPrice = parseCurrency(startup['val'] ?? 'R\$ 1,00');
        final newQuotas = currentQuotas + (amountToBuy / (startupPrice > 0 ? startupPrice : 1));
        
        // Define o prefixo correto da quota
        String prefix = assetData['amount']?.toString().split(' ').length == 2 ? " ${assetData['amount']?.toString().split(' ').last}" : " Cotas";

        transaction.update(assetRef, {
          'value': _currencyFormat.format(currentAssetValue + amountToBuy),
          'amount': "${newQuotas.toStringAsFixed(1)}$prefix",
        });
      } else {
        // Cria novo ativo
        final startupPrice = parseCurrency(startup['val'] ?? 'R\$ 1,00');
        final quotas = amountToBuy / (startupPrice > 0 ? startupPrice : 1);
        String prefix = " ${startup['name'].toString().substring(0, 2).toUpperCase()}";
        
        final docRef = assetsCollection.doc();
        transaction.set(docRef, {
          'name': startup['name'],
          'value': _currencyFormat.format(amountToBuy),
          'amount': "${quotas.toStringAsFixed(1)}$prefix",
        });
      }

      // Calcula as cotas para o histórico
      final startupPrice = parseCurrency(startup['val'] ?? 'R\$ 1,00');
      final boughtQuotas = amountToBuy / (startupPrice > 0 ? startupPrice : 1);
      final quotasPrefix = " ${startup['name'].toString().substring(0, 2).toUpperCase()}";

      // Salva o histórico da compra
      final acquisitionRef = _db.collection('users').doc(user.uid).collection('acquisitions').doc();
      transaction.set(acquisitionRef, {
        'type': 'buy',
        'title': 'Compra: ${startup['name']}',
        'amount': _currencyFormat.format(amountToBuy),
        'quotas': "${boughtQuotas.toStringAsFixed(1)}$quotasPrefix",
        'date': FieldValue.serverTimestamp(),
      });
    });
  }

  // Vender todos os ativos de uma empresa
  Future<void> sellAllAsset(Map<String, dynamic> asset) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    final walletRef = _db.collection('users').doc(user.uid).collection('wallet').doc('main');
    final assetRef = _db.collection('users').doc(user.uid).collection('assets').doc(asset['id']);
    
    return _db.runTransaction((transaction) async {
      final walletDoc = await transaction.get(walletRef);
      final assetDoc = await transaction.get(assetRef);
      
      if (!walletDoc.exists) throw Exception("Carteira não encontrada");
      if (!assetDoc.exists) throw Exception("Ativo não encontrado");

      final walletData = walletDoc.data()!;
      final currentBalance = parseCurrency(walletData['balance'] ?? 'R\$ 0,00');
      
      final assetData = assetDoc.data()!;
      final currentAssetValue = parseCurrency(assetData['value'] ?? 'R\$ 0,00');
      final quotasStr = assetData['amount']?.toString() ?? '0 Cotas';
      
      // Adiciona o valor total do ativo de volta à carteira
      final newBalance = currentBalance + currentAssetValue;
      transaction.update(walletRef, {
        'balance': _currencyFormat.format(newBalance),
      });

      // Remove o ativo
      transaction.delete(assetRef);

      // Salva o histórico
      final acquisitionRef = _db.collection('users').doc(user.uid).collection('acquisitions').doc();
      transaction.set(acquisitionRef, {
        'type': 'sell',
        'title': 'Venda: ${assetData['name']}',
        'amount': _currencyFormat.format(currentAssetValue),
        'quotas': quotasStr,
        'date': FieldValue.serverTimestamp(),
      });
    });
  }
  // --- MÉTODOS P2P ---
  Future<void> createP2POffer(Map<String, dynamic> asset, double price) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    final quotasStr = asset['amount']?.toString().split(' ').first ?? '0';
    final quotas = double.tryParse(quotasStr.replaceAll(',', '.')) ?? 0.0;
    if (quotas <= 0) throw Exception("Cotas insuficientes");

    await _db.collection('p2p_offers').add({
      'sellerId': user.uid,
      'startupName': asset['name'],
      'quotas': quotas,
      'price': price,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getP2POffers() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db.collection('p2p_offers')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            })
            // Opcional: filtrar no cliente se quiser esconder do próprio dono
            .where((offer) => offer['sellerId'] != user.uid)
            .toList()).asBroadcastStream();
  }

  Stream<List<Map<String, dynamic>>> getMyP2POffers() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db.collection('p2p_offers')
        .where('sellerId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList()).asBroadcastStream();
  }

  Future<void> makeCounterOffer(String offerId, double proposedPrice) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    await _db.collection('p2p_offers').doc(offerId).collection('negotiations').doc(user.uid).set({
      'buyerId': user.uid,
      'proposedPrice': proposedPrice,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getOfferNegotiations(String offerId) {
    return _db.collection('p2p_offers').doc(offerId).collection('negotiations')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList()).asBroadcastStream();
  }

  Future<void> acceptP2POffer(String offerId, {double? acceptedPrice, String? buyerIdParam}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("Usuário não logado");

    final offerRef = _db.collection('p2p_offers').doc(offerId);

    return _db.runTransaction((transaction) async {
      final offerDoc = await transaction.get(offerRef);
      if (!offerDoc.exists) throw Exception("Oferta não encontrada");

      final offerData = offerDoc.data()!;
      if (offerData['status'] != 'active') throw Exception("Esta oferta não está mais ativa.");

      final sellerId = offerData['sellerId'];
      final buyerId = buyerIdParam ?? currentUser.uid;

      if (sellerId == buyerId) throw Exception("Você não pode comprar sua própria oferta.");

      final price = acceptedPrice ?? offerData['price'] as double;
      final assetName = offerData['startupName'] as String;
      final quotas = offerData['quotas'] as double;

      final buyerWalletRef = _db.collection('users').doc(buyerId).collection('wallet').doc('main');
      final sellerWalletRef = _db.collection('users').doc(sellerId).collection('wallet').doc('main');
      
      final buyerWalletDoc = await transaction.get(buyerWalletRef);
      final sellerWalletDoc = await transaction.get(sellerWalletRef);

      if (!buyerWalletDoc.exists) throw Exception("Carteira do comprador não encontrada");
      if (!sellerWalletDoc.exists) throw Exception("Carteira do vendedor não encontrada");

      final buyerBalance = parseCurrency(buyerWalletDoc.data()!['balance'] ?? 'R\$ 0,00');
      final sellerBalance = parseCurrency(sellerWalletDoc.data()!['balance'] ?? 'R\$ 0,00');

      if (buyerBalance < price) throw Exception("Saldo insuficiente do comprador");

      // Transferência de dinheiro
      transaction.update(buyerWalletRef, {'balance': _currencyFormat.format(buyerBalance - price)});
      transaction.update(sellerWalletRef, {'balance': _currencyFormat.format(sellerBalance + price)});

      // Remover o ativo do vendedor
      final sellerAssetsCollection = _db.collection('users').doc(sellerId).collection('assets');
      final sellerAssetsQuery = await sellerAssetsCollection.where('name', isEqualTo: assetName).get();
      if (sellerAssetsQuery.docs.isNotEmpty) {
        // Assume selling all quotas for simplicity or update if partially selling 
        // Our simplified model assumes the offer was for the whole asset or specific quotas
        final sDoc = sellerAssetsQuery.docs.first;
        final sData = sDoc.data();
        final sQuotasStr = sData['amount']?.toString().split(' ').first ?? '0';
        final sQuotas = double.tryParse(sQuotasStr.replaceAll(',', '.')) ?? 0.0;
        
        if (sQuotas <= quotas) { // Se vendeu tudo ou de alguma forma passou do total
          transaction.delete(sDoc.reference);
        } else {
          // Atualiza descontando as cotas. Prefix seria " AD" etc.
          String prefix = sData['amount']?.toString().split(' ').length == 2 ? " ${sData['amount']?.toString().split(' ').last}" : " Cotas";
          // We need an approximate value deduction proportional to quotas
          final sValStr = sData['value']?.toString() ?? 'R\$ 0,00';
          final sVal = parseCurrency(sValStr);
          final newVal = sVal - (sVal * (quotas/sQuotas));
          transaction.update(sDoc.reference, {
            'amount': "${(sQuotas - quotas).toStringAsFixed(1)}$prefix",
            'value': _currencyFormat.format(newVal > 0 ? newVal : 0),
          });
        }
      }

      // Adicionar o ativo ao comprador
      final buyerAssetsCollection = _db.collection('users').doc(buyerId).collection('assets');
      final buyerAssetsQuery = await buyerAssetsCollection.where('name', isEqualTo: assetName).get();
      if (buyerAssetsQuery.docs.isNotEmpty) {
        final bDoc = buyerAssetsQuery.docs.first;
        final bData = bDoc.data();
        final bQuotasStr = bData['amount']?.toString().split(' ').first ?? '0';
        final bQuotas = double.tryParse(bQuotasStr.replaceAll(',', '.')) ?? 0.0;
        String prefix = bData['amount']?.toString().split(' ').length == 2 ? " ${bData['amount']?.toString().split(' ').last}" : " Cotas";
        final bValStr = bData['value']?.toString() ?? 'R\$ 0,00';
        final bVal = parseCurrency(bValStr);

        transaction.update(bDoc.reference, {
          'amount': "${(bQuotas + quotas).toStringAsFixed(1)}$prefix",
          'value': _currencyFormat.format(bVal + price),
        });
      } else {
         String prefix = " ${assetName.substring(0, 2).toUpperCase()}";
         final newAssetRef = buyerAssetsCollection.doc();
         transaction.set(newAssetRef, {
           'name': assetName,
           'value': _currencyFormat.format(price),
           'amount': "${quotas.toStringAsFixed(1)}$prefix",
         });
      }

      // Marcar oferta como concluída
      transaction.update(offerRef, {'status': 'completed'});
    });
  }

  Future<void> acceptCounterOffer(String offerId, String negotiationId, double agreedPrice) async {
    // negotiationId é na verdade o buyerId pois usamos doc(user.uid)
    await acceptP2POffer(offerId, acceptedPrice: agreedPrice, buyerIdParam: negotiationId);
    
    // Marcar negociação como aceita
    await _db.collection('p2p_offers').doc(offerId).collection('negotiations').doc(negotiationId).update({
      'status': 'accepted',
    });
  }

  // --- MÉTODOS DE SEED ---
  // Cria dados iniciais para testar o App conectando-se no BancoPI3
  Future<void> seedInitialData() async {
    // Populando as startups
    final startupsCollection = _db.collection('startups');
    final query = await startupsCollection.limit(1).get();
    
    if (query.docs.isEmpty) {
      final List<Map<String, dynamic>> initialStartups = [
        {
          "name": "EcoToken",
          "stage": "Em operação",
          "val": "R\$ 12,00",
          "description": "Plataforma de créditos de carbono tokenizados que conecta empresas a projetos ambientais verificados.",
          "sector": "Sustentabilidade",
          "socios": ["Ana Lima", "Carlos Matos"],
          "tokens": 500000,
          "capital": 6000000.0,
          "sumarioExecutivo": "EcoToken democratiza o mercado de carbono ao tokenizar créditos verificados, permitindo que pequenas empresas compensem emissões de forma acessível e transparente.",
          "perguntasRespostas": [
            {"pergunta": "Como os créditos são verificados?", "resposta": "Utilizamos auditores certificados pela Verra e pelo Gold Standard para cada projeto parceiro."},
            {"pergunta": "Qual o retorno esperado?", "resposta": "Projeção de valorização de 15% ao ano com base na demanda crescente por offsets de carbono."},
          ],
          "videoDemo": "https://www.youtube.com/watch?v=ecotoken_demo",
        },
        {
          "name": "HealthTech",
          "stage": "Em expansão",
          "val": "R\$ 45,50",
          "description": "SaaS de gestão clínica com IA para diagnóstico preditivo, voltado para clínicas e hospitais de médio porte.",
          "sector": "Saúde",
          "socios": ["Dr. Felipe Souza", "Mariana Costa", "Rafael Nunes"],
          "tokens": 1200000,
          "capital": 54600000.0,
          "sumarioExecutivo": "HealthTech reduz erros diagnósticos em até 30% ao integrar prontuário eletrônico com modelos de IA treinados em dados anonimizados do SUS e de clínicas privadas.",
          "perguntasRespostas": [
            {"pergunta": "A solução é compatível com LGPD?", "resposta": "Sim, todos os dados são anonimizados antes do treinamento dos modelos e armazenados em servidores nacionais."},
            {"pergunta": "Quantas clínicas já utilizam?", "resposta": "Temos 87 clínicas ativas e pipeline de 200+ para o próximo trimestre."},
          ],
          "videoDemo": "https://www.youtube.com/watch?v=healthtech_demo",
        },
        {
          "name": "AgroData",
          "stage": "Nova",
          "val": "R\$ 5,00",
          "description": "Plataforma de análise de dados agrícolas via satélite e IoT para otimização de produtividade no campo.",
          "sector": "Agronegócio",
          "socios": ["João Ferreira", "Lucia Alves"],
          "tokens": 2000000,
          "capital": 10000000.0,
          "sumarioExecutivo": "AgroData combina imagens de satélite, sensores IoT e machine learning para entregar aos produtores rurais recomendações de plantio e irrigação com precisão de 92%.",
          "perguntasRespostas": [
            {"pergunta": "Quais culturas são suportadas?", "resposta": "Atualmente soja, milho e cana-de-açúcar. Algodão e café entram no roadmap de Q3."},
            {"pergunta": "Qual o custo por hectare?", "resposta": "R\$ 12 por hectare/ano, com ROI médio de 4x comprovado em pilotos."},
          ],
          "videoDemo": "https://www.youtube.com/watch?v=agrodata_demo",
        },
        {
          "name": "FinSol",
          "stage": "Em operação",
          "val": "R\$ 28,75",
          "description": "Fintech de crédito com scoring alternativo para MEIs e autônomos não atendidos pelos grandes bancos.",
          "sector": "Finanças",
          "socios": ["Beatriz Rocha", "Thiago Mendes"],
          "tokens": 800000,
          "capital": 23000000.0,
          "sumarioExecutivo": "FinSol usa dados alternativos (fluxo de caixa, reputação digital, histórico de pagamentos de utilities) para oferecer crédito justo a 40 milhões de brasileiros desbancarizados.",
          "perguntasRespostas": [
            {"pergunta": "Qual a taxa de inadimplência?", "resposta": "3,2%, abaixo da média do setor que é 5,8% para o mesmo perfil de cliente."},
            {"pergunta": "A empresa é regulada pelo Banco Central?", "resposta": "Sim, operamos como SEP (Sociedade de Empréstimo entre Pessoas) autorizada pelo BACEN."},
          ],
          "videoDemo": "https://www.youtube.com/watch?v=finsol_demo",
        },
        {
          "name": "Educa+",
          "stage": "Nova",
          "val": "R\$ 7,50",
          "description": "Plataforma de microlearning gamificado para requalificação profissional de trabalhadores da indústria 4.0.",
          "sector": "Educação",
          "socios": ["Priscila Gomes", "Eduardo Teixeira"],
          "tokens": 1500000,
          "capital": 11250000.0,
          "sumarioExecutivo": "Educa+ usa trilhas de aprendizado adaptativas e mecânicas de game para requalificar trabalhadores em até 90 dias, com taxa de conclusão 3x maior que e-learning tradicional.",
          "perguntasRespostas": [
            {"pergunta": "Quais cursos estão disponíveis?", "resposta": "Mais de 200 trilhas nas áreas de automação, programação, análise de dados e soft skills."},
            {"pergunta": "Como é feita a parceria com empresas?", "resposta": "Modelo B2B2C com licenças corporativas e relatórios de progresso em tempo real para o RH."},
          ],
          "videoDemo": "https://www.youtube.com/watch?v=educamais_demo",
        },
        {
          "name": "Mobility Z",
          "stage": "Em expansão",
          "val": "R\$ 98,00",
          "description": "Rede de compartilhamento de veículos elétricos leves (patinetes e bikes) com carregamento solar nos pontos.",
          "sector": "Mobilidade Urbana",
          "socios": ["Diego Carvalho", "Fernanda Lins", "Samuel Park"],
          "tokens": 600000,
          "capital": 58800000.0,
          "sumarioExecutivo": "Mobility Z opera 12.000 veículos em 8 cidades, com infraestrutura de carregamento 100% solar e integração com apps de transporte público para a última milha.",
          "perguntasRespostas": [
            {"pergunta": "Em quantas cidades operam?", "resposta": "8 cidades atualmente: São Paulo, Rio, Curitiba, BH, Fortaleza, Recife, Goiânia e Campinas."},
            {"pergunta": "Qual o plano de expansão?", "resposta": "Meta de 25 cidades e 50.000 veículos até o final de 2026 com os recursos desta rodada."},
          ],
          "videoDemo": "https://www.youtube.com/watch?v=mobilityz_demo",
        },
        {
          "name": "Aura IA",
          "stage": "Nova",
          "val": "R\$ 21,30",
          "description": "Assistente de IA para saúde mental com escuta ativa, triagem e encaminhamento para profissionais certificados.",
          "sector": "Saúde Mental",
          "socios": ["Camila Rezende", "André Vasconcelos"],
          "tokens": 1000000,
          "capital": 21300000.0,
          "sumarioExecutivo": "Aura IA oferece suporte emocional 24/7 via conversação empática, identifica sinais de crise e conecta o usuário a psicólogos parceiros em menos de 2 horas.",
          "perguntasRespostas": [
            {"pergunta": "A IA substitui o psicólogo?", "resposta": "Não. Aura complementa o cuidado humano fazendo triagem e acolhimento inicial; casos críticos são sempre encaminhados a profissionais."},
            {"pergunta": "Os dados dos usuários são seguros?", "resposta": "Sim, seguimos rigorosamente a LGPD com criptografia ponta-a-ponta e opção de exclusão total de dados."},
          ],
          "videoDemo": "https://www.youtube.com/watch?v=aura_ia_demo",
        },
        {
          "name": "CleanEnergy",
          "stage": "Semente",
          "val": "R\$ 2,50",
          "description": "Startup de energia limpa desenvolvendo células de hidrogênio verde de baixo custo para uso industrial.",
          "sector": "Energia",
          "socios": ["Gustavo Pinheiro"],
          "tokens": 4000000,
          "capital": 10000000.0,
          "sumarioExecutivo": "CleanEnergy pesquisa e desenvolve eletrolisadores de próxima geração que reduzem o custo do hidrogênio verde em 40%, viabilizando sua adoção em larga escala pela indústria pesada.",
          "perguntasRespostas": [
            {"pergunta": "Em que estágio está a tecnologia?", "resposta": "TRL 5 (validação em ambiente relevante). Prevemos protótipo industrial até Q4 2026."},
            {"pergunta": "Há patentes registradas?", "resposta": "Sim, 3 patentes pendentes no INPI e 1 internacional via PCT."},
          ],
          "videoDemo": "https://www.youtube.com/watch?v=cleanenergy_demo",
        },
        {
          "name": "SpaceT",
          "stage": "Em operação",
          "val": "R\$ 150,00",
          "description": "Empresa de nanosatélites para monitoramento de ativos de infraestrutura (oleodutos, linhas de transmissão e hidrelétricas).",
          "sector": "Tecnologia Espacial",
          "socios": ["Renata Meireles", "Paulo Astronomo", "Ines Vidal"],
          "tokens": 300000,
          "capital": 45000000.0,
          "sumarioExecutivo": "SpaceT já tem 4 satélites em órbita e contratos com 3 concessionárias de energia e 2 empresas de óleo & gás, monitorando mais de 8.000 km de infraestrutura crítica.",
          "perguntasRespostas": [
            {"pergunta": "Qual a resolução das imagens?", "resposta": "50 cm por pixel com revisita de 12 horas, suficiente para detecção de anomalias estruturais."},
            {"pergunta": "Quem são os clientes atuais?", "resposta": "Temos contratos com Petrobras, Eletrobras e CTEEP sob NDA, representando R\$ 18M em ARR."},
          ],
          "videoDemo": "https://www.youtube.com/watch?v=spacet_demo",
        },
        {
          "name": "BioGenesis",
          "stage": "Em expansão",
          "val": "R\$ 55,20",
          "description": "Biotecnologia de edição genética aplicada ao desenvolvimento de biofármacos para doenças raras tropicais.",
          "sector": "Biotecnologia",
          "socios": ["Dra. Lara Brandão", "Prof. Marco Augusto"],
          "tokens": 900000,
          "capital": 49680000.0,
          "sumarioExecutivo": "BioGenesis usa CRISPR-Cas9 para desenvolver terapias para leishmaniose e doença de Chagas, doenças negligenciadas que afetam 20 milhões de brasileiros, com pipeline de 3 candidatos clínicos.",
          "perguntasRespostas": [
            {"pergunta": "Há aprovação regulatória em andamento?", "resposta": "Sim, temos IND aprovado pela ANVISA para o candidato BGX-01, com fase I iniciando em Q2 2026."},
            {"pergunta": "Há parceria com universidades?", "resposta": "Colaboramos com USP, FIOCRUZ e o Instituto Butantan para desenvolvimento pré-clínico."},
          ],
          "videoDemo": "https://www.youtube.com/watch?v=biogenesis_demo",
        },
      ];
      
      for (var startup in initialStartups) {
        await startupsCollection.add(startup);
      }
      debugPrint("Startups semeadas com sucesso!");
    }

    // Populando carteira do usuário atual (se logado)
    final user = _auth.currentUser;
    if (user != null) {
      final walletRef = _db.collection('users').doc(user.uid).collection('wallet').doc('main');
      final walletDoc = await walletRef.get();
      
      if (!walletDoc.exists) {
        await walletRef.set({
          "balance": "R\$ 15.250,00",
          "appreciation": "+ 0,0%"
        });
        print("Carteira do \$user.email criada com sucesso!");
      }
    }
  }

  // --- MÉTODOS DE LIMPEZA ---
  Future<void> removePlaceholderAssets() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final assetsCollection = _db.collection('users').doc(user.uid).collection('assets');
    final acquisitionsCollection = _db.collection('users').doc(user.uid).collection('acquisitions');

    // Identifica quais empresas o usuário de fato comprou (que têm histórico gerado)
    final acquisitionsQuery = await acquisitionsCollection.where('type', isEqualTo: 'buy').get();
    final realPurchasedStartupNames = acquisitionsQuery.docs
        .map((doc) => doc.data()['title']?.toString().replaceAll('Compra: ', '') ?? '')
        .toSet();

    final assetsQuery = await assetsCollection.get();
    for (var doc in assetsQuery.docs) {
      final assetName = doc.data()['name'] ?? '';
      // Se não houver histórico de compra dessa empresa, foi inject de placeholder
      if (!realPurchasedStartupNames.contains(assetName)) {
        await doc.reference.delete();
      }
    }
  }
}
