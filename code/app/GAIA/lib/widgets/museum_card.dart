import 'package:flutter/material.dart';
import 'package:gaia/model/museum.dart';

class MuseumCard extends StatelessWidget {
  final Museum museum;
  final double? distance;
  final VoidCallback? onTap;

  const MuseumCard({
    super.key,
    required this.museum,
    this.distance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final km = distance != null ? (distance! / 1000).toStringAsFixed(2) : null;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: museum.toImage(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    museum.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18),
                      const SizedBox(width: 4),
                      Text('${museum.city} (${museum.departement})'),
                      const Spacer(),
                      if (km != null)
                        Row(
                          children: [
                            const Icon(Icons.directions_walk,
                                size: 18, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('$km km',
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (museum.telephone.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 18),
                        const SizedBox(width: 4),
                        Text(museum.telephone),
                      ],
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
