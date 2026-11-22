import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

/// Image provider for a picked photo that works on phones and on the web.
///
/// On the web there is no file system: image_picker gives a `blob:` URL as
/// the path, which a network image can show.
ImageProvider pickedImageProvider(XFile file) =>
    kIsWeb ? NetworkImage(file.path) : FileImage(File(file.path));

/// Preview widget for a picked photo (phones and web).
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
