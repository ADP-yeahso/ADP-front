import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../data/app_data.dart';
import '../profile/patient_info_screen.dart';

const careBackground = Color(0xFFFFFBEF);
const careGreen = Color(0xFF547B35);
Widget careAsset(String name, {double? width, double? height}) =>
    SvgPicture.asset(
      'assets/images/care_note/$name.svg',
      width: width,
      height: height,
    );
PreferredSizeWidget careAppBar() => AppBar(
  backgroundColor: careBackground,
  surfaceTintColor: Colors.transparent,
  centerTitle: true,
  toolbarHeight: 52,
  leading: Builder(
    builder: (context) => IconButton(
      tooltip: '뒤로 가기',
      onPressed: () => Navigator.of(context).maybePop(),
      icon: careAsset('back_icon', width: 12, height: 22),
    ),
  ),
  title: careAsset('title', width: 80, height: 28),
  bottom: const PreferredSize(
    preferredSize: Size.fromHeight(1),
    child: Divider(height: 1, color: Color(0xFFE9E5D9)),
  ),
);

class CarePatientCard extends StatelessWidget {
  const CarePatientCard({super.key});
  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final birth = data.patient.patientBirthDate.toString().padLeft(8, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFE6E2D7)),
      ),
      child: Row(
        children: [
          careAsset('patient_avatar_default', width: 58, height: 58),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.patientRelationLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF243B17),
                  ),
                ),
                Text(
                  '${data.patient.patientName} · ${birth.substring(0, 4)}.${birth.substring(4, 6)}.${birth.substring(6)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF607251),
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: '환자 정보 수정',
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PatientInfoScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: careAsset('edit_info_button', width: 38, height: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Uses the original asset keys for styling while rendering text at device resolution.
/// PNGs contain 1x text and SVG filters apply to both text and backgrounds.
class CareAssetButton extends StatelessWidget {
  final String asset;
  final String label;
  final String? text;
  final VoidCallback onTap;
  final bool selected;
  final double height;
  const CareAssetButton({
    super.key,
    required this.asset,
    required this.label,
    required this.onTap,
    this.text,
    this.selected = false,
    this.height = 32,
  });

  @override
  Widget build(BuildContext context) {
    final option = asset.startsWith('option_');
    final write = asset == 'write_note_button';
    final greenAction = write || asset == 'save_green_button';
    final background = option
        ? (selected ? const Color(0xFFA2D87C) : const Color(0xFFFFFDF6))
        : (greenAction ? const Color(0xFFA2D97C) : const Color(0xFFFFEFB5));
    final radius = BorderRadius.circular(option ? 5 : 28);
    final border = option
        ? (selected ? const Color(0xFF91BE70) : const Color(0xFFE5E2DA))
        : (greenAction ? const Color(0xFF8BB96B) : const Color(0xFFDDCEA0));
    return Semantics(
      label: label,
      button: true,
      selected: option ? selected : null,
      child: Tooltip(
        message: label,
        child: Align(
          alignment: Alignment.center,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: option ? double.infinity : 290,
            ),
            child: Material(
              color: background,
              elevation: option ? 0.5 : 1,
              shadowColor: const Color(0x26000000),
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: BorderSide(color: border),
              ),
              child: InkWell(
                onTap: onTap,
                borderRadius: radius,
                child: Container(
                  constraints: BoxConstraints(minHeight: height),
                  padding: EdgeInsets.symmetric(
                    horizontal: option ? 4 : 20,
                    vertical: option ? 5 : 10,
                  ),
                  child: ExcludeSemantics(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        if (write) ...[
                          const Icon(
                            Icons.edit_square,
                            size: 20,
                            color: Color(0xFF16260E),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Flexible(
                          child: Text(
                            text ?? label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: option
                                  ? (asset.startsWith('option_unusual_') &&
                                            text == null
                                        ? 10
                                        : 12)
                                  : 18,
                              height: 1.2,
                              fontWeight: option
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: option && !selected
                                  ? const Color(0xFF645555)
                                  : const Color(0xFF16260E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
