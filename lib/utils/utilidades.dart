import 'package:material_symbols_icons/get.dart';
import 'package:flutter/material.dart';

// Função para obter o ícone Material a partir do nome
IconData getMaterialSymbol(String iconName) {
  return SymbolsGet.get(iconName,SymbolStyle.outlined);
}

String formatarQuantidade(double quantidade) {
  if (quantidade % 1.0 == 0.0) {
    return quantidade.toStringAsFixed(0);
  }
  return quantidade.toStringAsFixed(2);
}