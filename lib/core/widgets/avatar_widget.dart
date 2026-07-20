import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool isFile;

  const AvatarWidget({super.key, this.imageUrl, required this.name, this.size = 40, this.isFile = false});

  @override
  Widget build(BuildContext context) {
    if (isFile && imageUrl != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: kIsWeb ? NetworkImage(imageUrl!) : FileImage(File(imageUrl!)) as ImageProvider,
      );
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        imageBuilder: (_, imageProvider) => CircleAvatar(radius: size / 2, backgroundImage: imageProvider),
        placeholder: (_, __) => CircleAvatar(radius: size / 2, child: Text(name[0].toUpperCase())),
        errorWidget: (_, __, ___) => CircleAvatar(radius: size / 2, child: Text(name[0].toUpperCase())),
      );
    }
    return CircleAvatar(radius: size / 2, child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'));
  }
}
