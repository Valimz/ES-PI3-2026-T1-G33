// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

import 'package:flutter/material.dart';

class SucessoEnvioDialog extends StatelessWidget{
    const SucessoEnvioDialog({super.key});

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Column(
                children: [
                    Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 60,
                    ),
                    SizedBox(height: 16),
                    Text(
                        'E-mail Enviado!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                ],
            ),
            content: const Text(
                'Enviamos as intruções para recuperação de senha. Verifique sua caixa de entrada e lixo eletrônico.',
                textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
                TextButton(
                    onPressed: () {
                        Navigator.of(context).pop();
                    },
                    child: const Text(
                        'OK, ENTENDI',
                        style: TextStyle(fontWeight: FontWeight.bold),
                    ))
            ],
        );
    }
}