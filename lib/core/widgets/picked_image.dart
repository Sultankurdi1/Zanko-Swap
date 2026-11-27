import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

/// On the web image_picker returns a `blob:` URL instead of a file path.
ImageProvider pickedImageProvider(XFile file) =>
    kIsWeb ? NetworkImage(file.path) : FileImage(File(file.path));

class PickedImage extends StatelessWidget {
  const PickedImage(this.file, {super.key, this.width, this.height, this.fit});

  final XFile file;
  final double? width;
  final double? height;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) => Image(
    image: pickedImageProvider(file),
    width: width,
    height: height,
    fit: fit,
  );
}
