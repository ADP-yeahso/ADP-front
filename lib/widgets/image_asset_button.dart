import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 디자이너로부터 에셋을 받았을 때 `imagePath`만 입력하면 
/// 바로 이미지 버튼으로 교체되는 커스텀 버튼 위젯입니다.
class ImageAssetButton extends StatelessWidget {
  final String? imagePath; // 예: 'assets/images/btn_login.png' 또는 '.svg'
  final VoidCallback onPressed;
  
  // 에셋이 없을 때 임시로 보여줄 UI 속성들
  final String fallbackText;
  final Color fallbackColor;
  final bool isFilled; // 배경이 채워진 버튼인지 여부
  final double? width;
  final double height;
  final IconData? icon;

  const ImageAssetButton({
    super.key,
    this.imagePath,
    required this.onPressed,
    required this.fallbackText,
    required this.fallbackColor,
    this.isFilled = false,
    this.width,
    this.height = 56.0,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Widget? imageWidget;
    
    if (imagePath != null && imagePath!.isNotEmpty) {
      if (imagePath!.toLowerCase().endsWith('.svg')) {
        imageWidget = SvgPicture.asset(
          imagePath!,
          width: width,
          height: height,
          fit: BoxFit.contain,
        );
      } else {
        imageWidget = Image.asset(
          imagePath!,
          width: width,
          height: height,
          fit: BoxFit.contain,
        );
      }
    }

    return GestureDetector(
      onTap: onPressed,
      child: imageWidget ?? Container(
              width: width,
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isFilled ? fallbackColor : Colors.transparent,
                border: isFilled ? null : Border.all(color: fallbackColor, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: isFilled ? Colors.white : fallbackColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    fallbackText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isFilled ? Colors.white : fallbackColor,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
