import 'package:flutter/material.dart';
import '../Constants/ColorPalatte.dart';

class DressIcons {
  // Map of dress types to their corresponding icons
  static const Map<String, IconData> _dressIconMap = {
    // Formal wear
    'blouse': Icons.woman,
    'blazer': Icons.business_center,
    'suit': Icons.business_center,
    'coat': Icons.outbond,
    'jacket': Icons.checkroom,
    
    // Traditional wear
    'kurta': Icons.self_improvement,
    'kurti': Icons.self_improvement,
    'saree': Icons.woman,
    'lehenga': Icons.celebration,
    'anarkali': Icons.celebration,
    'salwar': Icons.self_improvement,
    'churidar': Icons.self_improvement,
    'palazzo': Icons.self_improvement,
    
    // Casual wear
    'shirt': Icons.checkroom,
    'top': Icons.checkroom,
    't-shirt': Icons.checkroom,
    'tshirt': Icons.checkroom,
    'dress': Icons.woman,
    'gown': Icons.celebration,
    'maxi': Icons.woman,
    
    // Bottom wear
    'pant': Icons.straighten,
    'pants': Icons.straighten,
    'trouser': Icons.straighten,
    'trousers': Icons.straighten,
    'jeans': Icons.straighten,
    'skirt': Icons.woman,
    'shorts': Icons.straighten,
    'leggings': Icons.straighten,
    
    // Inner wear
    'bra': Icons.favorite_border,
    'petticoat': Icons.woman,
    'slip': Icons.woman,
    
    // Accessories
    'dupatta': Icons.waves,
    'scarf': Icons.waves,
    'stole': Icons.waves,
    'shawl': Icons.waves,
    
    // Kids wear
    'frock': Icons.child_care,
    'romper': Icons.child_care,
    'jumpsuit': Icons.child_care,
    
    // Men's wear
    'dhoti': Icons.man,
    'lungi': Icons.man,
    'veshti': Icons.man,
    
    // Special occasion
    'wedding': Icons.favorite,
    'party': Icons.celebration,
    'evening': Icons.nights_stay,
    
    // Work wear
    'uniform': Icons.work,
    'apron': Icons.kitchen,
    
    // Default fallback
    'default': Icons.checkroom,
  };

  // Get icon for a dress type
  static IconData getIconForDressType(String? dressType) {
    if (dressType == null || dressType.isEmpty) {
      return _dressIconMap['default']!;
    }
    
    // Convert to lowercase for case-insensitive matching
    String lowerDressType = dressType.toLowerCase().trim();
    
    // Direct match first
    if (_dressIconMap.containsKey(lowerDressType)) {
      return _dressIconMap[lowerDressType]!;
    }
    
    // Partial match - check if any key contains the dress type or vice versa
    for (String key in _dressIconMap.keys) {
      if (lowerDressType.contains(key) || key.contains(lowerDressType)) {
        return _dressIconMap[key]!;
      }
    }
    
    // Return default icon if no match found
    return _dressIconMap['default']!;
  }

  // Get color based on dress category
  static Color getColorForDressType(String? dressType) {
    if (dressType == null || dressType.isEmpty) {
      return ColorPalatte.primary;
    }
    
    String lowerDressType = dressType.toLowerCase().trim();
    
    // Traditional wear - Golden/Orange theme
    if (['kurta', 'kurti', 'saree', 'lehenga', 'anarkali', 'salwar', 'churidar', 'palazzo', 'dhoti', 'lungi', 'veshti'].any((item) => 
        lowerDressType.contains(item) || item.contains(lowerDressType))) {
      return Colors.orange.shade700;
    }
    
    // Formal wear - Blue theme
    if (['blazer', 'suit', 'coat', 'jacket', 'shirt', 'trouser', 'trousers', 'uniform'].any((item) => 
        lowerDressType.contains(item) || item.contains(lowerDressType))) {
      return Colors.blue.shade700;
    }
    
    // Party/Celebration wear - Purple theme
    if (['gown', 'dress', 'party', 'wedding', 'evening', 'celebration'].any((item) => 
        lowerDressType.contains(item) || item.contains(lowerDressType))) {
      return Colors.purple.shade700;
    }
    
    // Casual wear - Green theme
    if (['top', 't-shirt', 'tshirt', 'jeans', 'shorts', 'casual'].any((item) => 
        lowerDressType.contains(item) || item.contains(lowerDressType))) {
      return Colors.green.shade700;
    }
    
    // Kids wear - Pink theme
    if (['frock', 'romper', 'jumpsuit', 'child'].any((item) => 
        lowerDressType.contains(item) || item.contains(lowerDressType))) {
      return Colors.pink.shade700;
    }
    
    // Women's specific - Red theme
    if (['blouse', 'woman', 'lady', 'female'].any((item) => 
        lowerDressType.contains(item) || item.contains(lowerDressType))) {
      return Colors.red.shade700;
    }
    
    // Default color
    return ColorPalatte.primary;
  }
}

// Custom widget for dress icons
class DressIconWidget extends StatelessWidget {
  final String? dressType;
  final String? imageUrl; // URL for dress type image
  final double size;
  final bool showBackground;
  final Color? backgroundColor;
  final Color? iconColor;
  
  const DressIconWidget({
    Key? key,
    required this.dressType,
    this.imageUrl,
    this.size = 40.0,
    this.showBackground = true,
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final IconData icon = DressIcons.getIconForDressType(dressType);
    final Color bgColor = backgroundColor ?? DressIcons.getColorForDressType(dressType);
    final Color icColor = iconColor ?? Colors.white;
    
    // If imageUrl is provided, show image instead of icon
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Image.network(
            imageUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to icon if image fails to load
              return _buildIconWidget(icon, bgColor, icColor);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: SizedBox(
                  width: size * 0.5,
                  height: size * 0.5,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    
    // Show icon if no imageUrl
    return _buildIconWidget(icon, bgColor, icColor);
  }
  
  Widget _buildIconWidget(IconData icon, Color bgColor, Color icColor) {
    if (showBackground) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(size / 2),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: icColor,
          size: size * 0.6,
        ),
      );
    } else {
      return Icon(
        icon,
        color: bgColor,
        size: size,
      );
    }
  }
}