import 'package:flutter/material.dart';

/// Espacement vertical entre champs de saisie — à utiliser partout dans l’app.
abstract class FormSpacing {
  /// Hauteur entre deux champs (outlined + labels flottants) — lisible sur tous les écrans.
  static const double gap = 24;

  /// À placer entre chaque `TextField` / `TextFormField` consécutif.
  static const Widget betweenInputs = SizedBox(height: gap);
}
