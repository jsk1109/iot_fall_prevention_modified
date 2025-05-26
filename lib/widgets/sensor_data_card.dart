import 'package:flutter/material.dart';

class SensorDataCard extends StatelessWidget {
  final double temperature;
  final double humidity;
  final double pressure;
  final DateTime timestamp;

  const SensorDataCard({
    super.key,
    required this.temperature,
    required this.humidity,
    required this.pressure,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '측정 시간: ${timestamp.toString().substring(0, 19)}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSensorData(
                  icon: Icons.thermostat,
                  label: '온도',
                  value: '$temperature°C',
                  color: Colors.red,
                ),
                _buildSensorData(
                  icon: Icons.water_drop,
                  label: '습도',
                  value: '$humidity%',
                  color: Colors.blue,
                ),
                _buildSensorData(
                  icon: Icons.speed,
                  label: '기압',
                  value: '$pressure hPa',
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorData({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
