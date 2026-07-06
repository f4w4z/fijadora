import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.rating,
    this.onChanged,
    this.size = 28,
    this.color = Colors.amber,
  });

  final double rating;
  final ValueChanged<double>? onChanged;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final val = index + 1;
        final star = Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            val <= rating ? CupertinoIcons.star_fill : CupertinoIcons.star,
            size: size,
            color: color,
          ),
        );
        if (onChanged == null) return star;
        return GestureDetector(
          onTap: () => onChanged!(val.toDouble()),
          child: star,
        );
      }),
    );
  }
}
