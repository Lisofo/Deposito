import 'package:flutter/material.dart';

class CORSImageWidget extends StatefulWidget {
  final String imageUrl;
  final double height;
  final double width;

  const CORSImageWidget({
    required this.imageUrl, 
    this.height = 100, 
    this.width = 100, 
    super.key
  });

  @override
  State<CORSImageWidget> createState() => _CORSImageWidgetState();
}

class _CORSImageWidgetState extends State<CORSImageWidget> {
  bool hasError = false;

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: const Center(
          child: Icon(Icons.image_not_supported),
        ),
      );
    }

    return Image.network(
      widget.imageUrl,
      height: widget.height,
      width: widget.width,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          height: widget.height,
          width: widget.width,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        setState(() {
          hasError = true;
        });
        return SizedBox(
          height: widget.height,
          width: widget.width,
          child: const Center(
            child: Icon(Icons.image_not_supported),
          ),
        );
      },
    );
  }
}