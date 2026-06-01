import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Acesso de LEITURA ao Firestore e dados de FAQ.
///
/// Regras de negócio financeiras (compra, venda, saque, P2P, valorização)
/// vivem exclusivamente nas Cloud Functions e são acessadas via
/// [BackendService]/[FunctionsService]. Este serviço expõe apenas leituras
/// (streams) e o conteúdo de perguntas/respostas das startups.
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

  // Stream para obter os dados cadastrais do usuário logado (users/{uid}).
  Stream<Map<String, dynamic>?> getUserProfile() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db.collection('users').doc(user.uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    }).asBroadcastStream();
  }

  // Atualiza o telefone do usuário.
  Future<void> updateUserPhone(String telefone) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db
        .collection('users')
        .doc(user.uid)
        .set({'telefone': telefone}, SetOptions(merge: true));
  }

  // Ativa ou desativa o MFA no cadastro do usuário.
  Future<void> setMfaEnabled(bool enabled) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db
        .collection('users')
        .doc(user.uid)
        .set({'mfaEnabled': enabled}, SetOptions(merge: true));
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
  /// [limit] restringe a quantidade de documentos retornados (melhora performance).
  Stream<List<Map<String, dynamic>>> getUserAcquisitions({int? limit}) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    Query<Map<String, dynamic>> query = _db
        .collection('users')
        .doc(user.uid)
        .collection('acquisitions')
        .orderBy('date', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList()).asBroadcastStream();
  }

  // Utilitário para desformatar moeda (BRL) — usado em telas de leitura.
  double parseCurrency(String currencyStr) {
    try {
      String cleanString = currencyStr.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.');
      return double.tryParse(cleanString) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // --- MÉTODOS DE PERGUNTAS PRIVADAS (FAQ) ---
  Future<void> addPrivateQuestion(String startupId, String pergunta) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não logado");
    if (pergunta.trim().isEmpty) throw Exception("A pergunta não pode ser vazia");

    final startupRef = _db.collection('startups').doc(startupId);
    final newId = DateTime.now().microsecondsSinceEpoch.toString();
    await startupRef.update({
      'faq': FieldValue.arrayUnion([
        {
          'id': newId,
          'pergunta': pergunta.trim(),
          'resposta': '',
          'publico': false,
          'askerId': user.uid,
          'createdAt': DateTime.now().toIso8601String(),
        }
      ]),
    });
  }

  Stream<List<Map<String, dynamic>>> getMyPrivateQuestions(String startupId) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('startups')
        .doc(startupId)
        .snapshots()
        .map((snap) {
      final data = snap.data();
      if (data == null) return <Map<String, dynamic>>[];
      final faq = data['faq'];
      if (faq is! List) return <Map<String, dynamic>>[];
      return faq
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .where((q) => q['askerId'] == user.uid)
          .toList();
    }).asBroadcastStream();
  }

  Future<void> editPrivateQuestion(
      String startupId, Map<String, dynamic> original, String novaPergunta) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não logado");
    final novaTrim = novaPergunta.trim();
    if (novaTrim.isEmpty) throw Exception("A pergunta não pode ser vazia");
    if (original['askerId'] != user.uid) {
      throw Exception("Você só pode editar suas próprias perguntas");
    }

    final startupRef = _db.collection('startups').doc(startupId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(startupRef);
      if (!snap.exists) throw Exception("Startup não encontrada");

      final data = snap.data()!;
      final rawFaq = data['faq'];
      final List<dynamic> faq =
          rawFaq is List ? List<dynamic>.from(rawFaq) : <dynamic>[];

      bool encontrou = false;
      final List<Map<String, dynamic>> novoFaq = faq
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .map((q) {
        if (!encontrou && _matchesQuestion(q, original)) {
          encontrou = true;
          if (q['publico'] == true) {
            throw Exception(
                "Pergunta já publicada não pode ser editada");
          }
          return {
            ...q,
            'pergunta': novaTrim,
            'editedAt': DateTime.now().toIso8601String(),
          };
        }
        return q;
      }).toList();

      if (!encontrou) throw Exception("Pergunta não encontrada");

      transaction.update(startupRef, {'faq': novoFaq});
    });
  }

  Future<void> deletePrivateQuestion(
      String startupId, Map<String, dynamic> original) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não logado");
    if (original['askerId'] != user.uid) {
      throw Exception("Você só pode excluir suas próprias perguntas");
    }

    final startupRef = _db.collection('startups').doc(startupId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(startupRef);
      if (!snap.exists) throw Exception("Startup não encontrada");

      final data = snap.data()!;
      final rawFaq = data['faq'];
      final List<dynamic> faq =
          rawFaq is List ? List<dynamic>.from(rawFaq) : <dynamic>[];

      bool removeu = false;
      final List<Map<String, dynamic>> novoFaq = [];
      for (final item in faq) {
        if (item is! Map) continue;
        final q = Map<String, dynamic>.from(item);
        if (!removeu && _matchesQuestion(q, original)) {
          if (q['publico'] == true) {
            throw Exception(
                "Pergunta já publicada não pode ser excluída");
          }
          removeu = true;
          continue;
        }
        novoFaq.add(q);
      }

      if (!removeu) throw Exception("Pergunta não encontrada");

      transaction.update(startupRef, {'faq': novoFaq});
    });
  }

  bool _matchesQuestion(Map<String, dynamic> q, Map<String, dynamic> original) {
    final origId = original['id'];
    if (origId != null && q['id'] != null) {
      return q['id'] == origId;
    }
    return q['askerId'] == original['askerId'] &&
        q['pergunta'] == original['pergunta'] &&
        q['createdAt'] == original['createdAt'];
  }

  Future<void> addPublicQuestion(String startupId, String pergunta) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não logado");
    if (pergunta.trim().isEmpty) throw Exception("A pergunta não pode ser vazia");

    final startupRef = _db.collection('startups').doc(startupId);
    final newId = DateTime.now().microsecondsSinceEpoch.toString();
    await startupRef.update({
      'faq': FieldValue.arrayUnion([
        {
          'id': newId,
          'pergunta': pergunta.trim(),
          'resposta': '',
          'publico': true,
          'askerId': user.uid,
          'createdAt': DateTime.now().toIso8601String(),
        }
      ]),
    });
  }

  Future<void> ensureDefaultPublicQuestions(
      String startupId, String startupName) async {
    if (startupId.isEmpty) return;
    final defaults = _defaultPublicFaqByName[startupName];
    if (defaults == null || defaults.isEmpty) return;

    final ref = _db.collection('startups').doc(startupId);
    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data() ?? <String, dynamic>{};
    final rawFaq = data['faq'];
    final existing = rawFaq is List
        ? rawFaq
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList()
        : <Map<String, dynamic>>[];
    final existingIds = existing.map((q) => q['id']).toSet();
    final missing =
        defaults.where((q) => !existingIds.contains(q['id'])).toList();
    if (missing.isEmpty) return;

    await ref.update({'faq': FieldValue.arrayUnion(missing)});
  }

  Stream<List<Map<String, dynamic>>> getPublicQuestions(String startupId) {
    return _db.collection('startups').doc(startupId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return <Map<String, dynamic>>[];
      final faq = data['faq'];
      if (faq is! List) return <Map<String, dynamic>>[];
      final publicas = faq
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .where((q) => q['publico'] == true)
          .toList();
      publicas.sort((a, b) {
        final aOficial = a['askerId'] == null;
        final bOficial = b['askerId'] == null;
        if (aOficial != bOficial) return aOficial ? -1 : 1;
        return (a['createdAt']?.toString() ?? '')
            .compareTo(b['createdAt']?.toString() ?? '');
      });
      return publicas;
    }).asBroadcastStream();
  }

  // --- LEITURA P2P (escrita é feita via Cloud Functions) ---
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

  // Perguntas públicas predefinidas exibidas no FAQ de cada startup.
  static const Map<String, List<Map<String, dynamic>>> _defaultPublicFaqByName = {
    "EcoTech": [
      {
        "id": "default-ecotech-1",
        "pergunta": "Como a EcoTech gera receita?",
        "resposta":
            "Por meio de assinaturas mensais das empresas que utilizam a plataforma de monitoramento ambiental.",
        "publico": true,
      },
      {
        "id": "default-ecotech-2",
        "pergunta": "Qual é o principal diferencial da startup?",
        "resposta":
            "Sensores próprios integrados a um painel de analytics em tempo real para conformidade ambiental.",
        "publico": true,
      },
    ],
    "FinFlow": [
      {
        "id": "default-finflow-1",
        "pergunta": "Para quem é o produto da FinFlow?",
        "resposta":
            "Para MEIs e pequenos negócios que precisam de gestão simples e automatizada de fluxo de caixa.",
        "publico": true,
      },
      {
        "id": "default-finflow-2",
        "pergunta": "Como é feita a cobrança aos clientes?",
        "resposta":
            "Plano mensal por assinatura, com diferentes faixas conforme o volume de transações.",
        "publico": true,
      },
    ],
    "AgroSmart": [
      {
        "id": "default-agrosmart-1",
        "pergunta": "O que a solução da AgroSmart resolve?",
        "resposta":
            "Otimiza a irrigação no campo usando sensores IoT, reduzindo o desperdício de água e custos.",
        "publico": true,
      },
      {
        "id": "default-agrosmart-2",
        "pergunta": "Em que estágio a startup está?",
        "resposta":
            "Em fase inicial (Nova), validando a tecnologia com produtores parceiros.",
        "publico": true,
      },
    ],
    "HealthVibe": [
      {
        "id": "default-healthvibe-1",
        "pergunta": "Como a IA é utilizada na HealthVibe?",
        "resposta":
            "Para triagem inicial dos pacientes em atendimentos de telemedicina, agilizando o encaminhamento.",
        "publico": true,
      },
      {
        "id": "default-healthvibe-2",
        "pergunta": "A plataforma substitui o médico?",
        "resposta":
            "Não. A IA apoia a triagem, mas o atendimento e o diagnóstico são sempre realizados por profissionais.",
        "publico": true,
      },
    ],
    "EduNext": [
      {
        "id": "default-edunext-1",
        "pergunta": "O que torna os cursos da EduNext diferentes?",
        "resposta":
            "A gamificação do aprendizado, com trilhas, recompensas e acompanhamento de progresso.",
        "publico": true,
      },
      {
        "id": "default-edunext-2",
        "pergunta": "Qual é o modelo de negócio?",
        "resposta":
            "Assinaturas de acesso às trilhas de cursos, com planos para alunos e para empresas.",
        "publico": true,
      },
    ],
  };

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
