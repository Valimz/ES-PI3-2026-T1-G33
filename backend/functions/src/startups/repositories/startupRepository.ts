import {FieldValue} from "firebase-admin/firestore";
import {
 StartupDocument,
 StartupListItem,
 StartupQuestionDocument,
} from "../types";
import {db} from "../shared/firebase";

const startupsCollection = db.collection("startups");

const demoStartups: Array<Record<string, any> & {id: string}> = [
 {
 id: "ecotech",
 name: "EcoTech",
 stage: "Em operação",
 val: "R$ 3,00",
 description: "Plataforma de monitoramento ambiental para empresas.",
 shortDescription: "Plataforma de monitoramento ambiental para empresas.",
 sector: "Cleantech",
 capitalAportado: 300000,
 capitalRaisedCents: 30000000,
 tokensEmitidos: 100000,
 totalTokensIssued: 100000,
 socios: [
 {nome: "Ana Souza", percentual: 60},
 {nome: "Carlos Lima", percentual: 40},
 ],
 founders: [
 {name: "Ana Souza", role: "Sócia", equityPercent: 60},
 {name: "Carlos Lima", role: "Sócio", equityPercent: 40},
 ],
 mentoresConselho: ["Mariana Prado"],
 externalMembers: [
 {name: "Mariana Prado", role: "Mentora", organization: "Mescla"},
 ],
 videoUrl: "https://exemplo.com/demo1",
 demoVideos: ["https://exemplo.com/demo1"],
 status: "ativa",
 faq: [
 {
 id: "default-ecotech-1",
 pergunta: "Como a EcoTech gera receita?",
 resposta: "Por meio de assinaturas mensais das empresas que utilizam a plataforma de monitoramento ambiental.",
 publico: true,
 },
 {
 id: "default-ecotech-2",
 pergunta: "Qual é o principal diferencial da startup?",
 resposta: "Sensores próprios integrados a um painel de analytics em tempo real para conformidade ambiental.",
 publico: true,
 },
 ],
 },
 {
 id: "finflow",
 name: "FinFlow",
 stage: "Em expansão",
 val: "R$ 2,00",
 description: "Gestão de fluxo de caixa para MEIs.",
 shortDescription: "Gestão de fluxo de caixa para MEIs.",
 sector: "Fintech",
 capitalAportado: 500000,
 capitalRaisedCents: 50000000,
 tokensEmitidos: 250000,
 totalTokensIssued: 250000,
 socios: [
 {nome: "Roberto Dias", percentual: 50},
 {nome: "Julia Mota", percentual: 50},
 ],
 founders: [
 {name: "Roberto Dias", role: "Sócio", equityPercent: 50},
 {name: "Julia Mota", role: "Sócia", equityPercent: 50},
 ],
 mentoresConselho: ["Ricardo Santos"],
 externalMembers: [
 {name: "Ricardo Santos", role: "Mentor", organization: "Mescla"},
 ],
 videoUrl: "https://exemplo.com/demo2",
 demoVideos: ["https://exemplo.com/demo2"],
 status: "ativa",
 faq: [
 {
 id: "default-finflow-1",
 pergunta: "Para quem é o produto da FinFlow?",
 resposta: "Para MEIs e pequenos negócios que precisam de gestão simples e automatizada de fluxo de caixa.",
 publico: true,
 },
 {
 id: "default-finflow-2",
 pergunta: "Como é feita a cobrança aos clientes?",
 resposta: "Plano mensal por assinatura, com diferentes faixas conforme o volume de transações.",
 publico: true,
 },
 ],
 },
 {
 id: "agrosmart",
 name: "AgroSmart",
 stage: "Nova",
 val: "R$ 2,00",
 description: "IoT para otimização de irrigação.",
 shortDescription: "IoT para otimização de irrigação.",
 sector: "Agtech",
 capitalAportado: 150000,
 capitalRaisedCents: 15000000,
 tokensEmitidos: 75000,
 totalTokensIssued: 75000,
 socios: [
 {nome: "Marcos Vinicius", percentual: 100},
 ],
 founders: [
 {name: "Marcos Vinicius", role: "Sócio", equityPercent: 100},
 ],
 mentoresConselho: ["Arnaldo Souza"],
 externalMembers: [
 {name: "Arnaldo Souza", role: "Mentor", organization: "Mescla"},
 ],
 videoUrl: "https://exemplo.com/demo3",
 demoVideos: ["https://exemplo.com/demo3"],
 status: "ativa",
 faq: [
 {
 id: "default-agrosmart-1",
 pergunta: "O que a solução da AgroSmart resolve?",
 resposta: "Otimiza a irrigação no campo usando sensores IoT, reduzindo o desperdício de água e custos.",
 publico: true,
 },
 {
 id: "default-agrosmart-2",
 pergunta: "Em que estágio a startup está?",
 resposta: "Em fase inicial (Nova), validando a tecnologia com produtores parceiros.",
 publico: true,
 },
 ],
 },
 {
 id: "healthvibe",
 name: "HealthVibe",
 stage: "Em operação",
 val: "R$ 2,00",
 description: "Telemedicina com IA para triagem.",
 shortDescription: "Telemedicina com IA para triagem.",
 sector: "Healthtech",
 capitalAportado: 800000,
 capitalRaisedCents: 80000000,
 tokensEmitidos: 400000,
 totalTokensIssued: 400000,
 socios: [
 {nome: "Beatriz Luz", percentual: 70},
 {nome: "Hugo Vaz", percentual: 30},
 ],
 founders: [
 {name: "Beatriz Luz", role: "Sócia", equityPercent: 70},
 {name: "Hugo Vaz", role: "Sócio", equityPercent: 30},
 ],
 mentoresConselho: ["Sandra Meireles"],
 externalMembers: [
 {name: "Sandra Meireles", role: "Mentora", organization: "Mescla"},
 ],
 videoUrl: "https://exemplo.com/demo4",
 demoVideos: ["https://exemplo.com/demo4"],
 status: "ativa",
 faq: [
 {
 id: "default-healthvibe-1",
 pergunta: "Como a IA é utilizada na HealthVibe?",
 resposta: "Para triagem inicial dos pacientes em atendimentos de telemedicina, agilizando o encaminhamento.",
 publico: true,
 },
 {
 id: "default-healthvibe-2",
 pergunta: "A plataforma substitui o médico?",
 resposta: "Não. A IA apoia a triagem, mas o atendimento e o diagnóstico são sempre realizados por profissionais.",
 publico: true,
 },
 ],
 },
 {
 id: "edunext",
 name: "EduNext",
 stage: "Em expansão",
 val: "R$ 2,25",
 description: "Plataforma de cursos gamificados.",
 shortDescription: "Plataforma de cursos gamificados.",
 sector: "Edutech",
 capitalAportado: 450000,
 capitalRaisedCents: 45000000,
 tokensEmitidos: 200000,
 totalTokensIssued: 200000,
 socios: [
 {nome: "Tiago André", percentual: 100},
 ],
 founders: [
 {name: "Tiago André", role: "Sócio", equityPercent: 100},
 ],
 mentoresConselho: ["Fernando Silva"],
 externalMembers: [
 {name: "Fernando Silva", role: "Mentor", organization: "Mescla"},
 ],
 videoUrl: "https://exemplo.com/demo5",
 demoVideos: ["https://exemplo.com/demo5"],
 status: "ativa",
 faq: [
 {
 id: "default-edunext-1",
 pergunta: "O que torna os cursos da EduNext diferentes?",
 resposta: "A gamificação do aprendizado, com trilhas, recompensas e acompanhamento de progresso.",
 publico: true,
 },
 {
 id: "default-edunext-2",
 pergunta: "Qual é o modelo de negócio?",
 resposta: "Assinaturas de acesso às trilhas de cursos, com planos para alunos e para empresas.",
 publico: true,
 },
 ],
 },
 ];

