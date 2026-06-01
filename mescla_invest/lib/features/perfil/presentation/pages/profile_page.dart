import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';
import 'package:mescla_invest/services/firestore_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirestoreService _firestore = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Perfil',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _firestore.getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? {};
          final nome = data['nome']?.toString() ?? '—';
          final email = data['email']?.toString() ??
              FirebaseAuth.instance.currentUser?.email ??
              '—';
          final telefone = data['telefone']?.toString() ?? 'Não informado';
          final mfaEnabled = data['mfaEnabled'] == true;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.accent,
                        child: Icon(Icons.person,
                            size: 48, color: AppColors.primary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        nome,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _InfoTile(
                  icon: Icons.email_outlined,
                  label: 'E-mail',
                  value: email,
                ),
                _InfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Telefone',
                  value: telefone,
                  onEdit: () => _editarTelefone(telefone),
                ),
                const SizedBox(height: 16),
                Card(
                  child: SwitchListTile(
                    secondary: const Icon(Icons.security_outlined,
                        color: AppColors.primary),
                    title: const Text('Autenticação em duas etapas (MFA)'),
                    subtitle: Text(
                        mfaEnabled ? 'Ativada' : 'Desativada'),
                    value: mfaEnabled,
                    onChanged: (valor) => _alternarMfa(valor),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text('Sair da conta',
                        style: TextStyle(color: Colors.redAccent)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _alternarMfa(bool ativar) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await _firestore.setMfaEnabled(ativar);
    if (!mounted) return;
    if (ativar) {
      navigator.pushNamed('/mfa');
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('MFA desativado.')),
      );
    }
  }

  Future<void> _editarTelefone(String atual) async {
    final controller = TextEditingController(
        text: atual == 'Não informado' ? '' : atual);
    final messenger = ScaffoldMessenger.of(context);
    final novoTelefone = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Editar telefone'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telefone',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (novoTelefone == null || novoTelefone.isEmpty) return;
    await _firestore.updateUserPhone(novoTelefone);
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Telefone atualizado.')),
    );
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    navigator.pushNamedAndRemoveUntil('/login', (route) => false);
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onEdit,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: const TextStyle(color: Color(0xFF64748B))),
        subtitle: Text(value,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        trailing: onEdit != null
            ? IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
              )
            : null,
      ),
    );
  }
}
