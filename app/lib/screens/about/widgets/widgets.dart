part of 'about_actions_section.dart';
// ignore_for_file: unused_element, unused_element_parameter

class _ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? imageAsset;
  final String text;

  const _ActionButton({
    required this.onPressed,
    this.icon,
    this.imageAsset,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            if (imageAsset != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Image.asset(imageAsset!, width: 20, height: 20),
              )
            else if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(icon, size: 20),
              ),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ImportDialogResult {
  final String jsonText;
  final ImportMode importMode;

  const _ImportDialogResult({required this.jsonText, required this.importMode});
}

class _PathImportDialogResult {
  final String path;
  final ImportMode importMode;

  const _PathImportDialogResult({required this.path, required this.importMode});
}