function toListItem(id: string, startup: Record<string, any>): StartupListItem {
 const capitalRaisedCents = typeof startup.capitalRaisedCents === "number"
 ? startup.capitalRaisedCents
 : typeof startup.capitalAportado === "number"
 ? startup.capitalAportado * 100
 : 0;

 const totalTokensIssued = typeof startup.totalTokensIssued === "number"
 ? startup.totalTokensIssued
 : typeof startup.tokensEmitidos === "number"
 ? startup.tokensEmitidos
 : 0;

 const currentTokenPriceCents = typeof startup.currentTokenPriceCents === "number"
 ? startup.currentTokenPriceCents
 : (() => {
 const raw = String(startup.val ?? "0").replace(/[^0-9,.-]/g, "").replace(",", ".");
 const parsed = Number.parseFloat(raw);
 return Number.isNaN(parsed) ? 0 : Math.round(parsed * 100);
 })();

 return {
 id,
 name: startup.name,
 stage: startup.stage,
 shortDescription: startup.shortDescription ?? startup.description ?? "",
 capitalRaisedCents,
 totalTokensIssued,
 currentTokenPriceCents,
 coverImageUrl: startup.coverImageUrl,
 tags: startup.tags ?? [],
 };
}

export async function listStartupItems(): Promise<StartupListItem[]> {
 const snapshot = await startupsCollection.limit(100).get();

 return snapshot.docs.map((doc) =>
 toListItem(doc.id, doc.data() as Record<string, any>)
 );
}

export async function getStartupById(
 startupId: string
): Promise<StartupDocument | undefined> {
 const startupSnapshot = await startupsCollection.doc(startupId).get();

 if (!startupSnapshot.exists) {
 return undefined;
 }

 return startupSnapshot.data() as StartupDocument;
}

export async function userIsInvestor(
 startupId: string,
 uid: string
): Promise<boolean> {
 const investorSnapshot = await startupsCollection
 .doc(startupId)
 .collection("investors")
 .doc(uid)
 .get();

 return investorSnapshot.exists;
}

export async function listPublicQuestions(startupId: string) {
 const questionsSnapshot = await startupsCollection
 .doc(startupId)
 .collection("questions")
 .where("visibility", "==", "publica")
 .limit(50)
 .get();

 return questionsSnapshot.docs
 .map((doc) => ({
 id: doc.id,
 text: doc.get("text"),
 answer: doc.get("answer") ?? null,
 answeredAt: doc.get("answeredAt")?.toDate?.()?.toISOString?.() ?? null,
 createdAt: doc.get("createdAt")?.toDate?.()?.toISOString?.() ?? null,
 }))
 .sort((left, right) => String(right.createdAt ?? "")
 .localeCompare(String(left.createdAt ?? "")));
}

export async function createQuestion(
 startupId: string,
 question: StartupQuestionDocument
): Promise<string> {
 const questionRef = await startupsCollection
 .doc(startupId)
 .collection("questions")
 .add(question);

 return questionRef.id;
}

export async function seedDemoStartups(): Promise<string[]> {
 const batch = db.batch();

 for (const startup of demoStartups) {
 const {id, ...data} = startup;
 const startupRef = startupsCollection.doc(id);

 batch.set(startupRef, {
 ...data,
 createdAt: FieldValue.serverTimestamp(),
 updatedAt: FieldValue.serverTimestamp(),
 }, {merge: true});
 }

 await batch.commit();

 return demoStartups.map((startup) => startup.id);
}
