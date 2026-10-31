import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 디자이너로부터 일러스트 에셋을 받았을 때 `imagePath`만 입력하면 
/// 바로 이미지로 교체되는 커스텀 위젯입니다.
class ImageAssetPlaceholder extends StatelessWidget {
  final String? imagePath; // 예: 'assets/images/illust_login.svg'
  
  // 에셋이 없을 때 임시로 보여줄 속성들
  final String fallbackText;
  final Color fallbackColor;
  final double? width;
  final double height;
  final bool isCircle;

  const ImageAssetPlaceholder({
    super.key,
    this.imagePath,
    required this.fallbackText,
    required this.fallbackColor,
    this.width,
    required this.height,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath != null && imagePath!.isNotEmpty) {
      if (imagePath!.toLowerCase().endsWith('.svg')) {
        return SvgPicture.asset(
          imagePath!,
          width: width,
          height: height,
          fit: BoxFit.contain,
        );
      } else {
        return Image.asset(
          imagePath!,
          width: width,
          height: height,
          fit: BoxFit.contain,
        );
      }
    }

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        border: Border.all(color: fallbackColor, width: 2),
        borderRadius: isCircle ? null : BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        fallbackText,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isCircle ? 14 : 32,
          fontWeight: FontWeight.bold,
          color: fallbackColor,
        ),
      ),
    );
  }
}
