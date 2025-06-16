import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../../models/produto_preco_data.dart';
import 'dart:async';

class ProdutoLineChart extends StatefulWidget {
  final List<ProdutoPrecoPorData> precos;
  const ProdutoLineChart({super.key, required this.precos});

  @override
  State<ProdutoLineChart> createState() => _ProdutoLineChartState();
}

class _ProdutoLineChartState extends State<ProdutoLineChart> {
  int? _pontoSelecionado;
  double? _precoSelecionado;
  Offset? _posicaoLabel;
  Timer? _timerLabel;

  @override
  void dispose() {
    _timerLabel?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final precos = widget.precos;
    final pontos = <FlSpot>[];
    final labels = <int, String>{};
    double maiorPreco = 0.0;
    for (var i = 0; i < precos.length; i++) {
      final p = precos[i];
      try {
        final partes = p.data.split('-');
        if (partes.length == 3) {
          final dia = partes[2].padLeft(2, '0');
          final mes = partes[1].padLeft(2, '0');
          labels[i] = '$dia/$mes';
        } else {
          labels[i] = p.data;
        }
        pontos.add(FlSpot(i.toDouble(), p.preco ?? 0));
        var preco = p.preco ?? 0;
        maiorPreco = max(maiorPreco, (preco % 1 == 0.0) ? preco : preco.truncateToDouble());
      } catch (_) {}
    }
    if (pontos.isEmpty) {
      return const Center(child: Text('Sem dados para o gráfico.'));
    }
    final minY = 0.0;
    final maxY = maiorPreco + 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                backgroundColor: Colors.white,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        return Text(labels[idx] ?? '', style: const TextStyle(fontSize: 10));
                      },
                      interval: 1,
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 2,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[300],
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey[200],
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: pontos,
                    isCurved: true,
                    color: Colors.blue[800],
                    barWidth: 4,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue[100]!.withOpacity(0.3),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.blue[800]!,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    shadow: const Shadow(
                      color: Colors.blueAccent,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: false,
                  touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                    if (response == null || response.lineBarSpots == null || response.lineBarSpots!.isEmpty) return;
                    if (event is FlTapUpEvent) {
                      final spot = response.lineBarSpots!.first;
                      setState(() {
                        _pontoSelecionado = spot.x.toInt();
                        _precoSelecionado = spot.y;
                        final dx = spot.x / (pontos.length - 1) * constraints.maxWidth;
                        final dy = (1 - (spot.y - minY) / (maxY - minY)) * constraints.maxHeight;
                        _posicaoLabel = Offset(dx.isNaN?0:dx, dy.isNaN?0:dy);
                      });
                      _timerLabel?.cancel();
                      _timerLabel = Timer(const Duration(seconds: 1), () {
                        setState(() {
                          _pontoSelecionado = null;
                          _precoSelecionado = null;
                          _posicaoLabel = null;
                        });
                      });
                    }
                  },
                ),
              ),
            ),
            if (_pontoSelecionado != null && _precoSelecionado != null && _posicaoLabel != null)
              Positioned(
                left: (_posicaoLabel!.dx - 30).clamp(0.0, constraints.maxWidth - 80),
                top: (_posicaoLabel!.dy - 40).clamp(0.0, constraints.maxHeight - 32),
                child: Material(
                  color: Colors.transparent,
                  child: AnimatedOpacity(
                    opacity: 1,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '€ ${_precoSelecionado!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}